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
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        self.isUserInteractionEnabled = true
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = true
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
        boundary.position.x = 770
        physicsBody?.applyImpulse(CGVector(dx: 30000, dy: 0))
        physicsBody?.velocity.dx = 9000
    }
    
    func close() {
        isOpen = false
    
        physicsBody?.mass = 0.1
        let action = SKAction.moveTo(x: -1090, duration: 0.13)
        boundary.run(action) {
            self.physicsBody?.mass = 50
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isOpen ? close() : open()
    }
    
}
