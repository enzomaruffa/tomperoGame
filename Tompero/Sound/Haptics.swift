//
//  Haptics.swift
//  Tompero
//
//  Lightweight tactile feedback for core interactions. Pairs with the
//  existing SFX so picking up, placing, chopping, and delivering all have
//  a physical response — a big lift to perceived "game feel" on device.
//  Gated on the same `soundOn` toggle as SFX so muting silences both.
//

import UIKit

enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let notification = UINotificationFeedbackGenerator()

    private static var enabled: Bool { MusicPlayer.shared.soundOn }

    /// Grabbing an item off a box / shelf / station.
    static func pickup() {
        guard enabled else { return }
        light.impactOccurred()
    }

    /// Dropping an item onto a station / shelf.
    static func place() {
        guard enabled else { return }
        medium.impactOccurred()
    }

    /// A single chop on the cutting board — crisp and short.
    static func chop() {
        guard enabled else { return }
        rigid.impactOccurred(intensity: 0.7)
    }

    /// A successful order delivery.
    static func success() {
        guard enabled else { return }
        notification.notificationOccurred(.success)
    }

    /// A failed / mismatched delivery.
    static func failure() {
        guard enabled else { return }
        notification.notificationOccurred(.error)
    }
}
