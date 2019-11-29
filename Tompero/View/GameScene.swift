//
//  GameScene.swift
//  Tompero
//
//  Created by Vinícius Binder on 22/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // MARK: - Variables
    //var tables: [PlayerTable]?
    var tables: [PlayerTable] = [
        PlayerTable(type: .chopping, ingredient: nil),
        PlayerTable(type: .cooking, ingredient: nil),
        PlayerTable(type: .frying, ingredient: nil)
    ]
    var player: String = ""
    
    var stations: [(SKSpriteNode, PlayerTable)]?
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        // Adds itself as a GameConnection observer
        GameConnectionManager.shared.subscribe(observer: self)
        
        setupStations()
    }
    
    func setupStations() {
        for (index, station) in tables.enumerated() {
            let node = SKSpriteNode(imageNamed: station.spriteImageName)
            
            let pos = scene!.size.width/2-node.size.width/2
            let xPos = [-pos, 0.0, pos]
            node.position = CGPoint(x: xPos[index], y: station.spriteYPos)
            
//            for extra in station.secondarySpritesImageNames {
//
//            }
            
            self.addChild(node)
            self.stations?.append((node, station))
        }
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
