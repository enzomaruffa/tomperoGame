//
//  ProgressBar.swift
//  Tompero
//
//  Created by Vinícius Binder on 08/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import SpriteKit

class ProgressBar: SKNode {
    var background: SKSpriteNode?
    var bar: SKSpriteNode?
    var savedProgress: CGFloat = 0
    var progress: CGFloat {
        get {
            return savedProgress
        }
        set {
            let value = max(min(newValue, 1.0), 0.0)
            if let bar = bar {
                bar.xScale = value
                savedProgress = value
            }
        }
    }

    convenience init(color: SKColor, size: CGSize) {
        self.init()
        background = SKSpriteNode(color: SKColor.white, size: size)
        bar = SKSpriteNode(color: color, size: size)
        if let bar = bar, let background = background {
            bar.xScale = 0.0
            bar.zPosition = 1.0
            bar.position = CGPoint(x: -size.width/2, y: 0)
            bar.anchorPoint = CGPoint(x: 0.0, y: 0.5)
            addChild(background)
            addChild(bar)
        }
    }
}
