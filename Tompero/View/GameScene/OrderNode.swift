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
        super.init(texture: texture, color: UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0), size: CGSize(width: 10.5, height: 36.0))
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
        case 0: return CGPoint(x: -120, y: -90)
        case 1: return CGPoint(x: -40, y: -90)
        case 2: return CGPoint(x: 40, y: -90)
        case 3: return CGPoint(x: 120, y: -90)
        case 4: return CGPoint(x: -120, y: -170)
        case 5: return CGPoint(x: -40, y: -170)
        case 6: return CGPoint(x: 40, y: -170)
        case 7: return CGPoint(x: 120, y: -170)
        default: return CGPoint()
        }
    }
    
    private func spawnIngredientIcons() {
        for (index, ingredient) in order!.ingredients.enumerated() {
            
            let circle = SKSpriteNode(imageNamed: "IngredientIndicator")
            self.addChild(circle)
            circle.position = position(ofIngredient: index)
            circle.zPosition = 7
            circle.size = CGSize(width: 60, height: 60)
            
            let node = SKSpriteNode(imageNamed: ingredient.texturePrefix + "Raw")
            circle.addChild(node)
            node.zPosition = 8
            node.size = CGSize(width: 25, height: 25)
        }
    }
    
    private func spawnFoodIcon() {
        
    }
    
    func updateTimer() {
        
    }
}
