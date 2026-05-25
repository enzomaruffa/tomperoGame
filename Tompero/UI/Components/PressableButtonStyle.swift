//
//  PressableButtonStyle.swift
//  Tompero
//
//  Tactile button-press feedback for menu screens. Replaces `.buttonStyle(.plain)`
//  on every menu button so taps feel slightly responsive — small scale-down on
//  press, springy bounce back on release. No color, no border — purely motion
//  so it composes over the existing custom image-based buttons.
//

import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
