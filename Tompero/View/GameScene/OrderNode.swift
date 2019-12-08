//
//  OrderNode.swift
//  Tompero
//
//  Created by Vinícius Binder on 06/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class OrderNode: SKSpriteNode {
    
    var order: Order?
    var progressNode = ProgressBar()
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        //super.init(texture: texture, color: #colorLiteral(red: 1, green: 0.270588249, blue: 0.2274509817, alpha: 1), size: CGSize(width: 600, height: 568))
        super.init(texture: texture, color: UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0), size: CGSize(width: 600, height: 568))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initOrder(_ order: Order) {
        self.order = order
        spawnIngredientIcons()
        spawnOrderNumber()
        spawnTimeBar()
    }
    
    func sortActions(_ states: [IngredientState: [IngredientState]]) -> [IngredientState] {
        var ordered: [IngredientState] = []
        
        let actions: [IngredientState] = [.chopping, .cooking, .frying]
        
        for action in actions {
            states.keys.forEach({
                if $0 == action {
                    ordered.append(action)
                }
            })
        }
        
        return ordered
    }
    
    func spawnIngredientIcons() {
        
        let yPos: [CGFloat] = [-4.0, -72.0, -140.0]
        
        let xPos: [CGFloat] = [-230.0, -115.0, 0.0, 115.0, 230.0]
        
        for (index, ingredient) in order!.ingredients.enumerated() {
            let circle = SKSpriteNode(imageNamed: "IngredientIndicator")
            self.addChild(circle)
            circle.position = CGPoint(x: xPos[index], y: 120)
            circle.zPosition = 7
            circle.size = CGSize(width: 110, height: 110)
            
            let node = SKSpriteNode(imageNamed: ingredient.texturePrefix + "Raw")
            circle.addChild(node)
            node.zPosition = 8
            node.size = CGSize(width: 100, height: 100)
            
            let actions = sortActions(ingredient.states)
            
            var jndex = 0
            for state in actions {
                var name = ""
                switch state {
                case .chopping: name = "Chop"
                case .cooking: name = "Cook"
                case .frying: name = "Fry"
                default: continue
                }
                
                let actionNode = SKSpriteNode(imageNamed: name + "Icon")
                actionNode.position = CGPoint(x: xPos[index], y: yPos[jndex])
                jndex += 1
                actionNode.zPosition = 9
                actionNode.setScale(0.65)
                self.addChild(actionNode)
            }
        }
    }
    
    func spawnOrderNumber() {
        let node = SKLabelNode(text: "Order #" + order!.number.description)
        node.position = CGPoint(x: 0, y: 200)
        node.fontName = "TitilliumWeb-Light"
        node.fontSize = 60
        addChild(node)
    }
    
    func spawnTimeBar() {
        progressNode = ProgressBar(color: .green, size: CGSize(width: 480, height: 20))
        progressNode.position = CGPoint(x: 0, y: -220)
        print(order!.timeLeft, order!.totalTime)
        progressNode.progress = CGFloat(1 - order!.timeLeft/order!.totalTime)
        addChild(progressNode)
    }
    
    func updateBar() {
        progressNode.progress += CGFloat(1/(60*order!.totalTime))
    }
}
