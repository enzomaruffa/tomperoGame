//
//  IngredientNode.swift
//  Tompero
//
//  Created by Vinícius Binder on 29/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

final class IngredientNode: TappableDelegate, MovableDelegate {
    
    // MARK: - Variables
    var currentStation: StationNode
    var ingredient: Ingredient
    var spriteNode: SKSpriteNode
    
    var rotationTimer: Timer?
    
    var scaleBeforeMove: CGFloat = 1
    var alphaBeforeMove: CGFloat = 1
    var zPosBeforeMove: CGFloat = 10
    
    var moving = false
    
    static let baseZPos = CGFloat(8)
    
    // MARK: - Initializers
    init(ingredient: Ingredient, movableNode: MovableSpriteNode, currentLocation: StationNode) {
        self.ingredient = ingredient
        self.currentStation = currentLocation
        
        spriteNode = movableNode
        
        movableNode.position = currentLocation.spriteNode.position
        movableNode.tapDelegate = self
        movableNode.moveDelegate = self
        movableNode.zPosition = IngredientNode.baseZPos
        
        currentStation.ingredientNode = self
    }
    
    // MARK: - Methods
    private func hideSpriteNode(completion block: @escaping () -> Void) {
        // We use a very low alpha value otherwise its interaction is disabled
        self.spriteNode.run(SKAction.fadeAlpha(to: 0.0001, duration: 0.05), completion: block)
    }
    
    private func showSpriteNode() {
        self.spriteNode.alpha = 1
    }
    
    private func sendSpriteNode(to type: StationType) {
        let duration = TimeInterval.random(in: 2...7)
        let vector = CGVector.randomVector(totalLength: CGFloat(duration * 150))
        
        let scale = SKAction.scale(to: 0.3, duration: 0.15)
        scale.timingMode = .easeIn
        
        self.spriteNode.run(
            .sequence([
                .scale(to: 0.8, duration: 0.05, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.1),
                scale,
                .run {
                    if type == .pipe {
                        self.spriteNode.removeFromParent()
                        return
                    } else if type == .hatch {
                        self.spriteNode.zPosition = -10
                    }
                    },
                .group([
                    .move(by: vector, duration: duration),
                    .fadeOut(withDuration: duration),
                    .scale(to: 0, duration: duration),
                    .rotate(byAngle: CGFloat.random(in: CGFloat.pi...4*CGFloat.pi), duration: duration)
                ])
            ])
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.2) {
            self.spriteNode.removeFromParent()
        }
    }
    
    func addIngredientTo(_ plateNode: PlateNode) {
        plateNode.plate.ingredients.append(self.ingredient)
        plateNode.updateTexture()
        
        //TODO: Remove ingredient node from scene destroy it whatever
        self.spriteNode.removeFromParent()
    }
    
    func removeFromPreviousStation() {
        currentStation.ingredientNode = nil
    }
    
    private func setIngredientIn(_ station: StationNode) {
        removeFromPreviousStation()
        
        // Check plate in station
        if let plateNode = station.plateNode {
            addIngredientTo(plateNode)
            plateNode.updateTexture()
        } else {
            currentStation = station
            currentStation.ingredientNode = self
        }
        
        if station.stationType == .shelf {
            spriteNode.zPosition = IngredientNode.baseZPos * 2
        } else {
            spriteNode.zPosition = IngredientNode.baseZPos
        }
        
    }
    
    // MARK: - MovableDelegate
    
    func attemptMove(to station: StationNode) -> Bool {
        
        print("Attempting move \(ingredient.texturePrefix) to \(station.stationType)")
        
        switch station.stationType {
        case .board:
            let canMove = station.ingredientNode?.ingredient == nil && ingredient.attemptChangeState(to: .chopping)
            if canMove {
                showSpriteNode()
                setIngredientIn(station)
            }
            print("Result: \(canMove)")
            return canMove
            
        case .stove:
            let canMove = station.ingredientNode?.ingredient == nil && ingredient.attemptChangeState(to: .cooking)
            if canMove {
                spriteNode.run(.scale(to: 0, duration: 0.2)) {
                    self.hideSpriteNode(completion: {
                        self.spriteNode.setScale(1)
                    })
                }
                setIngredientIn(station)
            }
            print("Result: \(canMove)")
            return canMove
            
        case .fryer:
            let canMove = station.ingredientNode?.ingredient == nil && ingredient.attemptChangeState(to: .frying)
            if canMove {
                spriteNode.run(.scale(to: 0, duration: 0.2)) {
                    self.hideSpriteNode(completion: {
                        self.spriteNode.setScale(1)
                    })
                }
                setIngredientIn(station)
            }
            print("Result: \(canMove)")
            return canMove
            
        case .shelf:
            let canMove = station.ingredientNode?.ingredient == nil && ((station.plateNode != nil && ingredient.currentState == ingredient.finalState) || station.plateNode == nil)
            if canMove {
                showSpriteNode()
                setIngredientIn(station)
            }
            
            print("Result: \(canMove)")
            return canMove
            
        case .pipe:
            var playerToSendTo: String = ""
            let scene = station.spriteNode.parent as! GameScene
            switch station.spriteNode.name {
            case "pipe1": playerToSendTo = scene.players[0]
            case "pipe2": playerToSendTo = scene.players[1]
            case "pipe3": playerToSendTo = scene.players[2]
            default: return false
            }
            
            GameConnectionManager.shared.send(ingredient: self.ingredient, to: playerToSendTo)

            removeFromPreviousStation()
            sendSpriteNode(to: .pipe)
            return true
            
        case .hatch:
            removeFromPreviousStation()
            sendSpriteNode(to: .hatch)
            return true
            
        case .plateBox:
            if ingredient.finalState == ingredient.currentState, let plateNode = station.plateNode {
                
                removeFromPreviousStation()
                addIngredientTo(plateNode)
                return true
            }
            return false
            
        default:
            return false
        }
    }
    
    func moveStarted(currentPosition: CGPoint) {
        scaleBeforeMove = spriteNode.yScale
        alphaBeforeMove = spriteNode.alpha
        
    }
    
    func moving(currentPosition: CGPoint) {
        if currentPosition.distanceTo(currentStation.spriteNode.position) > 80 && rotationTimer == nil {
            
            SFXPlayer.shared.takeFood.play()
            moving = true
            zPosBeforeMove = spriteNode.zPosition
            spriteNode.zPosition = 90
            
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
        spriteNode.removeAllActions()
        rotationTimer?.invalidate()
        rotationTimer = nil
        
        moving = false
    }
    
    func moveCancel(currentPosition: CGPoint) {
        print("Move cancelled")
        spriteNode.setScale(scaleBeforeMove)
        spriteNode.alpha = alphaBeforeMove
        spriteNode.zPosition = zPosBeforeMove
    }
    
    // MARK: - TappableDelegate
    func tap() {
        print("Ingredient tapped")
        
        // animation
        if currentStation.stationType == .board {
            spriteNode.run(.sequence([
                .scale(to: 0.9, duration: 0.05),
                .scale(to: 1, duration: 0.2, delay: 0, usingSpringWithDamping: 0.1, initialSpringVelocity: 0.1)
            ]))
        }
        
        currentStation.tap()
        checkTextureChange()
    }
    
    func checkTextureChange() {
        if ingredient.textureName != spriteNode.texture?.name {
            spriteNode.texture = SKTexture(imageNamed: ingredient.textureName)
        }
    }
    
}

extension SKTexture {
    var name: String? {
        let comps = description.components(separatedBy: "'")
        return comps.count > 1 ? comps[1] : nil
    }
}
