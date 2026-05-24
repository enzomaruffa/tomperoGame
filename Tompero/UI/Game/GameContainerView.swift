//
//  GameContainerView.swift
//  Tompero
//
//  SwiftUI host for the SpriteKit GameScene. Uses native `SpriteView`
//  instead of wrapping the legacy GameViewController so Auto Layout's size
//  race with the SwiftUI host doesn't leave the scene rendering into a 0×0
//  surface (the bug that made audio play but visuals stay blank).
//

import SwiftUI
import SpriteKit

struct GameContainerView: View {
    let rule: GameRule
    let hosting: Bool

    @EnvironmentObject private var router: AppRouter
    @State private var scene: GameScene?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Solid black behind the scene so the navigation push isn't see-through.
                Color.black.ignoresSafeArea()

                if let scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                        .onAppear {
                            // Force the scene's size to match the actual host
                            // size — SpriteView would do it but only after the
                            // first frame; setting it here means GameScene's
                            // `didMove(to:)` sees a real `view.bounds` from
                            // the start.
                            scene.size = proxy.size
                        }
                }
            }
            .onAppear {
                if scene == nil {
                    scene = buildScene(size: proxy.size)
                }
            }
        }
        .onDisappear {
            GameConnectionManager.shared.removeAllObservers()
        }
        .statusBarHidden()
    }

    private func buildScene(size: CGSize) -> GameScene? {
        guard let scene = GameScene(fileNamed: "GameScene") else {
            Log.game.error("Failed to load GameScene.sks")
            return nil
        }
        scene.rule = rule
        scene.hosting = hosting
        scene.scaleMode = UIDevice.current.userInterfaceIdiom == .pad ? .aspectFit : .aspectFill
        // Resize to host before SpriteView attaches it so didMove sees real bounds
        if size.width > 0 && size.height > 0 {
            scene.size = size
        }
        scene.onMatchEnd = { stats in
            router.push(.statistics(stats))
        }
        scene.onMatchError = {
            router.popToRoot()
        }
        Log.game.info("GameContainerView built scene with size \(scene.size.debugDescription, privacy: .public)")
        return scene
    }
}
