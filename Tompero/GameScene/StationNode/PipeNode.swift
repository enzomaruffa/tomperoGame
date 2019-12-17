//
//  PipeNode.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 16/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class PipeNode: StationNode {
    
    override var ingredientNodeScale: CGFloat {
        0.5
    }
    
    override var plateNodeScale: CGFloat {
        0.5
    }
    
    override var stationAnimationAtlasName: String? {
        "PipeVacuum"
    }
    
    override var stationAnimationDuration: Double {
        0.3
    }
    
    override var stationAnimationOffset: CGPoint {
        CGPoint(x: 3.5, y: 0)
    }
    
    override var stationAnimationScale: CGFloat {
        0.05
    }
    
    init(node: SKSpriteNode) {
        super.init(stationType: .pipe)
        self.spriteNode = node
    }
}
