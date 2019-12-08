//
//  SFX.swift
//  Tompero
//
//  Created by Vinícius Binder on 08/12/19.
//  Copyright © 2019 Tompero. All rights reserved.
//

import Foundation
import AVFoundation

class SFX {
    
    static let shared = SFX()
    
    let putFoodDown     = CustomAudioPlayer(fileName: "putFoodDown.wav")
    let takeFood        = CustomAudioPlayer(fileName: "takeFood.wav")
    
    let chop            = CustomAudioPlayer(fileName: "chopping.wav")
    let cooking         = CustomAudioPlayer(fileName: "cooking.wav")
    let frying          = CustomAudioPlayer(fileName: "frying.wav")
    let burn            = CustomAudioPlayer(fileName: "burn.wav")
    
    let hatch           = CustomAudioPlayer(fileName: "hatch.wav")
    let airSuction      = CustomAudioPlayer(fileName: "airSuction.wav")
    
    let orderUp         = CustomAudioPlayer(fileName: "orderUp.wav")
    let orderDone       = CustomAudioPlayer(fileName: "orderDone.wav")
    let teleporter      = CustomAudioPlayer(fileName: "teleporter.wav")
    let cashRegister    = CustomAudioPlayer(fileName: "cashRegister.wav")
    
    let roundStarted    = CustomAudioPlayer(fileName: "roundStarted.wav")
    let endTimer        = CustomAudioPlayer(fileName: "endTimer.wav")
    let timesUp         = CustomAudioPlayer(fileName: "timesUp.wav")
    
}
