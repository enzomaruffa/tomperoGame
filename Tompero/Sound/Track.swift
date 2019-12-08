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
    
    func load(_ fileName: String) -> AVAudioPlayer {
        let path = Bundle.main.path(forResource: fileName, ofType:nil)!
        let url = URL(fileURLWithPath: path)
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.numberOfLoops = -1 // infinite loop
            return player
        } catch {
            fatalError("se fodeu")
        }
    }
    
    init(fileName: String) {
        super.init()
        self.player = load(fileName)
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
