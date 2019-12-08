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
    
    init(introFileName: String, loopFileName: String) {
        super.init(fileName: loopFileName)
        self.intro = super.load(introFileName)
        intro.numberOfLoops = 0
        intro.delegate = self
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

