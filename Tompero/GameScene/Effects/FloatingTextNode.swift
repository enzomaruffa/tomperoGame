//
//  FloatingTextNode.swift
//  Tompero
//
//  Spawns a transient SKLabelNode at a point that rises and fades out.
//  Used for "+N coins" celebrations on successful delivery and "MISS"
//  feedback on failure.
//

import Foundation
import SpriteKit
import UIKit

enum FloatingTextNode {

    /// Spawns a label at `position` (parent-local coordinates) that drifts
    /// upward 100pt over 1s while fading out, then removes itself.
    static func spawn(text: String, color: UIColor, at position: CGPoint, in parent: SKNode) {
        let label = SKLabelNode(fontNamed: "TitilliumWeb-Bold")
        label.text = text
        label.fontColor = color
        label.fontSize = 96
        label.position = position
        label.zPosition = 200
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        parent.addChild(label)

        let group = SKAction.group([
            SKAction.moveBy(x: 0, y: 180, duration: 1.0),
            SKAction.sequence([
                SKAction.wait(forDuration: 0.4),
                SKAction.fadeOut(withDuration: 0.6)
            ])
        ])
        label.run(SKAction.sequence([group, SKAction.removeFromParent()]))
    }
}
