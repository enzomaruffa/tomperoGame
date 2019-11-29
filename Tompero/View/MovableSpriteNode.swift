//
//  MovableSpriteNode.swift
//  Tompero
//
//  Created by Vinícius Binder on 29/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class MovableSpriteNode: SKSpriteNode {
    
    override var isUserInteractionEnabled: Bool {
        get {
            return true
        }
        set {
            // ignore
        }
    }
    
    var lastValidLocation: SKSpriteNode?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
//        let stations = scene?.children.filter({ (node as? Player) -> Bool in
//            (scene as! GameScene).tables?.contains(node)
//        })
//
//        scene?.children.forEach({ (node) in
//            node.intersects(self)
//        })
        
        //lastValidPosition = self.position
        // resize sprite
        // change zPos
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        self.position = touch.location(in: scene!)
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        //if touch.location(in: self.parent as! GameScene) ==
        // resize sprite
        // change zPos
    }
    
}
