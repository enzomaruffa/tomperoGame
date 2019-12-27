//
//  StationNode.swift
//  Tompero
//
//  Created by Vinícius Binder on 29/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class StationNode: TappableDelegate {
    
    var stationType: StationType
    internal var ingredient: Ingredient?
    
    var isEmpty: Bool {
        ingredientNode == nil && plateNode == nil
    }
    
    var spriteNode: SKSpriteNode
    
    // default to 0
    var spriteYPos: CGFloat {
        0
    }
    
    // set to default 1
    var ingredientNodeScale: CGFloat {
        1
    }
    
    // set to deafult  1
    var plateNodeScale: CGFloat {
        1
    }
    
    var indicatorNode: SKSpriteNode?
    
    var ingredientNode: IngredientNode? {
        didSet {
            ingredientNode?.spriteNode.setScale(ingredientNodeScale)
        }
    }
    
    var plateNode: PlateNode? {
        didSet {
            plateNode?.spriteNode.setScale(plateNodeScale)
        }
    }
    
    var progressBarNode: ProgressBar?
    
    // default to zero
    var progressBarNodeOffset: CGPoint {
        .zero
    }
    
    // default to nil
    var stationAnimationAtlasName: String? {
        nil
    }
    
    // default to zero
    var stationAnimationDuration: Double {
        0
    }
    
    // set to default 0 0
    var stationAnimationOffset: CGPoint {
        .zero
    }
    
    // set to default 1
    var stationAnimationScale: CGFloat {
        1
    }
    
    // set to default true
    var stationAnimationRepeats: Bool {
        true
    }
    
    var stationAnimationResize: Bool {
        true
    }
    
    var stationAnimationNode: SKSpriteNode?
    var stationAnimationFrames: [SKTexture]!
    var animationRunning = false
    
    func createAnimation() {
        if let stationAnimationAtlasName = stationAnimationAtlasName {
            let stationAtlas = SKTextureAtlas(named: stationAnimationAtlasName)
            stationAnimationFrames = []

            for currentAnimation in 0..<stationAtlas.textureNames.count {
                let stationFrameName = stationAnimationAtlasName + "\(currentAnimation > 9 ? currentAnimation.description : "0" + currentAnimation.description)"
                stationAnimationFrames!.append(stationAtlas.textureNamed(stationFrameName))
            }
            
            stationAnimationNode = TappableSpriteNode(texture: stationAnimationFrames[0])
            (stationAnimationNode as! TappableSpriteNode).delegate = self
            self.spriteNode.addChild(stationAnimationNode!)
            
            stationAnimationNode?.setScale(stationAnimationScale)
            
            stationAnimationNode!.position = stationAnimationOffset
            stationAnimationNode!.zPosition = 4
        }
    }
    
    internal init(stationType: StationType) {
        self.stationType = stationType
        self.spriteNode = SKSpriteNode()
    }
    
    // Tap interaction
    // Default to empty
    func tap() { }
    
    // Default to empty
    func update() { }
    
    func playAnimation() {
        // ===
        if let node = self.stationAnimationNode {

            animationRunning = true
            let timePerFrame = TimeInterval(stationAnimationDuration) / TimeInterval(stationAnimationFrames.count)
            var animationAction = SKAction.animate(
                                    with: stationAnimationFrames,
                                    timePerFrame: timePerFrame,
                                    resize: stationAnimationResize,
                                    restore: true
            )
            
            if stationAnimationRepeats {
                animationAction = SKAction.repeatForever(animationAction)
            }

            node.run(animationAction)
        }
    }
    
    func stopAnimation() {
        animationRunning = false
        stationAnimationNode?.removeAllActions()
    }
}
