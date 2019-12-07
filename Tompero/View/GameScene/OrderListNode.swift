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
        boundary.position.x = 780
        physicsBody?.applyImpulse(CGVector(dx: 30000, dy: 0))
        physicsBody?.velocity.dx = 8000
    }
    
    func close() {
        isOpen = false
    
        physicsBody?.mass = 0.1
        let action = SKAction.moveTo(x: -1041, duration: 0.13)
        boundary.run(action) {
            self.physicsBody?.mass = 50
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isOpen ? close() : open()
    }
    
    func update(_ orderList: [Order]) {
        orderNodes.forEach({ $0.removeFromParent() })
        
        let xPos: [CGFloat] = [593.0, 0.0, -593.0]
        //let extraOrders = orderList.count - 4
        for (index, order) in orderList.enumerated() {
            guard index < 3 else { break }
            
            let node = OrderNode()
            node.order = order
            node.position = CGPoint(x: xPos[index], y: 7)
            node.zPosition = 6
            node.spawnIngredientIcons()
            orderNodes.append(node)
            addChild(node)
        }
        
        //let node = childNode(withName: "extraOrders") as! SKLabelNode
        //node.text = extraOrders > 0 ? "+" + extraOrders.description : ""
    }
}
