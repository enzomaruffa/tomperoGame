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
    
    // MARK: - MovableDelegate
    func attemptMove(to station: StationNode) -> Bool {
        
        switch station.stationType {
        case .board:
            let canMove = ingredient.attemptChangeState(to: .chopping)
            if canMove {
                currentStation = station
                currentStation.ingredient = self.ingredient
            }
            return canMove
            
        case .stove:
            let canMove = ingredient.attemptChangeState(to: .cooking)
            if canMove {
                currentStation = station
                currentStation.ingredient = self.ingredient
            }
            return canMove
            
        case .fryer:
            let canMove = ingredient.attemptChangeState(to: .frying)
            if canMove {
                currentStation = station
                currentStation.ingredient = self.ingredient
            }
            return canMove
            
        default:
            currentStation = station
            currentStation.ingredient = self.ingredient
            return ingredient.attemptChangeState(to: ingredient.states[ingredient.currentState]!.first!)
        }
    }
    
    func moveStarted(currentPosition: CGPoint) {
        self.spriteNode.run(SKAction.scale(to: 0.7, duration: 0.2))
    }
    
    func moving(currentPosition: CGPoint) {
        
    }
    
    func moveEnded(currentPosition: CGPoint) {
        self.spriteNode.run(SKAction.scale(to: 1, duration: 0.2))
        
        print(currentStation.stationType)
        if currentStation.stationType == .fryer || currentStation.stationType == .stove {
            hideSpriteNode()
        } else {
            showSpriteNode()
        }
    }
    
    // MARK: - TappableDelegate
    func tap() {
        print("Ingredient tapped")
        currentStation.tap()
    }
    
}
