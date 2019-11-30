//
//  StationNode.swift
//  Tompero
//
//  Created by Vinícius Binder on 29/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class StationNode {
    
    var stationType: StationType
    var ingredient: Ingredient?
    
    var spriteNode: SKSpriteNode
    var spriteYPos: CGFloat {
        switch stationType {
        case .board: return -237.5
        case .stove: return -348.5
        case .fryer: return -342.0
        case .ingredientBox: return -200.0 // not final
        case .plateBox: return -200.0 // not final
        case .shelf: return -200.0 // not final
        case .delivery: return -200.0 // not final
        }
    }
    
    var ingredientSlot: IngredientNode?
    
    internal init(stationType: StationType, spriteNode: SKSpriteNode?, ingredient: Ingredient?) {
        self.stationType = stationType
        self.ingredient = ingredient
        
        if stationType == .ingredientBox {
            self.spriteNode = SKSpriteNode(imageNamed: NSStringFromClass(type(of: ingredient!)) + "Box.png")
        } else if stationType == .shelf || stationType == .delivery {
            self.spriteNode = spriteNode!
        } else {
            self.spriteNode = SKSpriteNode(imageNamed: stationType.rawValue + ".png")
        }
    }
    
    convenience init(stationType: StationType, spriteNode: SKSpriteNode) {
        self.init(stationType: stationType, spriteNode: spriteNode, ingredient: nil)
    }
    
    convenience init(stationType: StationType, ingredient: Ingredient?) {
        self.init(stationType: stationType, spriteNode: nil, ingredient: ingredient)
    }
    
    func update() {
        if stationType == .board {
            ingredient?.choppableComponent?.update()
        } else if stationType == .stove {
            ingredient?.cookableComponent?.update()
        } else if stationType == .fryer {
            ingredient?.fryableComponent?.update()
        }
    }
}
