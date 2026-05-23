//
//  StarsBackground.swift
//  Tompero
//
//  SwiftUI wrapper for the existing `StarsOverlay: UIView` CAEmitterLayer
//  particle effect. Reused as a background on every screen.
//

import SwiftUI
import UIKit

struct StarsBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> StarsOverlay {
        StarsOverlay(frame: .zero)
    }

    func updateUIView(_ uiView: StarsOverlay, context: Context) {
        // The view's own `didMoveToWindow` lifecycle drives the emitter
        // timer; no per-update work needed.
    }
}
