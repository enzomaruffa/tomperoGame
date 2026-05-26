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
    
    // MARK: - Variables
    var initialTouchPosition: CGPoint?
    weak var tapDelegate: TappableDelegate?
    weak var moveDelegate: MovableDelegate?
    
    var previousPosition: CGPoint?
    
    // MARK: - Initializers
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isUserInteractionEnabled = true
    }
    
    // MARK: - Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else { return }
        
        let touch = touches.first!
        
        moveDelegate?.moveStarted(currentPosition: touch.location(in: scene!))
        
        initialTouchPosition = touch.location(in: scene!)
        previousPosition = self.position
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        if let initialTouchPosition = self.initialTouchPosition {
            let finalTouchPosition = touch.location(in: scene!)
            let distanceToOrigin = initialTouchPosition.distanceTo(finalTouchPosition)
            if distanceToOrigin >= MovableSpriteNode.dragThreshold {
                moveDelegate?.moving(currentPosition: touch.location(in: scene!))
                // Lift the dragged item above the fingertip so it isn't hidden
                // under the finger — makes aiming at a station much easier.
                self.position = finalTouchPosition + CGPoint(x: 0, y: MovableSpriteNode.dragLift)
            }
        }
    }

    /// Movement (in scene units, 2436-wide canvas) before a touch counts as a
    /// drag rather than a tap. Lower = easier to start dragging.
    static let dragThreshold: CGFloat = 50
    /// How far above the fingertip the dragged item floats while moving.
    static let dragLift: CGFloat = 120
    
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
            // Drop point is where the *item* visually sits (fingertip + lift),
            // so "what you see is what you drop". Prefer a station whose frame
            // contains the item; otherwise the nearest station within a
            // forgiving radius — the old fingertip-exact test made dropping
            // (tentacles especially) frustrating.
            let dropPoint = self.position
            let stations = gameScene.stations.sorted {
                $0.spriteNode.position.distanceTo(dropPoint) < $1.spriteNode.position.distanceTo(dropPoint)
            }
            for station in stations {
                let frame = station.spriteNode.frame
                let radius = max(frame.width, frame.height) * 0.85
                let withinReach = frame.contains(dropPoint)
                    || station.spriteNode.position.distanceTo(dropPoint) <= radius
                guard withinReach else { continue }
                if moveDelegate?.attemptMove(to: station) ?? false {
                    SFXPlayer.shared.putFoodDown.play()
                    Haptics.place()
                    self.run(.group([
                        .move(to: station.spriteNode.position, duration: 0.1),
                        .rotate(toAngle: 0, duration: 0.1)
                    ]))
                    return
                }
            }

            moveDelegate?.moveCancel(currentPosition: touch.location(in: scene!))
            self.position = previousPosition!
            self.zRotation = 0
            previousPosition = .zero
        }
    }
}
