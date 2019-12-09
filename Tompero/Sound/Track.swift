//
//  Music.swift
//  SoundWorkshop
//
//  Created by Vinícius Binder on 29/10/19.
//  Copyright © 2019 Vinícius Binder. All rights reserved.
//

import AVFoundation

class Track: NSObject {
    private var player: AVAudioPlayer!
    
    func load(_ fileName: String, _ volume: Float) -> AVAudioPlayer {
        let path = Bundle.main.path(forResource: fileName, ofType:nil)!
        let url = URL(fileURLWithPath: path)
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            player.numberOfLoops = -1 // infinite loop
            return player
        } catch {
            fatalError("se fodeu")
        }
    }
    
    init(fileName: String, volume: Float) {
        super.init()
        self.player = load(fileName, volume)
    }
    
    convenience init(fileName: String) {
        self.init(fileName: fileName, volume: 1.0)
    }
    
    func play() {
        if player.isPlaying {
            return
        }
        
        player.play()
    }
    
    func stop() {
        player.stop()
        player.currentTime = 0
    }
}
