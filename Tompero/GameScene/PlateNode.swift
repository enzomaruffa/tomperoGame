//
//  PlateNode.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 05/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

final class PlateNode: MovableDelegate {
    
    // MARK: - Variables
    var currentStation: StationNode
    var plate: Plate
    var spriteNode: SKSpriteNode
    
    var rotationTimer: Timer?
    
    var scaleBeforeMove: CGFloat = 1
    var alphaBeforeMove: CGFloat = 1
    var zPosBeforeMove: CGFloat = 10
    
    var moving = false
    var successfulDelivery = false
    
    static let baseZPos: CGFloat = 3
    
    // MARK: - Initializers
    init(plate: Plate, movableNode: MovableSpriteNode, currentLocation: StationNode) {
        self.plate = plate
        self.currentStation = currentLocation
        
        spriteNode = movableNode
        
        currentStation.plateNode = self
        
        movableNode.position = currentLocation.spriteNode.position
        movableNode.moveDelegate = self
    }
    
    // MARK: - Methods
    private func hideSpriteNode() {
        // We use a very low alpha value otherwise its interaction is disabled
        self.spriteNode.run(SKAction.fadeAlpha(to: 0.0001, duration: 0.05))
    }
    
    private func showSpriteNode() {
        self.spriteNode.alpha = 1
    }
    
    private func implodeSpriteNode(withDuration duration: TimeInterval) {
        self.currentStation.plateNode = nil
        
        self.spriteNode.run(
            SKAction.sequence([
                .group([
                    SKAction.colorize(with: UIColor.white, colorBlendFactor: 1, duration: duration / 4),
                    SKAction.fadeOut(withDuration: duration)
                ]),
                .run {
                    if self.successfulDelivery {
                        SFXPlayer.shared.cashRegister.play()
                    } else {
                        // play fail sound
                    }
                }
            ])
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.spriteNode.removeFromParent()
        }
    }
    
    private func sendSpriteNode(to type: StationType) {
        self.currentStation.plateNode = nil
        
        for ingredient in self.plate.ingredients {
            ingredient.sprite.removeFromParent()
            ingredient.sprite.position = .zero
            spriteNode.addChild(ingredient.sprite)
        }
        
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
                        self.spriteNode.zPosition = -50
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
    
    private func setPlateIn(_ station: StationNode) {
        currentStation.plateNode = nil
        
        // Check if ingredient exists in station
        if let ingredientNode = station.ingredientNode {
            self.plate.ingredients.append(ingredientNode.ingredient)
            
            self.spriteNode.zPosition = PlateNode.baseZPos
            self.updateTexture()
            
            currentStation = station
            currentStation.plateNode = self
            
            currentStation.ingredientNode = nil
            //TODO: Remove ingredient node from scene destroy it whatever
            ingredientNode.spriteNode.removeFromParent()
        } else {
            self.spriteNode.zPosition = PlateNode.baseZPos
            self.updateTexture()
            
            currentStation = station
            currentStation.plateNode = self
        }
        
        if station.stationType == .shelf {
            self.spriteNode.zPosition = PlateNode.baseZPos + 10
            self.updateTexture()
        }
        
    }
    
    func updateTexture() {
        var zPos = self.spriteNode.zPosition + 1
        self.spriteNode.removeAllChildren()
        self.spriteNode.zPosition = zPos
        
        let breadList = [SpaceshipHull(), DevilMashedBread(), Asteroid()]
        var sortedIngredients = plate.ingredients.sorted(by: { $0.texturePrefix < $1.texturePrefix })
        
        sortedIngredients.forEach { print($0.texturePrefix, type(of: $0)) }
        
        if let firstBread = sortedIngredients.filter({ breadList.contains($0) }).first {
            sortedIngredients.removeAll(where: { $0 == firstBread })
            
            // Render bread bottom
            var newNode = SKSpriteNode(imageNamed: firstBread.texturePrefix + "Bottom")
            newNode.position = CGPoint(x: 0, y: 35)
            zPos += 1
            newNode.zPosition = zPos
            self.spriteNode.addChild(newNode)
            
            for (index, ingredient) in sortedIngredients.enumerated() {
                newNode = SKSpriteNode(imageNamed: ingredient.textureName)
                newNode.position = CGPoint(x: 0, y: 45 + index * 3)
                zPos += 1
                newNode.zPosition = zPos
                self.spriteNode.addChild(newNode)
            }
            
            // Render bread top
            newNode = SKSpriteNode(imageNamed: firstBread.texturePrefix + "Top")
            newNode.position = CGPoint(x: 0, y: 175 + sortedIngredients.count * 4)
            zPos += 1
            newNode.zPosition = zPos
            self.spriteNode.addChild(newNode)
            
        } else {
            // Render ingredients in plate
            var zPos = CGFloat(3)
            for (index, ingredient) in sortedIngredients.enumerated() {
                let newNode = SKSpriteNode(imageNamed: ingredient.textureName)
                newNode.position = CGPoint(x: 0, y: 30 + index * 3)
                zPos += 1
                newNode.zPosition = zPos
                self.spriteNode.addChild(newNode)
            }
        }
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
            let canMove =
                station.plateNode == nil &&
                    ((station.ingredientNode?.ingredient != nil && station.ingredientNode?.ingredient.currentState == station.ingredientNode?.ingredient.finalState)
                        || station.ingredientNode?.ingredient == nil)
            if canMove {
                showSpriteNode()
                setPlateIn(station)
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
            
            GameConnectionManager.shared.send(plate: self.plate, to: playerToSendTo)
        
            sendSpriteNode(to: .pipe)
            return true
            
        case .hatch:
            sendSpriteNode(to: .hatch)
            return true
            
        case .delivery:
            
            if let scene = spriteNode.scene as? GameScene {
                setPlateIn(station)
                
                print("Attempting plate delviery")
                successfulDelivery = scene.makeDelivery(plate: self.plate)
                
                implodeSpriteNode(withDuration: 1)
                
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
        moving = true
    }
    
    func moving(currentPosition: CGPoint) {
        if currentPosition.distanceTo(currentStation.spriteNode.position) > 80 && rotationTimer == nil {
            
            self.spriteNode.run(SKAction.scale(to: 0.7, duration: 0.2))
            self.spriteNode.alpha = 1
            
            zPosBeforeMove = spriteNode.zPosition
            spriteNode.zPosition = 30
            
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
         
        moving = false
    }
    
    func moveCancel(currentPosition: CGPoint) {
        print("Move cancelled")
        spriteNode.setScale(scaleBeforeMove)
        spriteNode.alpha = alphaBeforeMove
        spriteNode.zPosition = zPosBeforeMove
    }
    
}
