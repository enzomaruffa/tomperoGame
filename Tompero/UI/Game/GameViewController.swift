//
//  GameViewController.swift
//  Tompero
//
//  Hosts the SpriteKit GameScene. No longer storyboard-driven — built
//  programmatically so the SwiftUI `GameContainerView` can wrap it via
//  UIViewControllerRepresentable.
//

import UIKit
import SpriteKit
import GameplayKit

final class GameViewController: UIViewController {

    var rule: GameRule?
    var hosting: Bool = false
    var onMatchEnd: ((MatchStatistics) -> Void)?
    var onMatchError: (() -> Void)?

    private let skView = SKView()

    override func loadView() {
        // Code-only: no storyboard outlet. The SKView is the full content.
        view = skView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let scene = GameScene(fileNamed: "GameScene") {
            scene.rule = rule
            scene.hosting = hosting
            scene.controller = self
            scene.onMatchEnd = onMatchEnd
            scene.onMatchError = onMatchError

            scene.scaleMode = traitCollection.verticalSizeClass == .regular ? .aspectFit : .aspectFill
            scene.backgroundColor = .clear

            skView.allowsTransparency = true
            skView.backgroundColor = .clear
            skView.ignoresSiblingOrder = true
            skView.presentScene(scene)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        GameConnectionManager.shared.removeAllObservers()
    }

    override var shouldAutorotate: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .phone ? .allButUpsideDown : .all
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { false }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }
}
