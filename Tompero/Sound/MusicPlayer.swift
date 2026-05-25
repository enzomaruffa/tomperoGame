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

    /// Set to true once `AVAudioSession.setActive(true)` returns. `play()` is
    /// a no-op until then so we don't drive audio into an inactive session.
    private var audioSessionReady = false

    /// If `play(...)` is invoked before the audio session is ready, remember
    /// the requested track here and start it as soon as activation completes.
    private var pendingTrack: TrackNumber?

    private init() {
        score[.menu] = Track(fileName: "menuMusicAmbiance.wav")
        score[.game] = TrackWithIntro(introFileName: "gameMusicIntro.m4a", loopFileName: "gameMusic.m4a")
    }

    func play(_ trackToPlay: TrackNumber) {
        guard musicOn else { return }
        guard audioSessionReady else {
            pendingTrack = trackToPlay
            return
        }

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
        // The UserDefaults reads are trivial and stay on main so anything
        // observing `musicOn` / `soundOn` (e.g. SettingsView's @Published
        // mirror) sees the persisted state on the first frame.
        if UserDefaults.standard.object(forKey: "musicOn") != nil {
            musicOn = UserDefaults.standard.bool(forKey: "musicOn")
        } else {
            musicOn = true
        }

        if UserDefaults.standard.object(forKey: "soundOn") != nil {
            soundOn = UserDefaults.standard.bool(forKey: "soundOn")
        } else {
            soundOn = true
        }

        // setCategory + setActive(true) can block the main thread for 1–3s on
        // first call (the audio HAL warms up). Run them on a background queue
        // and flush any pending play() request once activation completes.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            Log.game.info("LAUNCH +\(AppDelegate.elapsed())s AVAudioSession.activate start")
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                Log.game.error("AVAudioSession activation failed: \(error.localizedDescription, privacy: .public)")
            }
            Log.game.info("LAUNCH +\(AppDelegate.elapsed())s AVAudioSession.activate done")

            DispatchQueue.main.async {
                guard let self else { return }
                self.audioSessionReady = true
                if let pending = self.pendingTrack {
                    self.pendingTrack = nil
                    self.play(pending)
                }
            }
        }
    }
}

enum TrackNumber {
    case menu
    case game
}
