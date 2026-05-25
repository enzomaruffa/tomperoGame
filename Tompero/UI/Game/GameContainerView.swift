//
//  GameContainerView.swift
//  Tompero
//
//  SwiftUI host for the SpriteKit GameScene. Uses native `SpriteView`
//  instead of wrapping the legacy GameViewController so Auto Layout's size
//  race with the SwiftUI host doesn't leave the scene rendering into a 0×0
//  surface.
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
            // Solid black behind the scene so the navigation push isn't see-through.
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
        .statusBarHidden()
    }

    private func buildScene() -> GameScene? {
        guard let scene = GameScene(fileNamed: "GameScene") else {
            Log.game.error("Failed to load GameScene.sks")
            return nil
        }
        scene.rule = rule
        scene.hosting = hosting
        // .aspectFill on phone scales the scene to cover the view. The scene's
        // logical `.size` stays whatever the .sks file encoded — that matters
        // because `GameScene.setupStations()` uses `scene.size.width` as the
        // canvas its station-position math is calibrated for. Overriding
        // scene.size to the SwiftUI host size shrinks the canvas and stations
        // overlap.
        scene.scaleMode = UIDevice.current.userInterfaceIdiom == .pad ? .aspectFit : .aspectFill
        scene.onMatchEnd = { [weak scene] stats in
            let actions = scene?.state.myActions ?? .zero
            let peers = scene?.state.peerAwards ?? [:]
            router.push(.statistics(stats, localActions: actions, peerAwards: peers))
        }
        scene.onMatchError = {
            router.popToRoot()
        }
        Log.game.info("GameContainerView built scene with size \(scene.size.debugDescription, privacy: .public)")
        return scene
    }
}
