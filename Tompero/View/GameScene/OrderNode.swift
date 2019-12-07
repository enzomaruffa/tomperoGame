//
//  OrderNode.swift
//  Tompero
//
//  Created by Vinícius Binder on 06/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class OrderNode: SKSpriteNode {
    
    var order: Order?
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: .red, size: CGSize(width: 10.5, height: 36.0))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initOrder() {
        spawnIngredientIcons()
        spawnFoodIcon()
        updateTimer()
    }
    
    private func position(ofIngredient index: Int) -> CGPoint {
        switch index {
        case 0: return CGPoint(x: -30, y: -19)
        case 1: return CGPoint(x: -10, y: -19)
        case 2: return CGPoint(x: 10, y: -19)
        case 3: return CGPoint(x: 30, y: -19)
        case 4: return CGPoint(x: -30, y: -37)
        case 5: return CGPoint(x: -10, y: -37)
        case 6: return CGPoint(x: 10, y: -37)
        case 7: return CGPoint(x: 30, y: -37)
        default: return CGPoint()
        }
    }
    
    private func spawnIngredientIcons() {
        for (index, ingredient) in order!.ingredients.enumerated() {
            
            let circle = SKSpriteNode(imageNamed: "IngredientIndicator")
            circle.position = position(ofIngredient: index)
            circle.zPosition = 7
            circle.size = CGSize(width: 17, height: 17)
            
            let node = SKSpriteNode(imageNamed: ingredient.texturePrefix + "Raw")
            node.zPosition = 8
            node.size = CGSize(width: 13, height: 13)
            
            circle.addChild(node)
        }
    }
    
    private func spawnFoodIcon() {
        
    }
    
    func updateTimer() {
        
    }
}
