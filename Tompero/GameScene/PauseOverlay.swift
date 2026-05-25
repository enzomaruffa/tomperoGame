//
//  PauseOverlay.swift
//  Tompero
//
//  Renders the in-match pause UI — dim background + "PAUSED" label +
//  RESUME / QUIT buttons. Constructed lazily on the first pause so a
//  match that never pauses doesn't pay the cost.
//
//  Mirrors the structure of `ReconnectionOverlayController` (same scene-
//  attached SKNode pattern). The two action buttons each get their own
//  closure-backed tap delegate so the shared protocol stays a no-arg
//  `tap()`.
//

import Foundation
import SpriteKit
import UIKit

/// Wraps a one-arg closure as a `TappableDelegate`. Useful when several
/// buttons share the same protocol shape but need different behavior.
final class TappableClosure: TappableDelegate {
    private let handler: () -> Void
    init(_ handler: @escaping () -> Void) {
        self.handler = handler
    }
    func tap() {
        handler()
    }
}

final class PauseOverlay {

    private weak var scene: SKScene?
    private var overlay: SKNode?
    private let onResume: () -> Void
    private let onQuit: () -> Void
    private var resumeDelegate: TappableClosure!
    private var quitDelegate: TappableClosure!

    init(scene: SKScene, onResume: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.scene = scene
        self.onResume = onResume
        self.onQuit = onQuit
        self.resumeDelegate = TappableClosure { [weak self] in self?.onResume() }
        self.quitDelegate = TappableClosure { [weak self] in self?.onQuit() }
    }

    func show() {
        guard let scene, let camera = scene.camera else { return }
        let node = overlay ?? makeOverlay()
        if node.parent == nil {
            camera.addChild(node)
        }
        overlay = node
    }

    func hide() {
        overlay?.removeFromParent()
    }

    private func makeOverlay() -> SKNode {
        let node = SKNode()
        node.zPosition = 1500
        node.name = "pauseOverlay"

        let dim = SKShapeNode(rectOf: CGSize(width: 4000, height: 4000))
        dim.fillColor = UIColor.black.withAlphaComponent(0.65)
        dim.strokeColor = .clear
        node.addChild(dim)

        let title = SKLabelNode(fontNamed: "TitilliumWeb-Bold")
        title.text = "PAUSED"
        title.fontSize = 140
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: 180)
        node.addChild(title)

        let resume = makeButton(text: "RESUME", color: UIColor(white: 1, alpha: 0.18))
        resume.position = CGPoint(x: 0, y: -20)
        resume.delegate = resumeDelegate
        resume.name = "pauseResume"
        node.addChild(resume)

        let quit = makeButton(text: "QUIT", color: UIColor(red: 0.6, green: 0.1, blue: 0.1, alpha: 0.55))
        quit.position = CGPoint(x: 0, y: -180)
        quit.delegate = quitDelegate
        quit.name = "pauseQuit"
        node.addChild(quit)

        return node
    }

    private func makeButton(text: String, color: UIColor) -> TappableSpriteNode {
        let size = CGSize(width: 480, height: 120)
        let button = TappableSpriteNode(color: color, size: size)
        button.zPosition = 10

        let label = SKLabelNode(fontNamed: "TitilliumWeb-Bold")
        label.text = text
        label.fontSize = 64
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        button.addChild(label)

        return button
    }
}
