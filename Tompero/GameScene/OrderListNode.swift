//
//  OrderListNode.swift
//  Tompero
//
//  Created by Vinícius Binder on 06/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class OrderListNode: SKSpriteNode {
    
    var orderNodes: [OrderNode] = []
    
    var gameScene: GameScene {
        self.parent as! GameScene
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isUserInteractionEnabled = true
    }
    
    var isOpen: Bool = false
    var boundary: SKSpriteNode {
        let scene = self.parent as! GameScene
        return scene.childNode(withName: "boundary") as! SKSpriteNode
    }
    
    func open() {
        isOpen = true
        boundary.removeAllActions()
        normalSetup()
        boundary.position.x = 982
        physicsBody?.applyImpulse(CGVector(dx: 40000, dy: 0))
        physicsBody?.velocity.dx = 8100
    }
    
    func close() {
        isOpen = false
        physicsBody?.mass = 0.1
        let action = SKAction.moveTo(x: -1041, duration: 0.13)
        boundary.run(action) {
            self.physicsBody?.mass = 50
        }
    }
    
    func normalSetup() {
        self.gameScene.physicsWorld.gravity.dx = 30
        self.children.forEach({ $0.alpha = 1 })
        self.physicsBody?.mass = 50
        self.physicsBody?.restitution = 0.1
    }
    
    func jump() {
        guard !isOpen else { return }
        
        boundary.run(SKAction.sequence([
            .run {
                self.physicsBody?.mass = 0.1
                self.physicsBody?.restitution = 0.3
                self.gameScene.physicsWorld.gravity.dx = -self.gameScene.physicsWorld.gravity.dx
                self.children.forEach({ $0.alpha = 0 })
                self.boundary.position.x = -850
                self.physicsBody?.applyImpulse(CGVector(dx: 170, dy: 0))
            },
            .moveTo(x: -1041, duration: 0.8),
            .run {
                self.normalSetup()
            }
        ]))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isOpen ? close() : open()
    }
    
    func updateList(_ orderList: [Order]) {
        orderNodes.forEach({ $0.removeFromParent() })
        
        let xPos: [CGFloat] = [658, 8, -652]
        
        for (index, order) in orderList.enumerated() {
            guard index < 3 else { break }
            
            let node = OrderNode()
            node.position = CGPoint(x: xPos[index], y: 7)
            node.zPosition = 6
            node.initOrder(order)
            orderNodes.append(node)
            addChild(node)
        }
    }
    
    func update() {
        orderNodes.forEach({ $0.updateBar() })
    }
}
