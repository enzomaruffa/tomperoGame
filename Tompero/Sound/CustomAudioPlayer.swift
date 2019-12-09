//
//  CustomAudioPlayer.swift
//  SoundWorkshop
//
//  Created by Vinícius Binder on 29/10/19.
//  Copyright © 2019 Vinícius Binder. All rights reserved.
//

import AVFoundation

class CustomAudioPlayer {
    
    private var players = [AVAudioPlayer]()
    private var url: URL!
    
    var volume: Float = 1.0
    
    fileprivate func load() {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            players.append(player)
        } catch {
            print("se fodeu playboy")
        }
    }
    
    init(fileName: String, volume: Float) {
        let path = Bundle.main.path(forResource: fileName, ofType:nil)!
        url = URL(fileURLWithPath: path)
        self.volume = volume
        load()
    }
    
    convenience init(fileName: String) {
        self.init(fileName: fileName, volume: 1.0)
    }
    
    func play() {
        for player in players {
            if !player.isPlaying {
                player.play()
                return
            }
        }
        
        load()
        players.last?.play()
    }
}
