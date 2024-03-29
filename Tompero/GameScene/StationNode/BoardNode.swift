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
    
    override var stationAnimationDuration: Double {
        0
    }
    
    override var stationAnimationScale: CGFloat {
        .zero
    }
    
    override var stationAnimationRepeats: Bool {
        false
    }
    
    init() {
        super.init(stationType: .board)
        
        let tappableNode = TappableSpriteNode(imageNamed: stationType.rawValue + ".png")
        self.spriteNode = tappableNode
        tappableNode.delegate = self
        
        let progressBarNode = ProgressBar(color: .green, size: CGSize(width: tappableNode.size.width * 0.5, height: 18))
        self.spriteNode.addChild(progressBarNode)
        progressBarNode.zPosition = 20
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
            
            ingredientNode?.spriteNode.run(.sequence([
                .scale(to: 0.9, duration: 0.05),
                .scale(to: 1, duration: 0.2, delay: 0, usingSpringWithDamping: 0.1, initialSpringVelocity: 0.1)
            ]))
            
            progressBarNode?.progress = CGFloat(choppableComponent.chopProgress / choppableComponent.chopCap)
            
            if choppableComponent.complete {
                if (ingredient.states[ingredient.currentState] ?? []).contains(IngredientState.chopped) {
                    ingredient.currentState = .chopped
                }
                progressBarNode?.alpha = 0
            }
        } else {
            progressBarNode?.alpha = 0
        }
    }
    
}
