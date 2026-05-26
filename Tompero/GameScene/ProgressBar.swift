//
//  ProgressBar.swift
//  Tompero
//
//  Created by Vinícius Binder on 08/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//
//  Rounded capsule track with an inset colored fill that scales with
//  progress. `bar` stays an SKSpriteNode so callers can recolor it
//  (`.colorize` / `.color`) for the green→yellow→red urgency tiers.
//

import Foundation
import SpriteKit

class ProgressBar: SKNode {
    var background: SKNode?
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

        let cornerRadius = size.height / 2

        // Track — dark translucent capsule with a soft light rim.
        let track = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        track.fillColor = SKColor.black.withAlphaComponent(0.5)
        track.strokeColor = SKColor.white.withAlphaComponent(0.55)
        track.lineWidth = max(size.height * 0.12, 2)
        track.zPosition = 0
        addChild(track)
        background = track

        // Fill — inset so the track's rounded rim frames it; left-anchored
        // and xScaled by progress. Kept as a sprite for recoloring.
        let inset = max(size.height * 0.22, 3)
        let fillSize = CGSize(width: size.width - inset * 2, height: size.height - inset * 2)
        let fill = SKSpriteNode(color: color, size: fillSize)
        fill.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        fill.position = CGPoint(x: -fillSize.width / 2, y: 0)
        fill.xScale = 0.0
        fill.zPosition = 1.0
        addChild(fill)
        bar = fill
    }
}
