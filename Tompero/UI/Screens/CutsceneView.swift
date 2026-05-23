//
//  CutsceneView.swift
//  Tompero
//
//  SwiftUI host for the existing SpriteKit `Cutscene`. Uses SwiftUI's
//  native SpriteView; the cutscene fires its `onFinish` callback when video
//  playback ends or the back button is tapped, and the router pops.
//

import SwiftUI
import SpriteKit

struct CutsceneView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var scene: Cutscene = Cutscene(size: UIScreen.main.bounds.size)

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .onAppear {
                scene.scaleMode = .aspectFit
                scene.backgroundColor = .black
                scene.onFinish = {
                    router.pop()
                }
            }
    }
}
