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
    //var tables: [PlayerTable]?
    var tables: [PlayerTable] = [
        PlayerTable(type: .chopping, ingredient: nil),
        PlayerTable(type: .cooking, ingredient: nil),
        PlayerTable(type: .frying, ingredient: nil)
    ]
    var player: String = ""
    
    var stations: [StationNode] = []
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        // Adds itself as a GameConnection observer
        GameConnectionManager.shared.subscribe(observer: self)
        
        setupStations()
        setupShelves()
//        setupPipes()
//        setupHatch()
//        setupBackground()
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
        stations.append(StationNode(stationType: .shelf, spriteNode: scene?.childNode(withName: "shelf1") as! SKSpriteNode))
        stations.append(StationNode(stationType: .shelf, spriteNode: scene?.childNode(withName: "shelf2") as! SKSpriteNode))
        stations.append(StationNode(stationType: .shelf, spriteNode: scene?.childNode(withName: "shelf3") as! SKSpriteNode))
        
        // change color
        stations.append(StationNode(stationType: .delivery, spriteNode: scene?.childNode(withName: "delivery") as! SKSpriteNode))
    }
    
    // MARK: - Game Logic
}

// MARK: - GameConnectionManagerObserver Methods
extension GameScene: GameConnectionManagerObserver {
    func receivePlate(plate: Plate) {
        
    }
    
    func receiveIngredient(ingredient: Ingredient) {
        
    }
}
