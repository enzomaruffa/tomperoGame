//
//  StoveNode.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 15/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class StoveNode: StationNode {
    
    override var spriteYPos: CGFloat {
        -226.5
    }
    
    override var ingredientNode: IngredientNode? {
        didSet {
            ingredientNode?.spriteNode.setScale(ingredientNodeScale)
            
            if ingredientNode != nil {
                progressBarNode?.alpha = 1
            } else {
                progressBarNode?.alpha = 0
            }
            
            if indicatorNode == nil {
                indicatorNode = SKSpriteNode(imageNamed: "IngredientIndicator")
                spriteNode.addChild(indicatorNode!)
                indicatorNode!.zPosition = 5
                indicatorNode!.scale(to: CGSize(width: 170, height: 170))
                indicatorNode!.position = CGPoint(x: 240, y: 150)
            }
            
            if let ingredient = ingredientNode?.ingredient {
                let iconNode = SKSpriteNode(imageNamed: ingredient.texturePrefix + "Raw")
                iconNode.zPosition = 6
                iconNode.scale(to: CGSize(width: 100, height: 100))
                indicatorNode?.addChild(iconNode)
            } else {
                indicatorNode?.removeAllChildren()
            }
        }
    }
    
    override var progressBarNodeOffset: CGPoint {
        CGPoint(x: 0, y: 220)
    }
    
    override var stationAnimationAtlasName: String? {
        "Cook"
    }
    
    override var stationAnimationDuration: Double {
        2
    }
    
    init() {
        super.init(stationType: .stove)
        
        let tappableNode = TappableSpriteNode(imageNamed: stationType.rawValue + ".png")
        self.spriteNode = tappableNode
        tappableNode.delegate = self
        
        let progressBarNode = ProgressBar(color: .green, size: CGSize(width: tappableNode.size.width * 0.5, height: 18))
        self.spriteNode.addChild(progressBarNode)
        progressBarNode.zPosition = 8
        progressBarNode.position = progressBarNodeOffset
        
        self.progressBarNode = progressBarNode
        progressBarNode.alpha = 0
    }

    override func update() {
        
        if !(ingredientNode?.moving ?? true),
            let ingredient = ingredientNode?.ingredient,
            let cookableComponent = ingredient.cookableComponent {
            
            cookableComponent.update()
            
            if !animationRunning {
                playAnimation()
            }

            progressBarNode?.alpha = 1
            
            if cookableComponent.burnt {
                if ingredient.states[ingredient.currentState]!.contains(IngredientState.burnt) {
                    ingredient.currentState = .burnt
                    ingredientNode?.checkTextureChange()
                }
            } else if cookableComponent.complete {
                progressBarNode?.progress = CGFloat(cookableComponent.cookProgress / cookableComponent.burnCap)
                progressBarNode?.bar?.color = .red
                
                if ingredient.states[ingredient.currentState]!.contains(IngredientState.cooked) {
                    ingredient.currentState = .cooked
                    ingredientNode?.checkTextureChange()
                }
            } else {
                progressBarNode?.bar?.color = .green
                progressBarNode?.progress = CGFloat(cookableComponent.cookProgress / cookableComponent.cookCap)
            }
            
        } else { //Stops only on these stations
            if animationRunning {
                stopAnimation()
                progressBarNode?.alpha = 0
            }
        }
    }
    
    override func playAnimation() {
        SFXPlayer.shared.cooking.play()
        super.playAnimation()
    }
    override func stopAnimation() {
        SFXPlayer.shared.cooking.stop()
        super.stopAnimation()
    }
    
}
