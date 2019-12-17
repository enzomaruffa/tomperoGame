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
    
    init(node: SKSpriteNode) {
        super.init(stationType: .shelf)
        self.spriteNode = node
    }
}
