//
//  PlateNode.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 05/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class PlateNode: MovableDelegate {
    
    // MARK: - Variables
    var currentStation: StationNode
    var plate: Plate
    var spriteNode: SKSpriteNode
    
    var rotationTimer: Timer?
    
    var scaleBeforeMove: CGFloat = 1
    var alphaBeforeMove: CGFloat = 1
    
    // MARK: - Initializers
    init(plate: Plate, movableNode: MovableSpriteNode, currentLocation: StationNode) {
        self.plate = plate
        self.currentStation = currentLocation
        
        spriteNode = movableNode
        
        currentStation.plateNode = self
        
        movableNode.position = currentLocation.spriteNode.position
        movableNode.moveDelegate = self
    }
    
    // MARK: - Methods
    private func hideSpriteNode() {
        // We use a very low alpha value otherwise its interaction is disabled
        self.spriteNode.run(SKAction.fadeAlpha(to: 0.0001, duration: 0.05))
    }
    
    private func showSpriteNode() {
        self.spriteNode.alpha = 1
    }
    
    private func implodeSpriteNode() {
        self.currentStation.plateNode = nil
        spriteNode.removeFromParent()
    }
    
    private func setPlateIn(_ station: StationNode) {
        currentStation.plateNode = nil
        
        // Check if ingredient exists in station
        if let ingredientNode = station.ingredientNode {
            self.plate.ingredients.append(ingredientNode.ingredient)
            self.updateTexture()
            
            //TODO: Remove ingredient node from scene destroy it whatever
            ingredientNode.spriteNode.removeFromParent()
        } else {
            currentStation = station
            currentStation.plateNode = self
        }
        
    }
    
    func updateTexture() {
        var zPos = CGFloat(3)
        self.spriteNode.removeAllChildren()
        self.spriteNode.zPosition = zPos
        
        let breadList = [SpaceshipHull(), DevilMashedBread(), Asteroid()]
        var sortedIngredients = plate.ingredients.sorted(by: { $0.texturePrefix < $1.texturePrefix })
        
        sortedIngredients.forEach { print($0.texturePrefix, type(of: $0)) }
        
        if let firstBread = sortedIngredients.filter({ breadList.contains($0) }).first {
            sortedIngredients.removeAll(where: { $0 == firstBread })
            
            // Render bread bottom
            var newNode = SKSpriteNode(imageNamed: firstBread.texturePrefix + "Bottom")
            newNode.position = CGPoint(x: 0, y: 35)
            zPos += 1
            newNode.zPosition = zPos
            self.spriteNode.addChild(newNode)
            
            for (index, ingredient) in sortedIngredients.enumerated() {
                newNode = SKSpriteNode(imageNamed: ingredient.textureName)
                newNode.position = CGPoint(x: 0, y: 45 + index * 3)
                zPos += 1
                newNode.zPosition = zPos
                self.spriteNode.addChild(newNode)
            }
            
            // Render bread top
            newNode = SKSpriteNode(imageNamed: firstBread.texturePrefix + "Top")
            newNode.position = CGPoint(x: 0, y: 175 + sortedIngredients.count * 4)
            zPos += 1
            newNode.zPosition = zPos
            self.spriteNode.addChild(newNode)
            
        } else {
            // Render ingredients in plate
            var zPos = CGFloat(3)
            for (index, ingredient) in sortedIngredients.enumerated() {
                let newNode = SKSpriteNode(imageNamed: ingredient.textureName)
                newNode.position = CGPoint(x: 0, y: 30 + index * 3)
                zPos += 1
                newNode.zPosition = zPos
                self.spriteNode.addChild(newNode)
            }
        }
    }
    
    // MARK: - MovableDelegate
    func attemptMove(to station: StationNode) -> Bool {
        
        print("Attempting move to \(station.stationType)")
        
        switch station.stationType {
        case .board:
            return false
            
        case .stove:
            return false
            
        case .fryer:
            return false
            
        case .shelf:
            let canMove =
                station.plateNode == nil &&
                    ((station.ingredientNode?.ingredient != nil && station.ingredientNode?.ingredient.currentState == station.ingredientNode?.ingredient.finalState)
                        || station.ingredientNode?.ingredient == nil)
            if canMove {
                showSpriteNode()
                setPlateIn(station)
            }
            print("Result: \(canMove)")
            return canMove
            
        case .pipe:
            var playerToSendTo: String = ""
            let scene = station.spriteNode.parent as! GameScene
            switch station.spriteNode.name {
            case "pipe1": playerToSendTo = scene.players[0]
            case "pipe2": playerToSendTo = scene.players[1]
            case "pipe3": playerToSendTo = scene.players[2]
            default: return false
            }
            
            GameConnectionManager.shared.send(plate: self.plate, to: playerToSendTo)
        
            implodeSpriteNode()
            return true
            
        case .hatch:
            implodeSpriteNode()
            return true
            
        case .delivery:
            
            if let scene = spriteNode.scene as? GameScene {
                setPlateIn(station)
                
                print("Attempting plate delviery")
                let success = scene.makeDelivery(plate: self.plate)
                
                implodeSpriteNode()
                
                return true
            }
            
            return false
            
        default:
            return false
        }
    }
    
    func moveStarted(currentPosition: CGPoint) {
        scaleBeforeMove = spriteNode.yScale
        alphaBeforeMove = spriteNode.alpha
    }
    
    func moving(currentPosition: CGPoint) {
        if currentPosition.distanceTo(currentStation.spriteNode.position) > 80 && rotationTimer == nil {
            
            self.spriteNode.run(SKAction.scale(to: 0.7, duration: 0.2))
            self.spriteNode.alpha = 1
            
            let duration = 0.2
            
            let minRotation = CGFloat(-0.3)
            let maxRotation = CGFloat(+0.3)
            spriteNode.run(SKAction.rotate(toAngle: minRotation - 0.1, duration: duration))
            
            rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true, block: { (_) in
                if self.spriteNode.zRotation >= maxRotation {
                    self.spriteNode.run(SKAction.rotate(toAngle: minRotation - 0.02, duration: duration))
                } else if self.spriteNode.zRotation <= minRotation {
                    self.spriteNode.run(SKAction.rotate(toAngle: maxRotation + 0.02, duration: duration))
                }
            })
        }
    }
    
    func moveEnded(currentPosition: CGPoint) {
        spriteNode.zRotation = 0
        spriteNode.removeAllActions()
        rotationTimer?.invalidate()
        rotationTimer = nil
    }
    
    func moveCancel(currentPosition: CGPoint) {
        print("Move cancelled")
        spriteNode.setScale(scaleBeforeMove)
        spriteNode.alpha = alphaBeforeMove
    }
    
}
