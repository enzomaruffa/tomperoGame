//
//  IngredientNode.swift
//  Tompero
//
//  Created by Vinícius Binder on 29/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class IngredientNode: TappableDelegate, MovableDelegate {
    
    // MARK: - Variables
    var currentStation: StationNode
    var ingredient: Ingredient
    var spriteNode: SKSpriteNode
    
    var rotationTimer: Timer?
    
    var scaleBeforeMove: CGFloat = 1
    var alphaBeforeMove: CGFloat = 1
    
    // MARK: - Initializers
    init(ingredient: Ingredient, movableNode: MovableSpriteNode, currentLocation: StationNode) {
        self.ingredient = ingredient
        self.currentStation = currentLocation
        currentStation.ingredient = self.ingredient
        
        spriteNode = movableNode
        
        movableNode.position = currentLocation.spriteNode.position
        movableNode.tapDelegate = self
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
        
    }
    
    func addIngredientTo(_ plateNode: PlateNode) {
        plateNode.plate.ingredients.append(self.ingredient)
        plateNode.updateTexture()
        
        //TODO: Remove ingredient node from scene destroy it whatever
        self.spriteNode.removeFromParent()
    }
    
    private func setIngredientIn(_ station: StationNode) {
        if currentStation.stationType != .ingredientBox {
            currentStation.ingredient = nil
        }
        currentStation.ingredientNode = nil
        
        // Check plate in station
        if let plateNode = station.plateNode {
            addIngredientTo(plateNode)
        } else {
            currentStation = station
            currentStation.ingredient = self.ingredient
            currentStation.ingredientNode = self
        }
        
    }
    
    // MARK: - MovableDelegate
    
    func attemptMove(to station: StationNode) -> Bool {
        
        print("Attempting move \(ingredient.texturePrefix) to \(station.stationType)")
        
        switch station.stationType {
        case .board:
            let canMove = station.ingredient == nil && ingredient.attemptChangeState(to: .chopping)
            if canMove {
                showSpriteNode()
                setIngredientIn(station)
                spriteNode.setScale(1)
            }
            print("Result: \(canMove)")
            return canMove
            
        case .stove:
            let canMove = station.ingredient == nil && ingredient.attemptChangeState(to: .cooking)
            if canMove {
                hideSpriteNode()
                setIngredientIn(station)
                spriteNode.setScale(1)
            }
            print("Result: \(canMove)")
            return canMove
            
        case .fryer:
            let canMove = station.ingredient == nil && ingredient.attemptChangeState(to: .frying)
            if canMove {
                hideSpriteNode()
                setIngredientIn(station)
                spriteNode.setScale(1)
            }
            print("Result: \(canMove)")
            return canMove
            
        case .shelf:
            let canMove = station.ingredient == nil && ((station.plateNode != nil && ingredient.currentState == ingredient.finalState) || station.plateNode == nil)
            if canMove {
                showSpriteNode()
                setIngredientIn(station)
                spriteNode.setScale(0.6)
            }
            
            print("Result: \(canMove)")
            return canMove
            
        case .pipe:
            // check if plate
            
            var playerToSendTo: String = ""
            let scene = station.spriteNode.parent as! GameScene
            switch station.spriteNode.name {
            case "pipe1": playerToSendTo = scene.players[0]
            case "pipe2": playerToSendTo = scene.players[1]
            case "pipe3": playerToSendTo = scene.players[2]
            default: return false
            }
            GameConnectionManager.shared.send(ingredient: self.ingredient, to: playerToSendTo)
            print(playerToSendTo)
            implodeSpriteNode()
            return true
            
        case .hatch:
            implodeSpriteNode()
            return true
            
        case .plateBox:
            if ingredient.finalState == ingredient.currentState, let plateNode = station.plateNode {
                addIngredientTo(plateNode)
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
    
    // MARK: - TappableDelegate
    func tap() {
        print("Ingredient tapped")
        currentStation.tap()
        checkTextureChange()
    }
    
    func checkTextureChange() {
        if ingredient.textureName != spriteNode.texture?.name {
            spriteNode.texture = SKTexture(imageNamed: ingredient.textureName)
        }
    }
    
}

extension SKTexture {
    var name: String? {
        let comps = description.components(separatedBy: "'")
        return comps.count > 1 ? comps[1] : nil
    }
}
