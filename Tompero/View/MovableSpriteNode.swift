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
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isUserInteractionEnabled = true
    }
    
    var initialTouchPosition: CGPoint?
    weak var tapDelegate: TappableDelegate?
    weak var moveDelegate: MovableDelegate?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else { return }
        let touch = touches.first!
        
        moveDelegate?.moveStarted(currentPosition: touch.location(in: scene!))
        
        if scene != nil {
            self.zPosition = 4
        }
        
        initialTouchPosition = touch.location(in: scene!)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        moveDelegate?.moving(currentPosition: touch.location(in: scene!))
        
        // calculate offset
        self.position = touch.location(in: scene!)
        
        // TODO: how indicator nodes for placeable spaces
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        moveDelegate?.moveEnded(currentPosition: touch.location(in: scene!))
        
        if let initialTouchPosition = self.initialTouchPosition {
            let finalTouchPosition = touch.location(in: scene!)
            let distanceToOrigin = initialTouchPosition.distanceTo(finalTouchPosition)
            if distanceToOrigin < 80 {
                tapDelegate?.tap()
            }
        }
        
        if let gameScene = scene as? GameScene {
            for station in gameScene.stations {
                if station.spriteNode.contains(touch.location(in: gameScene)) && (moveDelegate?.attemptMove(to: station) ?? false) {
                    self.position = station.spriteNode.position
                    print("Success!")
                    return
                }
            }

            print("Returning to previous position...")
            self.position = (moveDelegate?.currentStation.spriteNode.position)!
        }
    }
}
