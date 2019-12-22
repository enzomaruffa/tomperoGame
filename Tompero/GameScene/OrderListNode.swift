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
    
    enum State {
        case closed
        case open
        case closing
        case jumping
    }
    
    var states: [State: [State]] = [
        .closed : [.open, .jumping],
        .open : [.closing],
        .closing : [.closed],
        .jumping : [.closing]
    ]
    var currentState: State = .closed
    
    var orderNodes: [OrderNode] = []
    
    var boundary: SKSpriteNode {
        let scene = parent as! GameScene
        return scene.childNode(withName: "boundary") as! SKSpriteNode
    }
    
    var gameScene: GameScene {
        self.parent as! GameScene
    }
    
    var boundaryStart: CGPoint = CGPoint(x: -3501, y: 250)
    var boundaryEnd: CGPoint = CGPoint(x: 850, y: 250) 
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {  
        super.init(texture: texture, color: color, size: size)
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isUserInteractionEnabled = true
    }
    
    private func canChangeCurrentState(to state: State) -> Bool {
//        print("[OrderListNode.canChangeCurrentState] current state: \(currentState)")
        if states[currentState]!.contains(state) {
            return true
        }
        return false
    }
    
    func open() {
//        print("[OrderListNode.open] entry")
        guard canChangeCurrentState(to: .open) else { return }
        
        physicsBody?.velocity = .zero
        
        children.forEach({ $0.alpha = 1 })
        gameScene.physicsWorld.gravity.dx = 30
        
//        print("[OrderListNode.open] applying impulse on \(physicsBody)")
        
        physicsBody?.applyImpulse(CGVector(dx: 10000, dy: 0))
        currentState = .open
    }
    
    func close() {
//        print("[OrderListNode.close] entry")
        guard canChangeCurrentState(to: .closing) else { return }
        
        physicsBody?.velocity = .zero
        currentState = .closing
        
        gameScene.physicsWorld.gravity.dx = -30
        
//        print("[OrderListNode.close] applying impulse on \(physicsBody)")
        
        physicsBody?.applyImpulse(CGVector(dx: -8000, dy: 0))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.currentState = .closed
        }
    }
    
    func jump() {
//        print("[OrderListNode.jump] entry")
        guard canChangeCurrentState(to: .jumping) else { return }
        
        currentState = .jumping
        
//        print("[OrderListNode.jump] gravity is  \(gameScene.physicsWorld.gravity)")
        
        children.forEach({ $0.alpha = 0 })
        
//        print("[OrderListNode.jump] applying impulse on \(physicsBody)")
        physicsBody?.applyImpulse(CGVector(dx: 1000, dy: 0))
        
        currentState = .closed
    }

    func checkAction() {
        if canChangeCurrentState(to: .open) {
            open()
        } else if canChangeCurrentState(to: .closing) {
            close()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if canChangeCurrentState(to: .open) {
            open()
        } else if canChangeCurrentState(to: .closing) {
            close()
        }
    }
    
    func updateList(_ orderList: [Order]) {
        orderNodes.forEach({ $0.removeFromParent() })
        
        let xPos: [CGFloat] = [753, 103, -557]
        
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
