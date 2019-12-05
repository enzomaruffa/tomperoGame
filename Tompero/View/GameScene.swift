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
    var player: String = MCManager.shared.selfName
    var rule: GameRule?
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
    
    var ingredients: [IngredientNode] = []
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        // Adds itself as a GameConnection observer
        GameConnectionManager.shared.subscribe(observer: self)
        
        setupStations()
        setupShelves()
        setupPiping()
        setupBackground()
        
        let tentacleNode = self.childNode(withName: "ingredient") as! MovableSpriteNode
        let tentacle = IngredientNode(ingredient: Tentacle(), movableNode: tentacleNode, currentLocation: shelves.first!)
        tentacleNode.name = "denis"
        ingredients.append(tentacle)
        
        let eyesNode = MovableSpriteNode(imageNamed: "EyesRaw")
        let eyes = IngredientNode(ingredient: Eyes(), movableNode: eyesNode, currentLocation: shelves[1])
        eyesNode.name = "paulo"
        self.addChild(eyesNode)
        ingredients.append(eyes)
        
        let moonCheeseNode = MovableSpriteNode(imageNamed: "MoonCheeseRaw")
        let moonCheese = IngredientNode(ingredient: MoonCheese(), movableNode: moonCheeseNode, currentLocation: shelves[2])
        moonCheeseNode.name = "nariana"
        self.addChild(moonCheeseNode)
        ingredients.append(moonCheese)
    }
    
    func setupStations() {
        func convertTableToStation(type: PlayerTableType) -> StationType {
            switch type {
            case .chopping: return .board
            case .cooking: return .stove
            case .frying: return .fryer
            case .plate: return .plateBox
            case .ingredient: return .ingredientBox
            default: return .board
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
    
    func setupShelves() {
        stations.append(StationNode(stationType: .shelf, spriteNode: self.childNode(withName: "shelf1") as! SKSpriteNode))
        stations.append(StationNode(stationType: .shelf, spriteNode: self.childNode(withName: "shelf2") as! SKSpriteNode))
        stations.append(StationNode(stationType: .shelf, spriteNode: self.childNode(withName: "shelf3") as! SKSpriteNode))
        
        stations.append(StationNode(stationType: .delivery, spriteNode: self.childNode(withName: "delivery") as! SKSpriteNode))
        
        (self.childNode(withName: "target") as! SKSpriteNode).texture = SKTexture(imageNamed: "Target" + playerColor)
        
        (self.childNode(withName: "teleporter") as! SKSpriteNode).texture = SKTexture(imageNamed: "Teleporter" + playerColor)
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
    override func update(_ currentTime: TimeInterval) {
        stations.forEach({ $0.update() })
    }
}

// MARK: - GameConnectionManagerObserver Methods
extension GameScene: GameConnectionManagerObserver {
    func receivePlate(plate: Plate) {
        print("[GameScene] Received plate")
    }
    
    func receiveIngredient(ingredient: Ingredient) {
        print("[GameScene] Received ingredient with prefix \(ingredient.texturePrefix) and state as \(ingredient.currentState)")
    }
}
