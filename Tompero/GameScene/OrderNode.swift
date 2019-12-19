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
    var yellow = false
    var red = false
    
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
        updateBar()
    }
    
    private func sortActions(_ states: [IngredientState: [IngredientState]]) -> [IngredientState] {
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
    
    private func spawnIngredientIcons() {
        
        let xPos: [CGFloat] = [-230, -115, 0, 115, 230]
        let yPos: [CGFloat] = [12, -56, -124]
        let arrowSize: [CGFloat] = [110, 180, 240]
        
        for (index, ingredient) in order!.ingredients.enumerated() {
            let circle = SKSpriteNode(imageNamed: "IngredientIndicator")
            self.addChild(circle)
            circle.position = CGPoint(x: xPos[index], y: 118)
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
            
            if !actions.isEmpty {
                let height = arrowSize[actions.count-1]
                spawnArrow(at: CGPoint(x: xPos[index], y: 62 - height), of: height)
            }
        }
    }
    
    private func spawnArrow(at position: CGPoint, of height: CGFloat) {
        let node = SKShapeNode(rect: CGRect(origin: position, size: CGSize(width: 1, height: height)))
        node.fillColor = .white
        node.strokeColor = node.fillColor
        addChild(node)
        
        let end = SKSpriteNode(imageNamed: "arrowEnd")
        end.zRotation = CGFloat(Double.pi)
        end.size = CGSize(width: 20, height: 20)
        end.position = CGPoint(x: position.x+1, y: 70-height-11)
        addChild(end)
    }
    
    private func spawnOrderNumber() {
        let node = SKLabelNode(text: "Order #" + order!.number.description)
        node.position = CGPoint(x: 0, y: 200)
        node.fontName = "TitilliumWeb-Light"
        node.fontSize = 60
        addChild(node)
    }
    
    private func spawnTimeBar() {
        progressNode = ProgressBar(color: .green, size: CGSize(width: 480, height: 20))
        progressNode.position = CGPoint(x: 0, y: -232.5)
        print(order!.timeLeft, order!.totalTime)
        progressNode.progress = CGFloat(1 - order!.timeLeft/order!.totalTime)
        addChild(progressNode)
    }
    
    func updateBar() {
        progressNode.progress += CGFloat(1/(60*order!.totalTime))
        
        if progressNode.progress > 0.35 && progressNode.progress <= 0.7 && !yellow {
            yellow = true
            progressNode.bar?.run(.colorize(with: .yellow, colorBlendFactor: 1, duration: 0.5))
        }
        
        if progressNode.progress > 0.7 && !red {
            red = true
            progressNode.bar?.run(.colorize(with: .red, colorBlendFactor: 1, duration: 0.5))
        }
    }
}
