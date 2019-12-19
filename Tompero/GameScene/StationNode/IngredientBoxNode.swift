//
//  IngredientBoxNode.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 16/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class IngredientBoxNode: StationNode {
    
    override var spriteYPos: CGFloat {
        -361
    }
    
    init(ingredient: Ingredient) {
        super.init(stationType: .ingredientBox)
        
        self.ingredient = ingredient
        
        let tappableNode = TappableSpriteNode(imageNamed: ingredient.texturePrefix + "Box.png")
        self.spriteNode = tappableNode
        tappableNode.delegate = self
    }
    
    override func tap() {
        if self.ingredientNode == nil {
            
            SFXPlayer.shared.takeFood.play()
            
            let newIngredient = ingredient!.findDowncast()
            
            let ingredientMovableNode = MovableSpriteNode(imageNamed: newIngredient.textureName)
            spriteNode.scene!.addChild(ingredientMovableNode)
            ingredientMovableNode.zPosition = 4
            
            let ingredientNode = IngredientNode(ingredient: newIngredient, movableNode: ingredientMovableNode, currentLocation: self)
            ingredientMovableNode.position = CGPoint(x: spriteNode.position.x, y: spriteNode.position.y + 85)
            
            self.ingredientNode = ingredientNode
        }
    }
}
