//
//  HatchNode.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 16/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class HatchNode: StationNode {
    
    override var ingredientNodeScale: CGFloat {
        0.5
    }
    
    override var plateNodeScale: CGFloat {
        0.5
    }
    
    override var stationAnimationAtlasName: String? {
        "HatchVacuum"
    }
    
    override var stationAnimationDuration: Double {
        0.8
    }
    
    override var stationAnimationOffset: CGPoint {
        CGPoint(x: 48, y: 0)
    }
    
    override var stationAnimationScale: CGFloat {
        0.8
    }
    
    override var stationAnimationResize: Bool {
        false
    }
    
    init(node: SKSpriteNode) {
        super.init(stationType: .hatch)
        self.spriteNode = node
    }
    
    override func playAnimation() {
        super.playAnimation()
        SFXPlayer.shared.hatch.play()
        SFXPlayer.shared.airSuction.play()
    }
    
    override func stopAnimation() {
        super.stopAnimation()
        SFXPlayer.shared.airSuction.stop()
        stationAnimationNode?.size = CGSize(width: 792*0.8, height: 668*0.8)
    }
}
