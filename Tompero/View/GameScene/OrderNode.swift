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
        super.init(texture: texture, color: #colorLiteral(red: 1, green: 0.270588249, blue: 0.2274509817, alpha: 1) /*UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0)*/, size: CGSize(width: 518, height: 568))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func spawnIngredientIcons() {
        
        let xPos: [CGFloat] = [-190.0, -62.5, 62.5, 190]
        let yPos: [CGFloat] = [-4.0, -72.0, -140.0]
        
        for (index, ingredient) in order!.ingredients.enumerated() {
            let circle = SKSpriteNode(imageNamed: "IngredientIndicator")
            self.addChild(circle)
            circle.position = CGPoint(x: xPos[index], y: 120)
            circle.zPosition = 7
            circle.size = CGSize(width: 110, height: 110)
            
            let node = SKSpriteNode(imageNamed: ingredient.texturePrefix + "Raw")
            circle.addChild(node)
            node.zPosition = 8
            node.size = CGSize(width: 100, height: 100)
            
            // order ingredient.states
            // +1 ingredient; separate bread
            
            var jndex = 0
            for state in ingredient.states {
                var name = ""
                switch state.key {
                case .chopping: name = "Chop"
                case .cooking: name = "Cook"
                case .frying: name = "Fry"
                default: continue // guard
                }
                
                let actionNode = SKSpriteNode(imageNamed: name + "Icon")
                actionNode.position = CGPoint(x: xPos[index], y: yPos[jndex])
                jndex += 1
                actionNode.zPosition = 9
                actionNode.setScale(0.65)
                self.addChild(actionNode)
            }
        }
    }
    
    func updateTimer() {
        
    }
}
