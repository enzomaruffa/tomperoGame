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
    
    // MARK: - Coordinator
    weak var coordinator: MainCoordinator?
    
    // MARK: - Game Variables
    var hosting = false
    
    var player: String = "God" //MCManager.shared.selfName
    var rule: GameRule?
    var orders: [Order] = []
    var tables: [PlayerTable] {
        rule!.playerTables[player]!
    }
    var playerOrder: [String] {
        rule!.playerOrder
    }
    var players: [String] {
        let players = rule!.playerOrder
        return players.filter({ $0 != player })
    }
    var playerColor: String {
        let colors = ["Blue", "Purple", "Green", "Orange"]
        print(playerOrder)
        print(playerOrder.firstIndex(of: player)!)
        return colors[playerOrder.firstIndex(of: player)!]
    }
    var colors: [String] {
        var colors = ["Blue", "Purple", "Green", "Orange"]
        colors.remove(at: playerOrder.firstIndex(of: player)!)
        return colors
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
    var orderGenerationCounter = 800
    var orderCount = 0
    let maxOrders = 3
    var firstOrder = false
    
    var matchStatistics: MatchStatistics?
    
    var matchTimer = Float(180)
    var timerStarted = false
    var timerUpdateCounter = 0
    
    var totalPoints = 0
    
    var endTimerPlayed = false
    var timesUpPlayed = false
    
    // MARK: - Animation Variables
    var stationsAnimationsRunning = false
    
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
        
        if hosting {
            matchStatistics = MatchStatistics(ruleUsed: rule!)
            EventLogger.shared.logMatchStart(withPlayerCount: playerOrder.filter({ $0 != "__empty__"}).count, andDifficulty: rule!.difficulty)
        }
        
        setupOrderListNode()
        setupStations()
        setupShelves()
        setupPiping()
        setupHUD()
        setupBackground()
        
        SFXPlayer.shared.roundStarted.play()
        
        // Debugging attempts
//        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
//            self.orderListNode.jump()
//            self.orderListNode.close()
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
//            self.orderListNode.jump()
//            self.orderListNode.open()
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
//            self.orderListNode.open()
//            self.orderListNode.jump()
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 13) {
//            self.orderListNode.close()
//            self.orderListNode.jump()
//        }
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
        
        print("Creating \(String(describing: teleportAnimationNode)) with textures \(String(describing: teleportAnimationFrames))")
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
            let pipeNode = self.childNode(withName: "pipe" + (index+1).description) as! SKSpriteNode
            pipeNode.zPosition = 2
            pipeNode.name = "pipe" + (index+1).description
//            if playerOrder[index+1] != "__empty__" {
                pipeNode.texture = SKTexture(imageNamed: "Pipe" + color)
                stations.append(PipeNode(node: pipeNode))
//            } else {
//                pipeNode.texture = SKTexture(imageNamed: "PipeClosed" + color)
//            }
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
        let order = rule?.generateOrder()
        orderCount += 1
        order!.number = orderCount
        orders.append(order!)
        
        updateOrderUI(orders)
        
        matchStatistics?.totalGeneratedOrders += 1
    }
    
    fileprivate func updateOrders() {
        for (index, order) in orders.enumerated() {
            order.timeLeft -= 1/60
            
            if hosting {
                if order.timeLeft <= 0.0 {
                    orders.remove(at: index)
                    GameConnectionManager.shared.sendEveryone(orderList: orders)
                    updateOrderUI(orders)
                }
            }
        }
        orderListNode.update()
        
        if hosting {
            orderGenerationCounter += 2
            
            if (orderGenerationCounter >= 1000 && orders.count < maxOrders) || (timerStarted && orders.isEmpty) {
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
    
    func endMatch() {
        self.isPaused = true
        GameConnectionManager.shared.sendEveryone(statistics: matchStatistics!)
        
        if hosting {
            EventLogger.shared.logMatchEnd(withPlayerCount: playerOrder.filter({ $0 != "__empty__"}).count, andDifficulty: rule!.difficulty)
        }
        
        coordinator?.statistics(statistics: matchStatistics!)
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
        
        guard let targetOrder = orders.filter({ $0.isEquivalent(to: plate) }).first else {
            print("Couldn't find any order")
            let notification = OrderDeliveryNotification(playerName: player, success: false, coinsAdded: 0)
            GameConnectionManager.shared.sendEveryone(deliveryNotification: notification)
            
            updateOrderUI(orders)
            return false
        }
        
        let difficultyBonus = [GameDifficulty.easy: 1, .medium: 2, .hard: 3]
        let totalScore = targetOrder.score * difficultyBonus[rule!.difficulty]!
        
        print("Total score: \(totalScore)")
        
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
        print("[GameScene] Received plate with ingredients \(plate.ingredients.map({ type(of: $0) }))")
        
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
        self.addChild(node)
    }
    
    func receiveIngredient(ingredient: Ingredient) {
        print("[GameScene] Received ingredient with prefix \(ingredient.texturePrefix) and state as \(ingredient.currentState)")
        
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
        self.addChild(node)
    }
    
    func receiveOrders(orders: [Order]) {
        print("[GameScene] Received new orderList")
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
        print("[GameScene] Received new notification")
        
        if notification.success {
            print("[GameScene] Notification was a success! Yay!")
            
            print("[GameScene] Notification points are \(notification.coinsAdded)")
            
            matchStatistics?.totalDeliveredOrders += 1
            matchStatistics?.totalPoints += notification.coinsAdded
            totalPoints += notification.coinsAdded
            
            print("[GameScene] Total points now are \(totalPoints)")
            
            SFXPlayer.shared.cashRegister.play()
            updateCoinsUI()
        }
    }
    
    func receiveStatistics(statistics: MatchStatistics) {
        self.isPaused = true
        stations.forEach({ $0.stopAnimation() })
        DispatchQueue.main.async {
            self.coordinator?.statistics(statistics: statistics)
        }
    }
    
}
