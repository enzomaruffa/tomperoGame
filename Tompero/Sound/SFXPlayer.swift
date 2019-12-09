//
//  SFXPlayer.swift
//  Tompero
//
//  Created by Vinícius Binder on 08/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import AVFoundation

class SFXPlayer {
    
    static let shared = SFXPlayer()
    
    let takeFood        = CustomAudioPlayer(fileName: "takeFood.wav", volume: 1.8)
    let putFoodDown     = CustomAudioPlayer(fileName: "putFoodDown.wav", volume: 0.5)
    
    let chop            = CustomAudioPlayer(fileName: "chopping.wav", volume: 2.0)
    let cooking                     = Track(fileName: "cooking.wav", volume: 1.5)
    let frying                      = Track(fileName: "frying.wav", volume: 1.5)
    let burn            = CustomAudioPlayer(fileName: "burn.wav", volume: 2.0)
    
    let hatch           = CustomAudioPlayer(fileName: "hatch.wav", volume: 0.35)
    let airSuction                  = Track(fileName: "airSuction.wav", volume: 0.35)
    
    let orderUp         = CustomAudioPlayer(fileName: "orderUp.wav", volume: 0.9)
    let orderDone       = CustomAudioPlayer(fileName: "orderDone.wav")
    let teleporter      = CustomAudioPlayer(fileName: "teleporter.wav", volume: 2.0)
    let cashRegister    = CustomAudioPlayer(fileName: "cashRegister.wav", volume: 2.0)
    
    let roundStarted    = CustomAudioPlayer(fileName: "roundStarted.wav", volume: 1.2)
    let endTimer        = CustomAudioPlayer(fileName: "endTimer.wav", volume: 0.8)
    let timesUp         = CustomAudioPlayer(fileName: "timesUp.wav", volume: 1.0)
    
}
