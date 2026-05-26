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

    /// Set by `MatchSceneBuilder` immediately after construction. Lets
    /// PlateNode / IngredientNode reach the scene for pipe routing +
    /// delivery without force-casting `parent as! GameScene`.
    weak var routing: MatchSceneRouting?

    var isEmpty: Bool {
        ingredientNode == nil && plateNode == nil
    }

    private var dropHighlightNode: SKShapeNode?
    private static let dropHighlightKey = "dropHighlightPulse"

    /// Glowing outline shown while a draggable item hovers over this station
    /// as the valid drop target. Purely cosmetic.
    func setHighlighted(_ highlighted: Bool) {
        if highlighted {
            guard dropHighlightNode == nil else { return }
            let s = spriteNode.size
            let glow = SKShapeNode(
                rectOf: CGSize(width: max(s.width, 120) * 0.92, height: max(s.height, 120) * 0.92),
                cornerRadius: 24
            )
            glow.strokeColor = SKColor(red: 0.45, green: 1.0, blue: 0.65, alpha: 0.95)
            glow.lineWidth = 14
            glow.glowWidth = 6
            glow.fillColor = SKColor(red: 0.45, green: 1.0, blue: 0.65, alpha: 0.12)
            glow.zPosition = 40
            spriteNode.addChild(glow)
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.35),
                SKAction.scale(to: 1.0, duration: 0.35)
            ])
            glow.run(.repeatForever(pulse), withKey: StationNode.dropHighlightKey)
            dropHighlightNode = glow
        } else {
            dropHighlightNode?.removeFromParent()
            dropHighlightNode = nil
        }
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
            updateIdleBob()
        }
    }

    var plateNode: PlateNode? {
        didSet {
            plateNode?.spriteNode.setScale(plateNodeScale)
            updateIdleBob()
        }
    }

    /// Opt-in subtle bob applied to the station sprite when `isEmpty`.
    /// Subclasses (box-type stations) flip this true in init.
    var idleBobEnabled: Bool = false {
        didSet { updateIdleBob() }
    }

    private static let idleBobKey = "stationIdleBob"

    func updateIdleBob() {
        guard idleBobEnabled, isEmpty else {
            spriteNode.removeAction(forKey: StationNode.idleBobKey)
            return
        }
        guard spriteNode.action(forKey: StationNode.idleBobKey) == nil else { return }
        let up = SKAction.moveBy(x: 0, y: 6, duration: 1.2)
        up.timingMode = .easeInEaseOut
        let down = SKAction.moveBy(x: 0, y: -6, duration: 1.2)
        down.timingMode = .easeInEaseOut
        let cycle = SKAction.sequence([up, down])
        spriteNode.run(SKAction.repeatForever(cycle), withKey: StationNode.idleBobKey)
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
