//
//  ShelfNode.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 15/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class ShelfNode: StationNode {
    
    override var ingredientNodeScale: CGFloat {
        0.7
    }
    
    override var plateNodeScale: CGFloat {
        0.6
    }
    
    override var ingredientNode: IngredientNode? {
        didSet {
            ingredientNode?.spriteNode.setScale(ingredientNodeScale)
            
            if ingredientNode != nil {
                progressBarNode?.alpha = 1
            } else {
                progressBarNode?.alpha = 0
            }
        }
    }
    
    init(node: SKSpriteNode) {
        super.init(stationType: .shelf, spriteNode: nil, ingredient: nil)
        
        self.spriteNode = node
    }
    
    override func playAnimation() {}
    override func stopAnimation() {}
    
}
