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
    
    var orderListNode: SKLabelNode!
    var orderGenerationCounter = 400
    
    var stationsAnimationsRunning = false
    
    private var teleportAnimationNode: SKSpriteNode!
    private var teleportAnimationFrames: [SKTexture]!
    private let teleportDuration = 1
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        // Adds itself as a GameConnection observer
        GameConnectionManager.shared.subscribe(observer: self)
        
        orderListNode = self.childNode(withName: "orderListNode") as! SKLabelNode
        orderListNode.numberOfLines = 0
        
        setupStations()
        setupShelves()
        setupPiping()
        setupBackground()
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
        
        print("Creating \(teleportAnimationNode) with textures \(teleportAnimationFrames)")
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
    
    // MARK: - Game Logic
    
    func generateRandomOrder() {
        let order = rule?.generateOrder()
        orders.append(order!)
        
        updateOrderUI(orders)
    }
    
    override func update(_ currentTime: TimeInterval) {
        stations.forEach({ $0.update() })
        
        let isMoving = !stations.filter({ ($0.ingredientNode?.moving ?? false || $0.plateNode?.moving ?? false) }).isEmpty
        
        print("\(isMoving), \(stationsAnimationsRunning)")
        
        if isMoving && !stationsAnimationsRunning {
            print("Should play animation!")
            pipes.forEach({ $0.playAnimation() })
            hatch.playAnimation()
            stationsAnimationsRunning = true
        } else if !isMoving && stationsAnimationsRunning {
            print("Should stop animation!")
            pipes.forEach({ $0.stopAnimation() })
            hatch.stopAnimation()
            stationsAnimationsRunning = false
        }
        
        if hosting {
            orderGenerationCounter += 1
            
            if orderGenerationCounter >= 1000 {
                generateRandomOrder()
                GameConnectionManager.shared.sendEveryone(orderList: orders)
                orderGenerationCounter = 0
            }
        }
        
    }
    
    func makeDelivery(plate: Plate) -> Bool {
        print("Existing orders: \(orders.map({$0.ingredients.map({ $0.texturePrefix })}))")
        print("Existing orders types: \(orders.map({$0.ingredients.map({ type(of: $0) })}))")
        
        print("Plate: \((plate.ingredients.map({ $0.texturePrefix })))")
        print("Plate types: \((plate.ingredients.map({ type(of: $0) })))")
        
        let timePerFrame = TimeInterval(teleportDuration) / TimeInterval(teleportAnimationFrames.count)
        teleportAnimationNode.run(SKAction.animate(
            with: teleportAnimationFrames,
            timePerFrame: timePerFrame,
            resize: false,
            restore: true))
        
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
        
        if orders.isEmpty {
            print("Orders are now empty! Generating a new one")
            generateRandomOrder()
        }
        
        GameConnectionManager.shared.sendEveryone(orderList: orders)
        
        orderGenerationCounter = 0
        updateOrderUI(orders)
        return true
    }
    
    func updateOrderUI(_ orders: [Order]) {
        let ordersInString = orders.map({ $0.ingredients.map({ $0.texturePrefix }).joined(separator: ", ") })
        orderListNode.text = ordersInString.joined(separator: "\n")
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
        
        updateOrderUI(orders)
    }
    
    func receiveDeliveryNotification(notification: OrderDeliveryNotification) {
        print("[GameScene] Received new notification")
        
    }
}
