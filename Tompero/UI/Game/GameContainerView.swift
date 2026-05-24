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
        ZStack {
            // Solid black under the scene so the navigation push isn't see-through.
            Color.black.ignoresSafeArea()

            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if scene == nil {
                scene = buildScene()
            }
        }
        .onDisappear {
            GameConnectionManager.shared.removeAllObservers()
        }
        .statusBarHidden()
    }

    private func buildScene() -> GameScene? {
        guard let scene = GameScene(fileNamed: "GameScene") else {
            Log.game.error("Failed to load GameScene.sks")
            return nil
        }
        scene.rule = rule
        scene.hosting = hosting
        scene.scaleMode = UIDevice.current.userInterfaceIdiom == .pad ? .aspectFit : .aspectFill
        scene.onMatchEnd = { stats in
            router.push(.statistics(stats))
        }
        scene.onMatchError = {
            router.popToRoot()
        }
        return scene
    }
}
