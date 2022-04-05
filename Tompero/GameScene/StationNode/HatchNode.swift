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
        CGPoint(x: 52, y: -2)
    }
    
    override var stationAnimationScale: CGFloat {
        0.85
    }
    
    override var stationAnimationResize: Bool {
        false
    }
    
    init(node: SKSpriteNode) {
        super.init(stationType: .hatch)
        self.spriteNode = node
        self.spriteNode.texture = .none
        self.spriteNode.color = .clear
        createAnimation()
    }
    
    override func createAnimation() {
        if let stationAnimationAtlasName = stationAnimationAtlasName {
            let stationAtlas = SKTextureAtlas(named: stationAnimationAtlasName)
            stationAnimationFrames = []

            for currentAnimation in 0..<stationAtlas.textureNames.count {
                let stationFrameName = stationAnimationAtlasName + "\(currentAnimation > 9 ? currentAnimation.description : "0" + currentAnimation.description)"
                stationAnimationFrames!.append(stationAtlas.textureNamed(stationFrameName))
            }
            
            stationAnimationNode = TappableSpriteNode(texture: stationAnimationFrames[0])
            (stationAnimationNode as! TappableSpriteNode).delegate = self
//            self.spriteNode.addChild(stationAnimationNode!)
            
            spriteNode.scene!.addChild(stationAnimationNode!)
            
            stationAnimationNode?.setScale(stationAnimationScale)
            
            stationAnimationNode!.position = spriteNode.position + stationAnimationOffset
            stationAnimationNode!.zPosition = spriteNode.zPosition + 1
        }
    }
    
    override func playAnimation() {
        super.playAnimation()
        SFXPlayer.shared.hatch.play()
        SFXPlayer.shared.airSuction.play()
    }
    
    override func stopAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            super.stopAnimation()
            SFXPlayer.shared.airSuction.stop()
            self.stationAnimationNode?.size = CGSize(width: 792*self.stationAnimationScale, height: 668*self.stationAnimationScale)
        }
    }
}
