//
//  GameScene.swift
//  Tompero
//
//  Created by Vinícius Binder on 22/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import SpriteKit
import GameplayKit

// swiftlint:disable force_cast
class GameScene: SKScene {
    
    // MARK: - Host callbacks
    /// Fired when a successful match ends with final statistics; SwiftUI
    /// host pushes the statistics screen. Replaces direct coordinator access.
    var onMatchEnd: ((MatchStatistics) -> Void)?
    /// Fired on a match-aborting error (peer dropped with no recovery). The
    /// SwiftUI host pops to root.
    var onMatchError: (() -> Void)?

    // MARK: - Game Variables
    var hosting = false
    weak var controller: UIViewController?
    
    var player: String = LANConnectionManager.shared.selfName
    var rule: GameRule?
    var orders: [Order] = []
    var tables: [PlayerTable] {
        rule?.playerTables[player] ?? []
    }
    var playerOrder: [String] {
        rule?.playerOrder ?? []
    }
    var players: [String] {
        playerOrder.filter { $0 != player }
    }
    private static let playerColorPalette = ["Blue", "Purple", "Green", "Orange"]
    var playerColor: String {
        guard let index = playerOrder.firstIndex(of: player) else { return GameScene.playerColorPalette[0] }
        return GameScene.playerColorPalette[index]
    }
    var colors: [String] {
        var palette = GameScene.playerColorPalette
        if let index = playerOrder.firstIndex(of: player) {
            palette.remove(at: index)
        }
        return palette
    }
    
    var stations: [StationNode] = []
    var shelves: [StationNode] {
        stations.filter({ $0.stationType == .shelf })
    }
    var pipes: [StationNode] {
        stations.filter({ $0.stationType == .pipe })
    }
    var hatch: StationNode {
        stations.filter({ $0.stationType == .hatch }).first!
    }
    
    var firstEmptyShelf: StationNode? {
        shelves.filter({ $0.isEmpty }).first
    }
    
    var orderListNode: OrderListNode!
    var orderGenerationCounter = 3 * 60
    let timeBetweenOrders = 10 * 60
    var orderCount = 0
    let maxOrders = 3
    var firstOrder = false
    
    var matchStatistics: MatchStatistics?
    
    var matchTimer: Float = 180
    var timerStarted = false
    var timerUpdateCounter = 0
    
    var totalPoints = 0
    
    var endTimerPlayed = false
    var timesUpPlayed = false
    
    // MARK: - Animation Variables
    var stationsAnimationsRunning = false

    // Disconnect-recovery overlay
    fileprivate var reconnectingOverlay: SKNode?
    fileprivate var reconnectTimeoutTimer: Timer?
    
    // Teleport variables
    private var teleportAnimationNode: SKSpriteNode!
    private var teleportAnimationFrames: [SKTexture]!
    private let teleportDuration = 1
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        
        // Scale view size to device
        let desiredWidth = CGFloat(2436)
        let desiredHeight = CGFloat(1154)
        
        var currentViewSize = self.viewSizeInLocalCoordinates()
        
        let requiredScale = max(desiredWidth / currentViewSize.width, desiredHeight / currentViewSize.height)
        
        let cameraNode = SKCameraNode()
        self.camera = cameraNode
        self.scene?.addChild(cameraNode)
        
        self.camera?.setScale(requiredScale)
        
        currentViewSize = self.viewSizeInLocalCoordinates(ignoreCameraScale: false)
        let offset = (desiredHeight - currentViewSize.height) / 2
        cameraNode.position = CGPoint(x: 0, y: -offset)
        
        // Adds itself as a GameConnection observer
        GameConnectionManager.shared.subscribe(observer: self)
        LANConnectionManager.shared.subscribeMatchmakingObserver(observer: self)

        if hosting, let rule {
            matchStatistics = MatchStatistics(ruleUsed: rule)
            EventLogger.shared.logMatchStart(withPlayerCount: playerOrder.filter({ $0 != "__empty__"}).count, andDifficulty: rule.difficulty)
        }
        
        setupOrderListNode()
        setupStations()
        setupShelves()
        setupPiping()
        setupHUD()
        setupBackground()
        
        SFXPlayer.shared.roundStarted.play()
    }
    
    func setupOrderListNode() {
        orderListNode = (childNode(withName: "orders") as! OrderListNode)
        orderListNode.texture = SKTexture(imageNamed: "OrderList" + playerColor)
    }
    
    func setupStations() {
        func convertTableToStation(type: PlayerTableType) -> StationType {
            switch type {
            case .chopping: return .board
            case .cooking: return .stove
            case .frying: return .fryer
            case .plate: return .plateBox
            case .ingredient: return .ingredientBox
            case .empty: return .empty
            }
        }
        
        var nodes: [StationNode] = []
        for table in tables {
            if table.type == .chopping {
                nodes.append(BoardNode())
            } else if table.type == .cooking {
                nodes.append(StoveNode())
            } else if table.type == .frying {
                nodes.append(FryerNode())
            } else if table.type == .plate {
                nodes.append(PlateBoxNode())
            } else if table.type == .ingredient {
                nodes.append(IngredientBoxNode(ingredient: table.ingredient!))
            } else if table.type == .empty {
                nodes.append(StationNode(stationType: .empty))
            }
        }
        stations = nodes
        
        for (index, station) in stations.enumerated() {
            let node = station.spriteNode
            let pos = scene!.size.width/2-node.size.width/2
            let xPos = [-pos, 0.0, pos]
            node.position = CGPoint(x: xPos[index], y: CGFloat(station.spriteYPos))
            self.addChild(node)
        }
    }
    
    func createTeleporterAnimation(_ teleporterNode: (SKSpriteNode)) {
        
        let teleportAtlas = SKTextureAtlas(named: "Teleport" + playerColor)
        teleportAnimationFrames = []
        for currentAnimation in 0..<teleportAtlas.textureNames.count {
            let teleportFrameName = "teleport\(currentAnimation > 9 ? currentAnimation.description : "0" + currentAnimation.description)"
            teleportAnimationFrames.append(teleportAtlas.textureNamed(teleportFrameName))
        }
        
        teleportAnimationNode = SKSpriteNode(texture: teleportAnimationFrames[0])
        self.addChild(teleportAnimationNode)
        
        teleportAnimationNode.position = teleporterNode.position + CGPoint(x: -8, y: -(teleporterNode.size.height + 8))
        teleportAnimationNode.zPosition = 60
        
    }
    
    func setupShelves() {
        stations.append(ShelfNode(node: self.childNode(withName: "shelf1") as! SKSpriteNode))
        stations.append(ShelfNode(node: self.childNode(withName: "shelf2") as! SKSpriteNode))
        stations.append(ShelfNode(node: self.childNode(withName: "shelf3") as! SKSpriteNode))
        
        stations.append(DeliveryNode(node: self.childNode(withName: "delivery") as! SKSpriteNode))
        
        (self.childNode(withName: "target") as! SKSpriteNode).texture = SKTexture(imageNamed: "Target" + playerColor)
        
        let teleporterNode = (self.childNode(withName: "teleporter") as! SKSpriteNode)
        teleporterNode.texture = SKTexture(imageNamed: "Teleporter" + playerColor)
        
        createTeleporterAnimation(teleporterNode)
    }
    
    func setupPiping() {
        for (index, color) in colors.enumerated() {
            let pipeNode = self.childNode(withName: "pipeArea" + (index+1).description) as! SKSpriteNode
            let pipeImage = self.childNode(withName: "pipe" + (index+1).description) as! SKSpriteNode
            pipeNode.name = "pipe" + (index+1).description
            if playerOrder[index+1] != "__empty__" {
                pipeImage.texture = SKTexture(imageNamed: "Pipe" + color)
                stations.append(PipeNode(node: pipeNode))
            } else {
                pipeImage.texture = SKTexture(imageNamed: "PipeClosed" + color)
            }
        }
        
        stations.append(HatchNode(node: self.childNode(withName: "hatch") as! SKSpriteNode))
    }
    
    func setupBackground() {
        let background = self.childNode(withName: "background") as! SKSpriteNode
        background.texture = SKTexture(imageNamed: "BackgroundXL" + playerColor)
    }
    
    func setupHUD() {
        let timerContainer = self.childNode(withName: "timerContainer") as! SKSpriteNode
        timerContainer.texture = SKTexture(imageNamed: "Timer" + playerColor)
        
        updateTimerUI()
        updateCoinsUI()
    }
    
    // MARK: - Game Logic
    
    func generateRandomOrder() {
        guard let order = rule?.generateOrder() else { return }
        orderCount += 1
        order.number = orderCount
        orders.append(order)

        updateOrderUI(orders)

        matchStatistics?.totalGeneratedOrders += 1
    }
    
    fileprivate func updateOrders() {
        for (index, order) in orders.enumerated() {
            order.timeLeft -= 1/60
            
            if hosting {
                if order.timeLeft <= 0.0 {

                    let totalActions = order.ingredients.map({ $0.numberOfActionsTilReady }).reduce(0, +)
                    EventLogger.shared.logOrderResult(success: false, actionCount: totalActions, ingredientCount: order.ingredients.count, difficulty: rule?.difficulty ?? .easy)
                    
                    orders.remove(at: index)
                    GameConnectionManager.shared.sendEveryone(orderList: orders)
                    updateOrderUI(orders)
                }
            }
        }
        orderListNode.update()
        
        if hosting {
            orderGenerationCounter += 1
            
            if (orderGenerationCounter >= timeBetweenOrders && orders.count < maxOrders) || (timerStarted && orders.isEmpty) {
                generateRandomOrder()
                if firstOrder {
                    SFXPlayer.shared.orderUp.play()
                    orderListNode.jump()
                } else {
                    orderListNode.open()
                }
                GameConnectionManager.shared.sendEveryone(orderList: orders)
                orderGenerationCounter = 0
                
                // timer only starts when the first order is generated
                if !timerStarted {
                    timerStarted = true   
                }
            }
            
            if self.orders.count == 1 && !firstOrder {
                firstOrder = true
                MusicPlayer.shared.play(.game)
            }
            
        }
    }
    
    fileprivate func checkAnimations() {
        let isMoving = !stations.filter({ ($0.ingredientNode?.moving ?? false || $0.plateNode?.moving ?? false) }).isEmpty
        
        if isMoving && !stationsAnimationsRunning {
            pipes.forEach({ $0.playAnimation() })
            hatch.playAnimation()
            stationsAnimationsRunning = true
        } else if !isMoving && stationsAnimationsRunning {
            pipes.forEach({ $0.stopAnimation() })
            hatch.stopAnimation()
            stationsAnimationsRunning = false
        }
    }
    
    func endMatch(error: Bool = false) {
        self.isPaused = true
        stations.forEach({ $0.stopAnimation() })
        
        if hosting && !error, let matchStatistics {
            EventLogger.shared.logMatchEnd(withPlayerCount: playerOrder.filter({ $0 != "__empty__"}).count, andDifficulty: rule?.difficulty ?? .easy)

            GameConnectionManager.shared.sendEveryone(statistics: matchStatistics)
            onMatchEnd?(matchStatistics)
        }

        if error {
            MusicPlayer.shared.stop(.game)
            onMatchError?()
        }
    }
    
    fileprivate func updateTimer() {
        timerUpdateCounter += 1
        if timerStarted && timerUpdateCounter >= 60 {
            matchTimer -= 1
            updateTimerUI()
            timerUpdateCounter = 0
        }
        
        if matchTimer < 0 {
            if !timesUpPlayed {
                timesUpPlayed = true
                SFXPlayer.shared.timesUp.play()
                MusicPlayer.shared.stop(.game)
            }
            
            if hosting {
                stations.forEach({ $0.stopAnimation() })
                endMatch()
            }
        }
        
        if matchTimer < 15 && !endTimerPlayed {
            endTimerPlayed = true
            SFXPlayer.shared.endTimer.play()
        }
    }
    
    func makeDelivery(plate: Plate) -> Bool {
        
        let timePerFrame = TimeInterval(teleportDuration) / TimeInterval(teleportAnimationFrames.count)
        SFXPlayer.shared.teleporter.play()
        teleportAnimationNode.run(SKAction.animate(
            with: teleportAnimationFrames,
            timePerFrame: timePerFrame,
            resize: false,
            restore: true)
        )
        
        let totalActions = plate.ingredients.map({ $0.numberOfActionsTilReady }).reduce(0, +)
        
        guard let targetOrder = orders.filter({ $0.isEquivalent(to: plate) }).first else {
            let notification = OrderDeliveryNotification(playerName: player, success: false, coinsAdded: 0)
            GameConnectionManager.shared.sendEveryone(deliveryNotification: notification)
            
            EventLogger.shared.logPlateDeliver(success: false, actionCount: totalActions, ingredientCount: plate.ingredients.count)
            
            updateOrderUI(orders)
            return false
        }
        
        EventLogger.shared.logPlateDeliver(success: true, actionCount: totalActions, ingredientCount: plate.ingredients.count)
        EventLogger.shared.logOrderResult(success: true, actionCount: totalActions, ingredientCount: plate.ingredients.count, difficulty: rule?.difficulty ?? .easy)
        
        let difficultyBonus: [GameDifficulty: Int] = [.easy: 1, .medium: 2, .hard: 3]
        let bonus = difficultyBonus[rule?.difficulty ?? .easy] ?? 1
        let totalScore = targetOrder.score * bonus
        
        
        let notification = OrderDeliveryNotification(playerName: player, success: true, coinsAdded: totalScore)
        GameConnectionManager.shared.sendEveryone(deliveryNotification: notification)

        orders.remove(at: orders.firstIndex { $0.isEquivalent(to: targetOrder) }!)
        
        GameConnectionManager.shared.sendEveryone(orderList: orders)
        
        orderGenerationCounter = 0
        updateOrderUI(orders)
        
        matchStatistics?.totalDeliveredOrders += 1
        matchStatistics?.totalPoints += notification.coinsAdded
        totalPoints += notification.coinsAdded
        
        updateCoinsUI()
        
        return true
    }
    
    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        stations.forEach({ $0.update() })
        
        checkAnimations()
        updateOrders()
        updateTimer()
    }
    
    // MARK: - UI Updates
    func updateOrderUI(_ orders: [Order]) {
        orderListNode.updateList(orders)
    }
    
    func updateTimerUI() {
        let timerLabel = self.childNode(withName: "timerLabel") as! SKLabelNode
        
        var currentSeconds = max(Int(ceil(matchTimer)), 0)
        
        let currentMinutes = currentSeconds / 60
        currentSeconds -= (currentMinutes * 60)
        
        timerLabel.text = "\(currentMinutes):\(currentSeconds > 9 ? currentSeconds.description : "0" + currentSeconds.description)"
    }
    
    func updateCoinsUI() {
        let coinsLabel = self.childNode(withName: "coinsLabel") as! SKLabelNode
        coinsLabel.text = "\(totalPoints)"
    }
}

// MARK: - GameConnectionManagerObserver Methods
extension GameScene: GameConnectionManagerObserver {
    
    func receivePlate(plate: Plate) {
        Log.game.debug("Received plate with ingredients \(plate.ingredients.map({ type(of: $0) }))")
        
        guard let shelf = firstEmptyShelf else {
            return
        }
        
        let node = MovableSpriteNode(imageNamed: "Plate")
        shelf.plateNode = PlateNode(
            plate: plate,
            movableNode: node,
            currentLocation: shelf
        )
        shelf.plateNode?.updateTexture()
        node.zPosition = 2
        node.setScale(0)
        self.addChild(node)
        node.run(.scale(to: shelf.plateNodeScale, duration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.1))
    }
    
    func receiveIngredient(ingredient: Ingredient) {
        Log.game.debug("Received ingredient with prefix \(ingredient.texturePrefix) and state \(ingredient.currentState.rawValue)")
        
        guard let shelf = firstEmptyShelf else {
            return
        }
        
        let node = MovableSpriteNode(imageNamed: ingredient.textureName)
        shelf.ingredientNode = IngredientNode(
            ingredient: ingredient,
            movableNode: node,
            currentLocation: shelf
        )
        shelf.ingredientNode?.checkTextureChange()
        node.zPosition = 2
        node.setScale(0)
        self.addChild(node)
        node.run(.scale(to: shelf.plateNodeScale, duration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.1))
    }
    
    func receiveOrders(orders: [Order]) {
        Log.game.debug("Received new orderList")
        self.orders = orders
        
        if firstOrder {
            SFXPlayer.shared.orderUp.play()
            orderListNode.jump()
        } else {
            orderListNode.open()
        }
        
        if self.orders.count == 1 && !firstOrder {
            firstOrder = true
            MusicPlayer.shared.play(.game)
        }
        
        if !timerStarted && !orders.isEmpty {
            timerStarted = true
        }
        
        updateOrderUI(orders)
    }
    
    func receiveDeliveryNotification(notification: OrderDeliveryNotification) {
        Log.game.debug("Received new notification")
        
        if notification.success {
            Log.game.debug("Notification was a success! Yay!")
            
            Log.game.debug("Notification points are \(notification.coinsAdded)")
            
            matchStatistics?.totalDeliveredOrders += 1
            matchStatistics?.totalPoints += notification.coinsAdded
            totalPoints += notification.coinsAdded
            
            Log.game.debug("Total points now are \(self.totalPoints)")
            
            SFXPlayer.shared.cashRegister.play()
            updateCoinsUI()
        }
    }
    
    func receiveStatistics(statistics: MatchStatistics) {
        endMatch()
        DispatchQueue.main.async {
            self.onMatchEnd?(statistics)
        }
    }
    
}

extension GameScene: LANMatchmakingObserver {
    func playerUpdate(player: String, state: PeerConnectionState) {
        // A bare .notConnected used to end the match instantly. With the
        // reconnect work in PR #6 a drop is often transient (background, brief
        // Wi-Fi loss), so we now hold the match paused for a 30s grace window
        // and only declare it over if the peer doesn't come back.
        guard view != nil else { return }

        switch state {
        case .notConnected:
            beginReconnectingOverlay(for: player)
        case .connecting:
            beginReconnectingOverlay(for: player)
        case .connected:
            endReconnectingOverlay(for: player)
        }
    }

    fileprivate func beginReconnectingOverlay(for player: String) {
        let overlay = reconnectingOverlay ?? makeReconnectingOverlay()
        (overlay.children.compactMap { $0 as? SKLabelNode }).forEach {
            $0.text = "\(player) reconnecting…"
        }
        if overlay.parent == nil, let camera {
            camera.addChild(overlay)
        }
        isPaused = true
        reconnectingOverlay = overlay
        cancelReconnectTimeout()
        scheduleReconnectTimeout()
    }

    fileprivate func endReconnectingOverlay(for player: String) {
        guard reconnectingOverlay != nil else { return }
        reconnectingOverlay?.removeFromParent()
        reconnectingOverlay = nil
        cancelReconnectTimeout()
        isPaused = false
    }

    fileprivate func makeReconnectingOverlay() -> SKNode {
        let overlay = SKNode()
        overlay.zPosition = 1000
        overlay.name = "reconnectingOverlay"

        let dim = SKShapeNode(rectOf: CGSize(width: 4000, height: 4000))
        dim.fillColor = UIColor.black.withAlphaComponent(0.65)
        dim.strokeColor = .clear
        overlay.addChild(dim)

        let label = SKLabelNode(fontNamed: "TitilliumWeb-Bold")
        label.fontSize = 80
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        overlay.addChild(label)
        return overlay
    }

    fileprivate func scheduleReconnectTimeout() {
        let timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.endMatch(error: true)
            }
        }
        reconnectTimeoutTimer = timer
    }

    fileprivate func cancelReconnectTimeout() {
        reconnectTimeoutTimer?.invalidate()
        reconnectTimeoutTimer = nil
    }
}
