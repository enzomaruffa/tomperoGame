//
//  GameContainerView.swift
//  Tompero
//
//  SwiftUI wrapper around the still-UIKit GameViewController, which hosts
//  the SpriteKit GameScene. Stub for now; the real wrapper lands in a later
//  commit once GameViewController is rewritten to be code-only.
//

import SwiftUI

struct GameContainerView: View {
    let rule: GameRule
    let hosting: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Game — TODO")
                .foregroundColor(.white)
        }
    }
}
