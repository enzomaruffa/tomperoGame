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
    
    // MARK: - Variables
    var hosting = false
    
    var player: String = "God"//MCManager.shared.selfName
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
    var orderGenerationCounter = 900
    var orderCount = 0
    let maxOrders = 3
    
    var matchStatistics: MatchStatistics?
    
    var matchTimer = 180.0
    var timerStarted = false
    var timerUpdateCounter = 0
    
    var totalPoints = 0
    
    var stationsAnimationsRunning = false
    
    // Teleport variables
    private var teleportAnimationNode: SKSpriteNode!
    private var teleportAnimationFrames: [SKTexture]!
    private let teleportDuration = 1
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        // Adds itself as a GameConnection observer
        GameConnectionManager.shared.subscribe(observer: self)
        
        if hosting {
            matchStatistics = MatchStatistics(ruleUsed: rule!)
        }
        
        setupOrderListNode()
        setupStations()
        setupShelves()
        setupPiping()
        setupHUD()
        setupBackground()
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
        
        stations = tables.map({ StationNode(stationType: convertTableToStation(type: $0.type), ingredient: $0.ingredient) })
        
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
        stations.append(StationNode(stationType: .shelf, spriteNode: self.childNode(withName: "shelf1") as! SKSpriteNode))
        stations.append(StationNode(stationType: .shelf, spriteNode: self.childNode(withName: "shelf2") as! SKSpriteNode))
        stations.append(StationNode(stationType: .shelf, spriteNode: self.childNode(withName: "shelf3") as! SKSpriteNode))
        
        stations.append(StationNode(stationType: .delivery, spriteNode: self.childNode(withName: "delivery") as! SKSpriteNode))
        
        (self.childNode(withName: "target") as! SKSpriteNode).texture = SKTexture(imageNamed: "Target" + playerColor)
        
        let teleporterNode = (self.childNode(withName: "teleporter") as! SKSpriteNode)
        teleporterNode.texture = SKTexture(imageNamed: "Teleporter" + playerColor)
        
        createTeleporterAnimation(teleporterNode)
    }
    
    func setupPiping() {
        
        for (index, color) in colors.enumerated() {
            let pipeNode = self.childNode(withName: "pipe" + (index+1).description) as! SKSpriteNode
            pipeNode.texture = SKTexture(imageNamed: "Pipe" + color)
            pipeNode.name = "pipe" + (index+1).description
            pipeNode.zPosition = 2
            
            stations.append(StationNode(stationType: .pipe, spriteNode: pipeNode))
        }
        
        stations.append(StationNode(stationType: .hatch, spriteNode: self.childNode(withName: "hatch") as! SKSpriteNode))
    }
    
    func setupBackground() {
        let background = self.childNode(withName: "background") as! SKSpriteNode
        background.texture = SKTexture(imageNamed: "Background" + playerColor)
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
            orderGenerationCounter += 1
            
            if (orderGenerationCounter >= 1000 && orders.count < maxOrders) || orders.isEmpty {
                generateRandomOrder()
                GameConnectionManager.shared.sendEveryone(orderList: orders)
                orderGenerationCounter = 0
                
                // timer only starts when the first order is generated
                if !timerStarted {
                    timerStarted = true
                }
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
    
    fileprivate func updateTimer() {
        timerUpdateCounter += 1
        if timerStarted && timerUpdateCounter >= 60 {
            matchTimer -= 1
            updateTimerUI()
            timerUpdateCounter = 0
        }
        
        if hosting && matchTimer < 0 {
            GameConnectionManager.shared.sendEveryone(statistics: matchStatistics!)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        stations.forEach({ $0.update() })
        
        checkAnimations()
        updateOrders()
        updateTimer()
    }
    
    func makeDelivery(plate: Plate) -> Bool {
        
        let timePerFrame = TimeInterval(teleportDuration) / TimeInterval(teleportAnimationFrames.count)
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
    
    func updateOrderUI(_ orders: [Order]) {
        orderListNode.updateList(orders)
    }
    
    func updateTimerUI() {
        let timerLabel = self.childNode(withName: "timerLabel") as! SKLabelNode
        
        var currentSeconds = Int(ceil(matchTimer))
    
        let currentMinutes = currentSeconds / 60
        currentSeconds -= (currentMinutes * 60)
        
        timerLabel.text = "\(currentMinutes):\(currentSeconds > 9 ? currentSeconds.description : "0" + currentSeconds.description)"
        
        print("\(currentMinutes):\(currentSeconds > 9 ? currentSeconds.description : "0" + currentSeconds.description)")
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
        
        if !timerStarted {
            timerStarted = true
        }
        
        updateOrderUI(orders)
    }
    
    func receiveDeliveryNotification(notification: OrderDeliveryNotification) {
        print("[GameScene] Received new notification")
        
        if notification.success {
            matchStatistics?.totalDeliveredOrders += 1
            matchStatistics?.totalPoints += notification.coinsAdded
            totalPoints += notification.coinsAdded
            updateCoinsUI()
        }
    }
    
    func receiveStatistics(statistics: MatchStatistics) {
        self.isPaused = true
    }
    
}
