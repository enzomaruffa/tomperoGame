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
    let ingredient: Ingredient?
    
    var isEmpty: Bool {
        ingredientNode == nil && plateNode == nil
    }
    
    var spriteNode: SKSpriteNode
    var spriteYPos: CGFloat {
        switch stationType {
        case .board: return -237.5
        case .stove: return -226.5
        case .fryer: return -342.0
        case .ingredientBox: return -361.0 // not final
        case .plateBox: return -361.0 // not final
        default: return 0
        }
    }
    
    var ingredientNodeScale: CGFloat {
        switch stationType {
        case .board: return 1
        case .stove: return 1
        case .fryer: return 1
        case .ingredientBox: return 1
        case .plateBox: return 1
        case .shelf: return 0.7
        case .delivery: return 0.7
        case .pipe: return 0.5
        case .hatch: return 0.5
        case .empty: return 1
        }
    }
    
    var plateNodeScale: CGFloat {
        switch stationType {
        case .board: return 1
        case .stove: return 1
        case .fryer: return 1
        case .ingredientBox: return 1
        case .plateBox: return 1
        case .shelf: return 0.6
        case .delivery: return 0.45
        case .pipe: return 0.5
        case .hatch: return 0.5
        case .empty: return 1
        }
    }
    
    var indicatorNode: SKSpriteNode?
    
    var ingredientNode: IngredientNode? {
        didSet {
            ingredientNode?.spriteNode.setScale(ingredientNodeScale)
            
            if ingredientNode != nil {
                progressBarNode?.alpha = 1
            } else {
                progressBarNode?.alpha = 0
            }
            
            if stationType == .stove || stationType == .fryer {
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
            
            if stationType == .board, let component = ingredientNode?.ingredient.choppableComponent {
                progressBarNode?.progress = CGFloat(component.chopProgress / component.chopCap)
            }
        }
    }
    
    var plateNode: PlateNode? {
        didSet {
            plateNode?.spriteNode.setScale(plateNodeScale)
        }
    }
    
    var progressBarNode: ProgressBar?
    
    var progressBarNodeOffset: CGPoint {
        switch stationType {
        case .stove: return CGPoint(x: 0, y: -220)
        case .fryer: return CGPoint(x: 0, y: -200)
        case .board: return CGPoint(x: 0, y: -180)
        default: return .zero
        }
    }
    
    var stationAnimationAtlasName: String? {
        switch stationType {
        case .stove: return "Cook"
        case .fryer: return "Fry"
        case .pipe: return "PipeVacuum"
        case .hatch: return "HatchVacuum"
        default: return nil
        }
    }
    
    var stationAnimationDuration: Double {
        switch stationType {
        case .stove: return 2
        case .fryer: return 2
        case .pipe: return 0.3
        case .hatch: return 0.8
        default: return 0
        }
    }
    
    var stationAnimationOffset: CGPoint {
        switch stationType {
        case .stove: return CGPoint(x: 0, y: 0)
        case .fryer: return CGPoint(x: 0, y: 68)
        case .pipe: return CGPoint(x: 3.5, y: 0)
        case .hatch: return CGPoint(x: 48, y: 0)
        default: return .zero
        }
    }
    
    var stationAnimationScale: CGFloat {
        switch stationType {
        case .stove: return 1
        case .fryer: return 1
        case .pipe: return 0.05
        case .hatch: return 0.8
        default: return .zero
        }
    }
    
    var stationAnimationRepeats: Bool {
        switch stationType {
        case .board: return false
        default: return true
        }
    }
    
    var stationAnimationNode: SKSpriteNode?
    var stationAnimationFrames: [SKTexture]!
    var animationRunning = false
    
    func createAnimation(stationType: StationType) {
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
            stationAnimationNode!.zPosition = 3
        }
    }
    
    internal init(stationType: StationType, spriteNode: SKSpriteNode?, ingredient: Ingredient?) {
        self.stationType = stationType
        self.ingredient = ingredient
        
        // 
        if stationType == .ingredientBox {
            
            let tappableNode = TappableSpriteNode(imageNamed: ingredient!.texturePrefix + "Box.png")
            self.spriteNode = tappableNode
            tappableNode.delegate = self
            
        } else if stationType == .plateBox {
            
            let tappableNode = TappableSpriteNode(imageNamed: "PlateBox.png")
            self.spriteNode = tappableNode
            tappableNode.delegate = self
            
        } else if stationType == .shelf
                || stationType == .delivery
                || stationType == .pipe
                || stationType == .hatch {
            
            self.spriteNode = spriteNode!
            
        } else if stationType == .empty {
            
            let tappableNode = TappableSpriteNode()
            self.spriteNode = tappableNode
            tappableNode.delegate = self
            
        } else {
            
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
        
        createAnimation(stationType: stationType)
    }
    
    convenience init(stationType: StationType, spriteNode: SKSpriteNode) {
        self.init(stationType: stationType, spriteNode: spriteNode, ingredient: nil)
    }
    
    convenience init(stationType: StationType, ingredient: Ingredient?) {
        self.init(stationType: stationType, spriteNode: nil, ingredient: ingredient)
    }
    
    // Tap interaction
    func tap() {
        
        if stationType == .board,
            let ingredient = ingredientNode?.ingredient,
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
            
        } else if stationType == .ingredientBox && self.ingredientNode == nil {
            
            SFXPlayer.shared.takeFood.play()
            
            let newIngredient = ingredient!.findDowncast()
            
            let ingredientMovableNode = MovableSpriteNode(imageNamed: newIngredient.textureName)
            spriteNode.scene!.addChild(ingredientMovableNode)
            ingredientMovableNode.zPosition = 4
            
            let ingredientNode = IngredientNode(ingredient: newIngredient, movableNode: ingredientMovableNode, currentLocation: self)
            ingredientMovableNode.position = CGPoint(x: spriteNode.position.x, y: spriteNode.position.y + 85)
            
            self.ingredientNode = ingredientNode
            
        } else if stationType == .plateBox && self.plateNode == nil {
            
            let newPlate = Plate()
            let plateMovableNode = MovableSpriteNode(imageNamed: newPlate.textureName)
            spriteNode.scene!.addChild(plateMovableNode)
            plateMovableNode.zPosition = 4
            
            let plateNode = PlateNode(plate: newPlate, movableNode: plateMovableNode, currentLocation: self)
            plateMovableNode.position = CGPoint(x: spriteNode.position.x, y: spriteNode.position.y + 85)
            
            self.plateNode = plateNode
        } else {
            progressBarNode?.alpha = 0
        }
    }
    
    // Scene update intercation
    func update() {
        
        if stationType == .stove && !(ingredientNode?.moving ?? true),
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
            
        } else if stationType == .fryer && !(ingredientNode?.moving ?? true),
            let ingredient = ingredientNode?.ingredient,
            let fryableComponent = ingredient.fryableComponent {
            
            fryableComponent.update()
            
            if !animationRunning {
                playAnimation()
            }

            progressBarNode?.alpha = 1
            progressBarNode?.progress = CGFloat(fryableComponent.fryProgress / fryableComponent.fryCap)
            
            if fryableComponent.burnt {
                if ingredient.states[ingredient.currentState]!.contains(IngredientState.burnt) {
                    ingredient.currentState = .burnt
                    ingredientNode?.checkTextureChange()
                }
            } else if fryableComponent.complete {
                if ingredient.states[ingredient.currentState]!.contains(IngredientState.fried) {
                    ingredient.currentState = .fried
                    ingredientNode?.checkTextureChange()
                }
            }
        } else if stationType == .stove || stationType == .fryer { //Stops only on these stations
            if animationRunning {
                stopAnimation()
                progressBarNode?.alpha = 0
            }
        }
    }
    
    func playAnimation() {
        switch stationType {
        case .stove: SFXPlayer.shared.cooking.play()
        case .fryer: SFXPlayer.shared.frying.play()
        case .hatch:
            SFXPlayer.shared.hatch.play()
            SFXPlayer.shared.airSuction.play()
        default: break
        }
        if let node = self.stationAnimationNode {

            animationRunning = true
            let timePerFrame = TimeInterval(stationAnimationDuration) / TimeInterval(stationAnimationFrames.count)
            var animationAction = SKAction.animate(
                                    with: stationAnimationFrames,
                                    timePerFrame: timePerFrame,
                                    resize: stationType == .hatch ? true : false,
                                    restore: true
            )
            
            if stationAnimationRepeats {
                animationAction = SKAction.repeatForever(animationAction)
            }

            node.run(animationAction)
        }
    }
    
    func stopAnimation() {
        switch stationType {
        case .stove: SFXPlayer.shared.cooking.stop()
        case .fryer: SFXPlayer.shared.frying.stop()
        case .hatch: SFXPlayer.shared.airSuction.stop()
        default: break
        }
        
        if stationType == .hatch {
            stationAnimationNode?.size = CGSize(width: 792*0.8, height: 668*0.8)
        }
        
        animationRunning = false
        stationAnimationNode?.removeAllActions()
    }
}
