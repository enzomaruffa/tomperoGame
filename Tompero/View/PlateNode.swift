//
//  PlateNode.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 05/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class PlateNode: MovableDelegate {
    
    var currentStation: StationNode
    var plate: Plate
    var spriteNode: SKSpriteNode
    
    var rotationTimer: Timer?
    
    var scaleBeforeMove: CGFloat = 1
    var alphaBeforeMove: CGFloat = 1
    
    init(plate: Plate, movableNode: MovableSpriteNode, currentLocation: StationNode) {
        self.plate = plate
        self.currentStation = currentLocation
        currentStation.plate = self.plate
        
        spriteNode = movableNode
        
        movableNode.position = currentLocation.spriteNode.position
        movableNode.moveDelegate = self
    }
    
    private func hideSpriteNode() {
        // We use a very low alpha value otherwise its interaction is disabled
        self.spriteNode.run(SKAction.fadeAlpha(to: 0.0001, duration: 0.05))
    }
    
    private func showSpriteNode() {
        self.spriteNode.alpha = 1
    }
    
    private func implodeSpriteNode() {
        
    }
    
    private func setPlateIn(_ station: StationNode) {
        currentStation.plate = nil

        // Check if ingredient exists in station
        
        
        currentStation = station
        currentStation.plate = self.plate
    }
    
    // MARK: - MovableDelegate
    func attemptMove(to station: StationNode) -> Bool {
        
        print("Attempting move to \(station.stationType)")
        
        switch station.stationType {
        case .board:
            return false
            
        case .stove:
            return false
            
        case .fryer:
            return false
            
        case .shelf:
            let canMove = station.plate == nil && ((station.ingredient != nil && station.ingredient?.currentState == station.ingredient?.finalState) || station.ingredient == nil)
            if canMove {
                showSpriteNode()
                setPlateIn(station)
                spriteNode.setScale(0.4)
            }
            print("Result: \(canMove)")
            return canMove
            
        case .pipe:
            // check if plate
            
            var playerToSendTo: String = ""
            let scene = station.spriteNode.parent as! GameScene
            switch station.spriteNode.name {
            case "pipe1": playerToSendTo = scene.players[0]
            case "pipe2": playerToSendTo = scene.players[1]
            case "pipe3": playerToSendTo = scene.players[2]
            default: return false
            }
            
            GameConnectionManager.shared.send(plate: self.plate, to: playerToSendTo)
            print(playerToSendTo)
            implodeSpriteNode()
            return true
            
        case .hatch:
            implodeSpriteNode()
            return true
            
        default:
            return true
        }
    }
    
    func moveStarted(currentPosition: CGPoint) {
        scaleBeforeMove = spriteNode.yScale
        alphaBeforeMove = spriteNode.alpha
    }
    
    func moving(currentPosition: CGPoint) {
        if currentPosition.distanceTo(currentStation.spriteNode.position) > 80 && rotationTimer == nil {
            
            self.spriteNode.run(SKAction.scale(to: 0.7, duration: 0.2))
            self.spriteNode.alpha = 1
            
            let duration = 0.2
            
            let minRotation = CGFloat(-0.3)
            let maxRotation = CGFloat(+0.3)
            spriteNode.run(SKAction.rotate(toAngle: minRotation - 0.1, duration: duration))
            
            rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true, block: { (_) in
                if self.spriteNode.zRotation >= maxRotation {
                    self.spriteNode.run(SKAction.rotate(toAngle: minRotation - 0.02, duration: duration))
                } else if self.spriteNode.zRotation <= minRotation {
                    self.spriteNode.run(SKAction.rotate(toAngle: maxRotation + 0.02, duration: duration))
                }
            })
        }
    }
    
    func moveEnded(currentPosition: CGPoint) {
        spriteNode.zRotation = 0
        spriteNode.removeAllActions()
        rotationTimer?.invalidate()
        rotationTimer = nil
    }
    
    func moveCancel(currentPosition: CGPoint) {
        print("Move cancelled")
        spriteNode.setScale(scaleBeforeMove)
        spriteNode.alpha = alphaBeforeMove
    }
    
}
