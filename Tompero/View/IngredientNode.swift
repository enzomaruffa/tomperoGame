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
    
    var currentStation: StationNode
    var ingredient: Ingredient
    var spriteNode: SKSpriteNode
    
    var rotationTimer: Timer?
    
    var scaleBeforeMove: CGFloat = 1
    
    init(ingredient: Ingredient, movableNode: MovableSpriteNode, currentLocation: StationNode) {
        self.ingredient = ingredient
        self.currentStation = currentLocation
        currentStation.ingredient = self.ingredient
        
        spriteNode = movableNode
        
        movableNode.position = currentLocation.spriteNode.position
        movableNode.tapDelegate = self
        movableNode.moveDelegate = self
    }
    
    private func hideSpriteNode() {
        // We use a very low alpha value otherwise it's interaction is disabled
        self.spriteNode.run(SKAction.fadeAlpha(to: 0.00001, duration: 0.1))
    }
    
    private func showSpriteNode() {
        self.spriteNode.run(SKAction.fadeIn(withDuration: 0.2))
    }
    
    private func setIngredientIn(_ station: StationNode) {
        currentStation.ingredient = nil
        currentStation.ingredientSlot = nil
        
        currentStation = station
        currentStation.ingredient = self.ingredient
        currentStation.ingredientSlot = self
    }
    
    // MARK: - MovableDelegate
    func attemptMove(to station: StationNode) -> Bool {
        
        print("Attempting move to \(station)")
        
        switch station.stationType {
        case .board:
            let canMove = ingredient.attemptChangeState(to: .chopping)
            if canMove {
                setIngredientIn(station)
                spriteNode.setScale(1)
            }
            print("Result: \(canMove)")
            return canMove
            
        case .stove:
            let canMove = ingredient.attemptChangeState(to: .cooking)
            if canMove {
                setIngredientIn(station)
                spriteNode.setScale(1)
            }
            print("Result: \(canMove)")
            return canMove
            
        case .fryer:
            let canMove = ingredient.attemptChangeState(to: .frying)
            if canMove {
                setIngredientIn(station)
                spriteNode.setScale(1)
            }
            print("Result: \(canMove)")
            return canMove

        case .shelf:
        setIngredientIn(station)
            spriteNode.setScale(0.7)
            print("Result: \(true)")
            return true
            
        default:
            return ingredient.attemptChangeState(to: ingredient.states[ingredient.currentState]!.first!)
        }
    }
    
    func moveStarted(currentPosition: CGPoint) {
        scaleBeforeMove = spriteNode.yScale
    }
    
    func moving(currentPosition: CGPoint) {
        if currentPosition.distanceTo(currentStation.spriteNode.position) > 60 && rotationTimer == nil {
            
            print("moving cuz \(currentPosition.distanceTo(currentStation.spriteNode.position)) and \(rotationTimer)")
            
            self.spriteNode.run(SKAction.scale(to: 0.7, duration: 0.2))
            
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
        if currentStation.stationType == .fryer || currentStation.stationType == .stove {
            hideSpriteNode()
        } else {
            showSpriteNode()
        }
        
        spriteNode.setScale(scaleBeforeMove)
        
        spriteNode.zRotation = 0
        spriteNode.removeAllActions()
        rotationTimer?.invalidate()
        rotationTimer = nil
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
