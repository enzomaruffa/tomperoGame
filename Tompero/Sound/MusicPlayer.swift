//
//  MusicPlayer.swift
//  SoundWorkshop
//
//  Created by Vinícius Binder on 29/10/19.
//  Copyright © 2019 Vinícius Binder. All rights reserved.
//

import AVFoundation

class MusicPlayer {
    
    var musicOn = true {
        didSet {
            MusicPlayer.shared.saveData()
        }
    }
    
    var soundOn = true {
        didSet {
            MusicPlayer.shared.saveData()
        }
    }
    
    static var shared = MusicPlayer()
    
    private var score = [TrackNumber: Track]()
    
    private init() {
        score[.menu] = Track(fileName: "menuMusicAmbiance.wav")
        score[.game] = TrackWithIntro(introFileName: "gameMusicIntro.m4a", loopFileName: "gameMusic.m4a")
    }
    
    func play(_ trackToPlay: TrackNumber) {
        guard musicOn else { return }
        
        for (trackNumber, track) in score {
            if trackNumber == trackToPlay {
                track.play()
            } else {
                track.stop()
            }
        }
    }
    
    func stop(_ trackToStop: TrackNumber) {
        if let track = score[trackToStop] {
            track.stop()
        }
    }
    
    func stopAll() {
        for (_, track) in score {
            track.stop()
        }
    }
    
    func saveData() {
        UserDefaults.standard.set(musicOn, forKey: "musicOn")
        UserDefaults.standard.set(soundOn, forKey: "soundOn")
    }
    
    func loadData() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error: Could not start audio session.")
        }
        
        if let _ = UserDefaults.standard.object(forKey: "musicOn") {
            musicOn = UserDefaults.standard.bool(forKey: "musicOn")
        } else {
            musicOn = true
        }
        
        if let _ = UserDefaults.standard.object(forKey: "soundOn") {
            soundOn = UserDefaults.standard.bool(forKey: "soundOn")
        } else {
            soundOn = true
        }
    }
}

enum TrackNumber {
    case menu
    case game
}
