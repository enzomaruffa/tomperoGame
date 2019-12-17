//
//  DeliveryNode.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 16/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class DeliveryNode: StationNode {
    
    override var ingredientNodeScale: CGFloat {
        0.7
    }
    
    override var plateNodeScale: CGFloat {
        0.45
    }
    
    init(node: SKSpriteNode) {
        super.init(stationType: .delivery)
        self.spriteNode = node
    }
}
