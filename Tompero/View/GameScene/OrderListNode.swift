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
    
    let offset = UIScreen.main.bounds.width-100
    var isOpen: Bool = false
    
    func open() {
        SKAction.moveBy(x: offset, y: 0, duration: 0.4)
    }
    
    func close() {
        SKAction.moveBy(x: -offset, y: 0, duration: 0.4)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("BEGAN")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("ENDED")
        isOpen ? close() : open()
    }
    
}
