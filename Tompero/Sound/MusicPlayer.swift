//
//  MusicPlayer.swift
//  SoundWorkshop
//
//  Created by Vinícius Binder on 29/10/19.
//  Copyright © 2019 Vinícius Binder. All rights reserved.
//

import AVFoundation

class MusicPlayer {
    
    static var shared = MusicPlayer()
    
    private var score = [TrackNumber: Track]()
    
    private init() {
        score[.menu] = Track(fileName: "menuMusic.mp3")
        score[.game] = TrackWithIntro(introFileName: "gameMusicIntro.wav", loopFileName: "gameMusic.wav")
    }
    
    func play(_ trackToPlay: TrackNumber) {
        for (trackNumber, track) in score {
            if trackNumber == trackToPlay {
                track.play()
            } else {
                track.stop()
            }
        }
    }
    
    func stop(_ trackToPlay: TrackNumber) {
        for (trackNumber, track) in score {
            if trackNumber != trackToPlay {
                track.play()
            } else {
                track.stop()
            }
        }
    }
}

enum TrackNumber {
    case menu
    case game
}
