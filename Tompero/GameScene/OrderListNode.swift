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
        let scene = self.parent as! GameScene
        return scene.childNode(withName: "boundary") as! SKSpriteNode
    }
    
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
    
    private func canChangeCurrentState(to state: State) -> Bool {
        print("[orderList.canchangecurrentState] attempt change to \(state) from \(currentState)")
        if states[currentState]!.contains(state) {
            print("[orderList.canchangecurrentState] returning true")
            return true
        }
        
        print("[orderList.canchangecurrentState] returning false")
        return false
    }
    
    func open() {
        print("[orderList] open called")
        guard canChangeCurrentState(to: .open) else { return }
        print("[orderList] opening...")
        
        currentState = .open
        
        self.physicsBody?.velocity = .zero
        
        self.children.forEach({ $0.alpha = 1 })
        self.gameScene.physicsWorld.gravity.dx = 30
        self.physicsBody?.restitution = 0.07
        boundary.physicsBody?.restitution = 0.07
        
        boundary.position.x = 982
        
        physicsBody?.applyImpulse(CGVector(dx: 10000, dy: 0))
    }
    
    func close() {
        print("[orderList.close] close called...")
        guard canChangeCurrentState(to: .closing) else { return }
        print("[orderList.close] closing...")
        
        self.physicsBody?.velocity = .zero
        currentState = .closing
        
        self.gameScene.physicsWorld.gravity.dx = 30
        self.physicsBody?.restitution = 0.1
        
        let animationDuration = 0.13

        print("[orderList.close] running move...")
        self.removeAllActions()
        let action = SKAction.moveTo(x: -1041, duration: animationDuration)
        boundary.run(action) {
            self.children.forEach({ $0.alpha = 0 })
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            self.currentState = .closed
            print("[orderList.close] state: closed...")
        }
    }
    
    func jump() {
        print("[orderList] jump called...")
        guard canChangeCurrentState(to: .jumping) else { return }
        print("[orderList] jumping...")
        
        currentState = .jumping
        
        self.children.forEach({ $0.alpha = 0 })
        boundary.run(SKAction.sequence([
            .run {
                self.gameScene.physicsWorld.gravity.dx = -30
                self.physicsBody?.restitution = 0.3
                
                self.boundary.position.x = -850
                
                self.physicsBody?.applyImpulse(CGVector(dx: 3000, dy: 0))
            },
            .run {
                // TODO: Possible bug. Close should only happen after the duration ends
                self.close()
            }
        ]))
    }

    func checkAction() {
        print("[orderList] check aciton called")
        if canChangeCurrentState(to: .open) {
            open()
        } else if canChangeCurrentState(to: .closing) {
            close()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("[orderList.touchesended] touchesEnded...")
        if canChangeCurrentState(to: .open) {
            print("[orderList.touchesended] calling open...")
            open()
        } else if canChangeCurrentState(to: .closing) {
            print("[orderList.touchesended] calling close...")
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
