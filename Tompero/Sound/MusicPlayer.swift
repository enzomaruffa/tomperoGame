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
        score[.dance] = Track(fileName: "dance-elevation.mp3")
        score[.club] = Track(fileName: "night-at-the-club.mp3")
        score[.intro] = TrackWithIntro(introFileName: "intro.mp3", loopFileName: "loop.mp3")
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
}

enum TrackNumber {
    case dance
    case club
    case intro
}
