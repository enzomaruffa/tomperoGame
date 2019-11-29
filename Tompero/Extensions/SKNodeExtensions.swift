//
//  SKNodeExtensions.swift
//  YingPong
//
//  Created by Enzo Maruffa Moreira on 25/06/19.
//  Copyright © 2019 Enzo Maruffa Moreira. All rights reserved.
//

import SpriteKit

extension SKNode {
    
    func addChildren(nodes: [SKNode]) {
        for node in nodes {
            self.addChild(node)
        }
    }
    
    var rootNode: SKNode? {
        if let parentNode = self.parent {
            if parentNode is SKScene {
                return parentNode
            } else {
                return parentNode.rootNode
            }
        } else {
            return nil
        }
    }
    
    var positionInScene:CGPoint? {
        if let scene = scene, let parent = parent {
            return parent.convert(position, to:scene)
        } else {
            return nil
        }
    }
    
//    convenience init(texture: SKTexture, glowRadius: CGFloat) {
//        self.init(texture: texture, color: .clear, size: texture.size())
//        
//        let glow: SKEffectNode = {
//            let glow = SKEffectNode()
//            glow.addChild(SKSpriteNode(texture: texture))
//            glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": glowRadius])
//            glow.shouldRasterize = true
//            return glow
//        }()
//        
//        let glowRoot: SKNode = {
//            let node = SKNode()
//            node.name = "Glow"
//            node.zPosition = -1
//            return node
//        }()
//        
//        glowRoot.addChild(glow)
//        addChild(glowRoot)
//    }
}
