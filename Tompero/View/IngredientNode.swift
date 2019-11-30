//
//  IngredientNode.swift
//  Tompero
//
//  Created by Vinícius Binder on 29/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class IngredientNode {
    
    var ingredient: Ingredient
    var spriteNode: SKSpriteNode {
        SKSpriteNode(imageNamed: ingredient.textureName)
    }
    var currentLocation: StationNode!
    
    init(ingredient: Ingredient, currentLocation: StationNode!) {
        self.ingredient = ingredient
        self.currentLocation = currentLocation
    }
    
    private func disableSpriteNode() {
        spriteNode.isHidden = true
        spriteNode.isUserInteractionEnabled = false
    }
    
    func move(to station: StationNode) -> Bool {
        switch station.typeOfStation {
        case .board:
            return ingredient.changeState(to: .chopping)
            
        case .stove:
            disableSpriteNode()
            return ingredient.changeState(to: .cooking)
            
        case .fryer:
            disableSpriteNode()
            return ingredient.changeState(to: .frying)
            
        default:
            return ingredient.changeState(to: ingredient.states[ingredient.currentState]!.first!)
        }
    }
    
}
