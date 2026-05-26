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
    @State private var isPaused = false

    var body: some View {
        ZStack {
            // Solid black behind the scene so the navigation push isn't see-through.
            Color.black.ignoresSafeArea()

            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }

            // Full-screen pause overlay — rendered in SwiftUI (not SpriteKit)
            // so it reliably covers the whole screen. Driven by the scene's
            // pause state, which flips for both local taps and remote peers.
            if isPaused {
                PauseOverlayView(
                    onResume: { scene?.resumeMatch() },
                    onQuit: { scene?.quitMatch() }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPaused)
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
        scene.onPauseChanged = { paused in
            isPaused = paused
        }
        Log.game.info("GameContainerView built scene with size \(scene.size.debugDescription, privacy: .public)")
        return scene
    }
}

/// Full-screen modal pause UI rendered over the SpriteView. Replaces the
/// camera-attached SKNode overlay, which couldn't reliably cover the whole
/// frame (a foreground scene sprite rendered above it).
private struct PauseOverlayView: View {
    let onResume: () -> Void
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 28) {
                Text("PAUSED")
                    .font(.custom("TitilliumWeb-Bold", size: 56))
                    .foregroundColor(.white)

                Button(action: onResume) {
                    Text("RESUME")
                        .font(.custom("TitilliumWeb-Bold", size: 26))
                        .foregroundColor(.white)
                        .frame(width: 280, height: 64)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.13, green: 0.11, blue: 0.26))
                                .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 2))
                        )
                }
                .buttonStyle(PressableButtonStyle())

                Button(action: onQuit) {
                    Text("QUIT")
                        .font(.custom("TitilliumWeb-Bold", size: 26))
                        .foregroundColor(.white)
                        .frame(width: 280, height: 64)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.62, green: 0.12, blue: 0.12))
                                .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 2))
                        )
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }
}
