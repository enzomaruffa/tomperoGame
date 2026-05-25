//
//  ReconnectionOverlay.swift
//  Tompero
//
//  Pulls the disconnect-recovery overlay out of GameScene. Holds the
//  overlay node + timeout timer + pause-the-scene side effect so the
//  scene can forward `playerUpdate` events with a one-liner.
//

import Foundation
import SpriteKit
import UIKit

final class ReconnectionOverlayController {

    private weak var scene: SKScene?
    private var overlay: SKNode?
    private var timeoutTimer: Timer?
    private let timeoutSeconds: TimeInterval
    private let onTimeout: () -> Void

    /// - Parameters:
    ///   - scene: the SpriteKit scene to pause/unpause and host the overlay on (the overlay is attached to the scene's camera).
    ///   - timeoutSeconds: how long to wait for a peer to come back before declaring the match dead. Default mirrors the original GameScene behavior.
    ///   - onTimeout: invoked on the main queue once the timeout fires. Typically aborts the match.
    init(scene: SKScene, timeoutSeconds: TimeInterval = 30, onTimeout: @escaping () -> Void) {
        self.scene = scene
        self.timeoutSeconds = timeoutSeconds
        self.onTimeout = onTimeout
    }

    /// Show or update the overlay for a peer that just dropped (or is in the
    /// middle of (re)connecting). Pauses the scene and resets the timeout.
    func begin(for player: String) {
        guard let scene else { return }
        let node = overlay ?? makeOverlay()
        node.children
            .compactMap { $0 as? SKLabelNode }
            .forEach { $0.text = "\(player) reconnecting…" }
        if node.parent == nil, let camera = scene.camera {
            camera.addChild(node)
        }
        scene.isPaused = true
        overlay = node
        cancelTimeout()
        scheduleTimeout()
    }

    /// Dismiss the overlay; called when the peer's connection state flips
    /// back to `.connected`. No-op if the overlay isn't currently shown.
    func end() {
        guard overlay != nil else { return }
        overlay?.removeFromParent()
        overlay = nil
        cancelTimeout()
        scene?.isPaused = false
    }

    /// Drop the timeout (e.g. when the match ends naturally and the overlay
    /// should not fire `onTimeout` from beyond the grave).
    func tearDown() {
        cancelTimeout()
    }

    // MARK: - Private

    private func makeOverlay() -> SKNode {
        let node = SKNode()
        node.zPosition = 1000
        node.name = "reconnectingOverlay"

        let dim = SKShapeNode(rectOf: CGSize(width: 4000, height: 4000))
        dim.fillColor = UIColor.black.withAlphaComponent(0.65)
        dim.strokeColor = .clear
        node.addChild(dim)

        let label = SKLabelNode(fontNamed: "TitilliumWeb-Bold")
        label.fontSize = 80
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        node.addChild(label)
        return node
    }

    private func scheduleTimeout() {
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeoutSeconds, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.onTimeout()
            }
        }
    }

    private func cancelTimeout() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
}
