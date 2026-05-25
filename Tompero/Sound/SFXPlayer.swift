//
//  SFXPlayer.swift
//  Tompero
//

import Foundation
import AVFoundation

/// Lazily-loaded sound effects. Each property's AVAudioPlayer is created
/// only when first played, so accessing `SFXPlayer.shared` no longer
/// decodes ~12 MB of WAV files on the main thread.
class SFXPlayer {

    static let shared = SFXPlayer()

    lazy var takeFood     = CustomAudioPlayer(fileName: "takeFood.wav", volume: 1.8)
    lazy var putFoodDown  = CustomAudioPlayer(fileName: "putFoodDown.wav", volume: 0.5)

    lazy var chop         = CustomAudioPlayer(fileName: "chopping.wav", volume: 2.0)
    lazy var cooking      = Track(fileName: "cooking.wav", volume: 1.5)
    lazy var frying       = Track(fileName: "frying.wav", volume: 1.5)
    lazy var burn         = CustomAudioPlayer(fileName: "burn.wav", volume: 2.0)

    lazy var hatch        = CustomAudioPlayer(fileName: "hatch.wav", volume: 0.35)
    lazy var airSuction   = Track(fileName: "airSuction.wav", volume: 0.35)

    lazy var orderUp      = CustomAudioPlayer(fileName: "orderUp.wav", volume: 0.9)
    lazy var orderDone    = CustomAudioPlayer(fileName: "orderDone.wav")
    lazy var teleporter   = CustomAudioPlayer(fileName: "teleporter.wav", volume: 2.0)
    lazy var cashRegister = CustomAudioPlayer(fileName: "cashRegister.wav", volume: 2.0)

    lazy var roundStarted = CustomAudioPlayer(fileName: "roundStarted.wav", volume: 1.2)
    lazy var endTimer     = CustomAudioPlayer(fileName: "endTimer.wav", volume: 0.8)
    lazy var timesUp      = CustomAudioPlayer(fileName: "timesUp.wav", volume: 1.0)

    private init() {}
}
