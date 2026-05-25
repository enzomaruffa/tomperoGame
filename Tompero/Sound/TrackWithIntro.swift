//
//  TrackWithIntro.swift
//  SoundWorkshop
//
//  Created by Vinícius Binder on 29/10/19.
//  Copyright © 2019 Vinícius Binder. All rights reserved.
//

import AVFoundation

class TrackWithIntro: Track, AVAudioPlayerDelegate {

    private let introFileName: String
    private let introVolume: Float
    private var intro: AVAudioPlayer?

    init(introFileName: String, loopFileName: String, volume: Float = 1.0) {
        self.introFileName = introFileName
        self.introVolume = volume
        super.init(fileName: loopFileName, volume: volume)
    }

    private func ensureIntro() -> AVAudioPlayer {
        if let intro { return intro }
        let p = load(introFileName, introVolume)
        p.numberOfLoops = 0
        p.delegate = self
        intro = p
        return p
    }

    override func play() {
        ensureIntro().play()
    }

    override func stop() {
        intro?.stop()
        intro?.currentTime = 0
        super.stop()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        super.play()
    }
}
