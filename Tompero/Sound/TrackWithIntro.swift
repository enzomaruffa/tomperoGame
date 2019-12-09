//
//  TrackWithIntro.swift
//  SoundWorkshop
//
//  Created by Vinícius Binder on 29/10/19.
//  Copyright © 2019 Vinícius Binder. All rights reserved.
//

import AVFoundation

class TrackWithIntro: Track, AVAudioPlayerDelegate {
    
    private var intro: AVAudioPlayer!
    
    init(introFileName: String, loopFileName: String, volume: Float) {
        super.init(fileName: loopFileName, volume: volume)
        self.intro = super.load(introFileName, volume)
        intro.numberOfLoops = 0
        intro.delegate = self
    }
    
    convenience init(introFileName: String, loopFileName: String) {
        self.init(introFileName: introFileName, loopFileName: loopFileName, volume: 1.0)
    }
    
    override func play() {
        intro.play()
    }
    
    override func stop() {
        intro.stop()
        intro.currentTime = 0
        super.stop()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        super.play()
    }
}
