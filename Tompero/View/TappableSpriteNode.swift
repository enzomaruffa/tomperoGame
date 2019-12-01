//
//  TouchableSpriteNode.swift
//  Tompero
//
//  Created by Enzo Maruffa Moreira on 30/11/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class TappableSpriteNode: SKSpriteNode {
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isUserInteractionEnabled = true
    }
    
    var initialTouchPosition: CGPoint?
    weak var delegate: TappableDelegate?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else { return }
        
        let touch = touches.first!
        initialTouchPosition = touch.location(in: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //        guard let touch = touches.first else { return }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        if let initialTouchPosition = self.initialTouchPosition {
            let finalTouchPosition = touch.location(in: self)
            if initialTouchPosition.distanceTo(finalTouchPosition) < 10 {
                print("Tappable delegate pressed \(delegate)")
                delegate?.tap()
            }
        }
    }
}

