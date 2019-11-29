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
    
    var lastValidLocation: PlayerTable?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
//        let gameScene = scene as! GameScene
//        for station in gameScene.tables {
//            if self.intersects(station.spriteNode) {
//                
//            }
//        }
        
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
