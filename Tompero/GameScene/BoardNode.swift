//
//  BoardNode.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 12/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import SpriteKit

class BoardNode: StationNode {
    
    override var spriteYPos: CGFloat {
        -237.5
    }
    
    override var ingredientNodeScale: CGFloat {
        1
    }
    
    override var ingredientNode: IngredientNode? {
        didSet {
            ingredientNode?.spriteNode.setScale(ingredientNodeScale)
            
            if ingredientNode != nil {
                progressBarNode?.alpha = 1
            } else {
                progressBarNode?.alpha = 0
            }
            
            if let component = ingredientNode?.ingredient.choppableComponent {
                progressBarNode?.progress = CGFloat(component.chopProgress / component.chopCap)
            }
        }
    }
    
    override var progressBarNodeOffset: CGPoint {
        CGPoint(x: 0, y: -180)
    }
    
    override var stationAnimationAtlasName: String? {
        nil
    }
    
    override var stationAnimationDuration: Double {
        0
    }
    
    override var stationAnimationOffset: CGPoint {
        .zero
    }
    
    override var stationAnimationScale: CGFloat {
        .zero
    }
    
    override var stationAnimationRepeats: Bool {
        false
    }
    
    init() {
        super.init(stationType: .board, spriteNode: nil, ingredient: nil)
        
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
    
    // Tap interaction
    override func tap() {
        if let ingredient = ingredientNode?.ingredient,
            let choppableComponent = ingredient.choppableComponent {
            choppableComponent.update()
            SFXPlayer.shared.chop.play()
            
            playAnimation()
            
            progressBarNode?.progress = CGFloat(choppableComponent.chopProgress / choppableComponent.chopCap)
            
            if choppableComponent.complete {
                if (ingredient.states[ingredient.currentState] ?? []).contains(IngredientState.chopped) {
                    ingredient.currentState = .chopped
                }
                progressBarNode?.alpha = 0
            }
        }
    }

    override func playAnimation() {}
    override func stopAnimation() {}
    
}
