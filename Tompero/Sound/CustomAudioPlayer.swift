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
    
    fileprivate func load() {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players.append(player)
        } catch {
            print("se fodeu playboy")
        }
    }
    
    init(fileName: String) {
        let path = Bundle.main.path(forResource: fileName, ofType:nil)!
        url = URL(fileURLWithPath: path)
        load()
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
