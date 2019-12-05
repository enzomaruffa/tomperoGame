//
//  StationNode.swift
//  Tompero
//
//  Created by Vinícius Binder on 29/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class StationNode: TappableDelegate {
    
    var stationType: StationType
    var ingredient: Ingredient?
    var plate: Plate?
    
    var spriteNode: SKSpriteNode
    var spriteYPos: CGFloat {
        switch stationType {
        case .board: return -237.5
        case .stove: return -348.5
        case .fryer: return -342.0
        case .ingredientBox: return -200.0 // not final
        case .plateBox: return -200.0 // not final
        default: return 0
        }
    }
    
    var ingredientSlot: IngredientNode?
    
    internal init(stationType: StationType, spriteNode: SKSpriteNode?, ingredient: Ingredient?) {
        self.stationType = stationType
        self.ingredient = ingredient
        
        if stationType == .ingredientBox {
            let tappableNode = TappableSpriteNode(imageNamed: NSStringFromClass(type(of: ingredient!)) + "Box.png")
            self.spriteNode = tappableNode
            tappableNode.delegate = self
        } else if stationType == .shelf || stationType == .delivery ||  stationType == .pipe || stationType == .hatch {
            self.spriteNode = spriteNode!
        } else {
            let tappableNode = TappableSpriteNode(imageNamed: stationType.rawValue + ".png")
            self.spriteNode = tappableNode
            tappableNode.delegate = self
        }
    }
    
    convenience init(stationType: StationType, spriteNode: SKSpriteNode) {
        self.init(stationType: stationType, spriteNode: spriteNode, ingredient: nil)
    }
    
    convenience init(stationType: StationType, ingredient: Ingredient?) {
        self.init(stationType: stationType, spriteNode: nil, ingredient: ingredient)
    }
    
    // Tap interaction
    func tap() {
        if stationType == .board {
            ingredient?.choppableComponent?.update()

            if ingredient?.choppableComponent?.complete ?? false {
                if (ingredient!.states[ingredient!.currentState] ?? []).contains(IngredientState.chopped) {
                    ingredient?.currentState = .chopped
                }
            }
        }
    }
    
    // Scene update intercation
    func update() {
        if stationType == .stove {
            ingredient?.cookableComponent?.update()
            
            if ingredient?.cookableComponent?.burnt ?? false {
                if ingredient!.states[ingredient!.currentState]!.contains(IngredientState.burnt) {
                    ingredient?.currentState = .burnt
                    ingredientSlot?.checkTextureChange()
                }
            } else if ingredient?.cookableComponent?.complete ?? false {
                if ingredient!.states[ingredient!.currentState]!.contains(IngredientState.cooked) {
                    ingredient?.currentState = .cooked
                    ingredientSlot?.checkTextureChange()
                }
            }
            
        } else if stationType == .fryer {
            ingredient?.fryableComponent?.update()
            
            if ingredient?.fryableComponent?.burnt ?? false {
                if ingredient!.states[ingredient!.currentState]!.contains(IngredientState.burnt) {
                    ingredient?.currentState = .burnt
                    ingredientSlot?.checkTextureChange()
                }
            } else if ingredient?.fryableComponent?.complete ?? false {
                if ingredient!.states[ingredient!.currentState]!.contains(IngredientState.fried) {
                    ingredient?.currentState = .fried
                    ingredientSlot?.checkTextureChange()
                }
            }
        } else if stationType == .pipe {
            
        }
    }
}
