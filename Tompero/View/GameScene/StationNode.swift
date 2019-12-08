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
    private let ingredient: Ingredient?
    
    var isEmpty: Bool {
        ingredientNode == nil && plateNode == nil
    }
    
    var spriteNode: SKSpriteNode
    var spriteYPos: CGFloat {
        switch stationType {
        case .board: return -237.5
        case .stove: return -348.5
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
    
    var ingredientNode: IngredientNode? {
        didSet {
            ingredientNode?.spriteNode.setScale(ingredientNodeScale)
            
            if stationType == .stove || stationType == .fryer {
                var indicatorNode = spriteNode.children.first as? SKSpriteNode
                if indicatorNode == nil {
                    indicatorNode = SKSpriteNode(imageNamed: "IngredientIndicator")
                    spriteNode.addChild(indicatorNode!)
                    indicatorNode!.zPosition = 5
                    indicatorNode!.scale(to: CGSize(width: 170, height: 170))
                    indicatorNode!.position = CGPoint(x: -260, y: 170)
                }
                
                if let ingredient = ingredientNode?.ingredient {
                    let iconNode = SKSpriteNode(imageNamed: ingredient.texturePrefix + "Icon")
                    iconNode.zPosition = 6
                    iconNode.scale(to: CGSize(width: 110, height: 110))
                    indicatorNode?.addChild(iconNode)
                } else {
                    indicatorNode?.removeAllChildren()
                }
            }
        }
    }
    
    var plateNode: PlateNode? {
        didSet {
            plateNode?.spriteNode.setScale(plateNodeScale)
        }
    }
    
    private var stationAnimationAtlasName: String? {
        switch stationType {
        case .stove: return "Cook"
        case .fryer: return "Fry"
        case .pipe: return "PipeVacuum"
        case .hatch: return "HatchVacuum"
        default: return nil
        }
    }
    
    private var stationAnimationDuration: Double {
        switch stationType {
        case .stove: return 2
        case .fryer: return 2
        case .pipe: return 0.3
        case .hatch: return 0.3
        default: return 0
        }
    }
    
    private var stationAnimationOffset: CGPoint {
        switch stationType {
        case .stove: return CGPoint(x: 0, y: 122)
        case .fryer: return CGPoint(x: 0, y: 68)
        case .pipe: return CGPoint(x: 3.5, y: 0)
        case .hatch: return CGPoint(x: 5, y: 0)
        default: return .zero
        }
    }
    
    private var stationAnimationScale: CGFloat {
        switch stationType {
        case .stove: return 1
        case .fryer: return 1
        case .pipe: return 0.05
        case .hatch: return 0.08
        default: return .zero
        }
    }
    
    private var stationAnimationRepeats: Bool {
        switch stationType {
        case .board: return false
        default: return true
        }
    }
    
    private var stationAnimationNode: SKSpriteNode?
    private var stationAnimationFrames: [SKTexture]!
    var animationRunning = false
    
    func createAnimation(stationType: StationType) {
        if let stationAnimationAtlasName = stationAnimationAtlasName {
            let stationAtlas = SKTextureAtlas(named: stationAnimationAtlasName)
            stationAnimationFrames = []
            
            for currentAnimation in 0..<stationAtlas.textureNames.count {
                let stationFrameName = stationAnimationAtlasName + "\(currentAnimation > 9 ? currentAnimation.description : "0" + currentAnimation.description)"
                print(stationFrameName)
                stationAnimationFrames!.append(stationAtlas.textureNamed(stationFrameName))
            }
            
            stationAnimationNode = TappableSpriteNode(texture: stationAnimationFrames[0])
            (stationAnimationNode as! TappableSpriteNode).delegate = self
            self.spriteNode.addChild(stationAnimationNode!)
            
            stationAnimationNode?.setScale(stationAnimationScale)
            
            stationAnimationNode!.position = stationAnimationOffset
            stationAnimationNode!.zPosition = 3

            print("Creating \(stationAnimationNode) with textures \(stationAnimationFrames)")
        }
    }
    
    internal init(stationType: StationType, spriteNode: SKSpriteNode?, ingredient: Ingredient?) {
        self.stationType = stationType
        self.ingredient = ingredient
        
        if stationType == .ingredientBox {
            let tappableNode = TappableSpriteNode(imageNamed: ingredient!.texturePrefix + "Box.png")
            self.spriteNode = tappableNode
            tappableNode.delegate = self
        } else if stationType == .plateBox {
            let tappableNode = TappableSpriteNode(imageNamed: "PlateBox.png")
            self.spriteNode = tappableNode
            tappableNode.delegate = self
        } else if stationType == .shelf || stationType == .delivery ||  stationType == .pipe || stationType == .hatch {
            self.spriteNode = spriteNode!
        } else if stationType == .empty {
            let tappableNode = TappableSpriteNode()
            self.spriteNode = tappableNode
            tappableNode.delegate = self
        } else {
            let tappableNode = TappableSpriteNode(imageNamed: stationType.rawValue + ".png")
            self.spriteNode = tappableNode
            tappableNode.delegate = self
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
        
        if stationType == .board {
            let ingredient = ingredientNode?.ingredient
            ingredient?.choppableComponent?.update()
            
            playAnimation()
            
            if ingredient?.choppableComponent?.complete ?? false {
                if (ingredient!.states[ingredient!.currentState] ?? []).contains(IngredientState.chopped) {
                    ingredient?.currentState = .chopped
                }
            }
            
        } else if stationType == .ingredientBox && self.ingredientNode == nil {
            
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
        }
    }
    
    // Scene update intercation
    func update() {
        
        
        if stationType == .stove && !(ingredientNode?.moving ?? true),
            let ingredient = ingredientNode?.ingredient {
            
            ingredient.cookableComponent?.update()
            
            if !animationRunning {
                playAnimation()
            }
            
            if ingredient.cookableComponent?.burnt ?? false {
                if ingredient.states[ingredient.currentState]!.contains(IngredientState.burnt) {
                    ingredient.currentState = .burnt
                    ingredientNode?.checkTextureChange()
                }
            } else if ingredient.cookableComponent?.complete ?? false {
                if ingredient.states[ingredient.currentState]!.contains(IngredientState.cooked) {
                    ingredient.currentState = .cooked
                    ingredientNode?.checkTextureChange()
                }
            }
            
        } else if stationType == .fryer && !(ingredientNode?.moving ?? true),
        let ingredient = ingredientNode?.ingredient  {
            
            ingredient.fryableComponent?.update()
            
            if !animationRunning {
                playAnimation()
            }
            
            if ingredient.fryableComponent?.burnt ?? false {
                if ingredient.states[ingredient.currentState]!.contains(IngredientState.burnt) {
                    ingredient.currentState = .burnt
                    ingredientNode?.checkTextureChange()
                }
            } else if ingredient.fryableComponent?.complete ?? false {
                if ingredient.states[ingredient.currentState]!.contains(IngredientState.fried) {
                    ingredient.currentState = .fried
                    ingredientNode?.checkTextureChange()
                }
            }
        } else if stationType == .stove || stationType == .fryer { //Stops only on these stations
            if animationRunning {
                stopAnimation()
            }
        }
    }
    
    func playAnimation() {
        print("Playing station animation")
        if let node = self.stationAnimationNode {
            print("     Node found, yay!")
            print("     My z \(node.zPosition) papa z\(spriteNode.zPosition)")

            animationRunning = true
            let timePerFrame = TimeInterval(stationAnimationDuration) / TimeInterval(stationAnimationFrames.count)
            var animationAction = SKAction.animate(
                                    with: stationAnimationFrames,
                                    timePerFrame: timePerFrame,
                                    resize: false,
                                    restore: true)
                
            if stationAnimationRepeats {
                print("     This one loops!")
                animationAction = SKAction.repeatForever(animationAction)
            }

            print("     Ranning!")
            node.run(animationAction)
        }
    }
    
    func stopAnimation() {
        print("Stopping station animation")
        animationRunning = false
        stationAnimationNode?.removeAllActions()
    }
}
