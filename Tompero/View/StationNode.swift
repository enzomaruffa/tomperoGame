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
    
    var typeOfStation: StationType
    var ingredient: Ingredient?
    
    var spriteNode: SKSpriteNode
    var spriteYPos: CGFloat {
        switch typeOfStation {
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
    
    internal init(typeOfStation: StationType, spriteNode: SKSpriteNode?, ingredient: Ingredient?) {
        self.typeOfStation = typeOfStation
        self.ingredient = ingredient
        
        if typeOfStation == .ingredientBox {
            self.spriteNode = SKSpriteNode(imageNamed: NSStringFromClass(type(of: ingredient!)) + "Box.png")
        } else if typeOfStation == .shelf || typeOfStation == .delivery {
            self.spriteNode = spriteNode!
        } else {
            self.spriteNode = SKSpriteNode(imageNamed: typeOfStation.rawValue + ".png")
        }
    }
    
    convenience init(typeOfStation: StationType, spriteNode: SKSpriteNode) {
        self.init(typeOfStation: typeOfStation, spriteNode: spriteNode, ingredient: nil)
    }
    
    convenience init(typeOfStation: StationType, ingredient: Ingredient?) {
        self.init(typeOfStation: typeOfStation, spriteNode: nil, ingredient: ingredient)
    }
}
