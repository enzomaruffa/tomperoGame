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
    
    var lastValidLocation: StationNode?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else { return }
        
        let gameScene = scene as! GameScene
        for station in gameScene.stations {
            if self.intersects(station.spriteNode) {
                lastValidLocation = station
                print(lastValidLocation!)
            }
        }
        
        //lastValidPosition = self.position
        
        self.zPosition = 4
        // resize sprite
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // calculate offset
        self.position = touch.location(in: scene!)
        
        // show indicator nodes for placeable spaces
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let gameScene = scene as! GameScene
        for station in gameScene.stations {
            print("cu")
            if station.spriteNode.contains(touch.location(in: gameScene)) {
                print("oi")
                self.position = station.spriteNode.position
                // attempt move
                // resize sprite
                return
            }
        }
        
        self.position = lastValidLocation!.spriteNode.position
        
    }
    
}
