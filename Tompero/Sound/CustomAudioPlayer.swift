//
//  CustomAudioPlayer.swift
//  SoundWorkshop
//
//  Created by Vinícius Binder on 29/10/19.
//  Copyright © 2019 Vinícius Binder. All rights reserved.
//
//  Lazily-loaded SFX wrapper. Construction only captures the file URL and
//  volume; the AVAudioPlayer is materialized on first `play()` so 14 SFX
//  files don't all decode synchronously the moment `SFXPlayer.shared` is
//  first touched.
//

import AVFoundation

class CustomAudioPlayer {

    private let url: URL?
    private var players = [AVAudioPlayer]()

    var volume: Float = 1.0

    init(fileName: String, volume: Float = 1.0) {
        if let path = Bundle.main.path(forResource: fileName, ofType: nil) {
            self.url = URL(fileURLWithPath: path)
        } else {
            self.url = nil
        }
        self.volume = volume
    }

    @discardableResult
    fileprivate func load() -> AVAudioPlayer? {
        guard let url else { return nil }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            players.append(player)
            return player
        } catch {
            return nil
        }
    }

    func play() {
        guard MusicPlayer.shared.soundOn else { return }

        DispatchQueue.global(qos: .background).async {
            for player in self.players where !player.isPlaying {
                player.play()
                return
            }

            self.load()?.play()
        }
    }
}
