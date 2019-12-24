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
        DispatchQueue.global(qos: .background).async {
            for player in self.players where !player.isPlaying {
                player.play()
                return
            }
            
            self.load()
            self.players.last?.play()
        }
    }
}
