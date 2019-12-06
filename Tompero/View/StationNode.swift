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
    
    var spriteNode: SKSpriteNode
    var spriteYPos: CGFloat {
        switch stationType {
        case .board: return -237.5
        case .stove: return -348.5
        case .fryer: return -342.0
        case .ingredientBox: return -361.0 // not final
        case .plateBox: return -361.0 // not final
        default: return 0
        }
    }
    
    var ingredientNode: IngredientNode? {
        didSet {
            if stationType == .stove || stationType == .fryer {
                var indicatorNode = spriteNode.children.first as? SKSpriteNode
                if indicatorNode == nil {
                    indicatorNode = SKSpriteNode(imageNamed: "IngredientIndicator")
                    spriteNode.addChild(indicatorNode!)
                    indicatorNode!.zPosition = 2
                    indicatorNode!.scale(to: CGSize(width: 170, height: 170))
                    indicatorNode!.position = CGPoint(x: -260, y: 170)
                }
                
                if let ingredient = ingredientNode?.ingredient {
                    let iconNode = SKSpriteNode(imageNamed: ingredient.texturePrefix + "Icon")
                    iconNode.zPosition = 3
                    iconNode.scale(to: CGSize(width: 110, height: 110))
                    indicatorNode?.addChild(iconNode)
                } else {
                    indicatorNode?.removeAllChildren()
                }
            }
        }
    }
    var plateNode: PlateNode?
    
    internal init(stationType: StationType, spriteNode: SKSpriteNode?, ingredient: Ingredient?) {
        self.stationType = stationType
        self.ingredient = ingredient
        
        if stationType == .ingredientBox {
            let tappableNode = TappableSpriteNode(imageNamed: ingredient!.texturePrefix + "Box.png")
            self.ingredient = ingredient
            self.spriteNode = tappableNode
            tappableNode.delegate = self
        } else if stationType == .plateBox {
            let tappableNode = TappableSpriteNode(imageNamed: "PlateBox.png")
            self.spriteNode = tappableNode
            tappableNode.delegate = self
        } else if stationType == .shelf || stationType == .delivery ||  stationType == .pipe || stationType == .hatch {
            self.spriteNode = spriteNode!
        } else if stationType == .empty {
            let tappableNode = TappableSpriteNode()
            self.spriteNode = tappableNode
            tappableNode.delegate = self
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
        } else if stationType == .ingredientBox && self.ingredientNode == nil {
            let newIngredient = ingredient!.findDowncast()
            let ingredientMovableNode = MovableSpriteNode(imageNamed: newIngredient.textureName)
            spriteNode.scene!.addChild(ingredientMovableNode)
            ingredientMovableNode.zPosition = 4
            let ingredientNode = IngredientNode(ingredient: newIngredient, movableNode: ingredientMovableNode, currentLocation: self)
            ingredientMovableNode.position = CGPoint(x: spriteNode.position.x, y: spriteNode.position.y + 85)
            self.ingredientNode = ingredientNode
        } else if stationType == .plateBox && self.plateNode == nil {
            let newPlate = Plate()
            let plateMovableNode = MovableSpriteNode(imageNamed: newPlate.textureName)
            spriteNode.scene!.addChild(plateMovableNode)
            plateMovableNode.zPosition = 4
            let plateNode = PlateNode(plate: newPlate, movableNode: plateMovableNode, currentLocation: self)
            plateMovableNode.position = CGPoint(x: spriteNode.position.x, y: spriteNode.position.y + 85)
            self.plateNode = plateNode
        }
    }
    
    // Scene update intercation
    func update() {
        if stationType == .stove {
            ingredient?.cookableComponent?.update()
            
            if ingredient?.cookableComponent?.burnt ?? false {
                if ingredient!.states[ingredient!.currentState]!.contains(IngredientState.burnt) {
                    ingredient?.currentState = .burnt
                    ingredientNode?.checkTextureChange()
                }
            } else if ingredient?.cookableComponent?.complete ?? false {
                if ingredient!.states[ingredient!.currentState]!.contains(IngredientState.cooked) {
                    ingredient?.currentState = .cooked
                    ingredientNode?.checkTextureChange()
                }
            }
            
        } else if stationType == .fryer {
            ingredient?.fryableComponent?.update()
            
            if ingredient?.fryableComponent?.burnt ?? false {
                if ingredient!.states[ingredient!.currentState]!.contains(IngredientState.burnt) {
                    ingredient?.currentState = .burnt
                    ingredientNode?.checkTextureChange()
                }
            } else if ingredient?.fryableComponent?.complete ?? false {
                if ingredient!.states[ingredient!.currentState]!.contains(IngredientState.fried) {
                    ingredient?.currentState = .fried
                    ingredientNode?.checkTextureChange()
                }
            }
        } else if stationType == .pipe {
            
        }
    }
}
