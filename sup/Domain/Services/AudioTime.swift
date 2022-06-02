//
//  AudioTime.swift
//  sup
//
//  Created by Robert Malko on 6/4/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation

class AudioTime {
    let duration: Double
    let audioPlayer: AudioPlayer

    init(duration: Double, audioPlayer: AudioPlayer) {
        self.duration = duration
        self.audioPlayer = audioPlayer
    }

    func call() -> Double {
        if duration > 0 { return duration }

        return audioPlayer.audioPlayer?.duration ?? 0.0
    }
}
