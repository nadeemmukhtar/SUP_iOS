//
//  AudioManager.swift
//  sup
//
//  Created by Robert Malko on 5/31/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation
import AudioKit

class AudioManager {
    var mixer: AKMixer!

    init() {
        mixer = AKMixer()
        self.setAudioSettings()
    }

    func enhance(audioURL: URL, callback: @escaping (URL) -> Void) {
        do {
            let file = try AKAudioFile(forReading: audioURL)
            let normalizedFile = try file.normalized(newMaxLevel: -6.0)
            let player = AKPlayer(audioFile: normalizedFile)
            let eq = addEq(node: player)
            let stereoWidener = addWidening(node: eq, player: player)
            let reverb = addReverb(node: stereoWidener)
            let limiter = addLimiter(node: reverb)
            AudioKit.output = limiter

            DispatchQueue.global().async {
                do {
                    let enhancedPath = audioURL.absoluteString.replacingOccurrences(of: ".mp4", with: "_enhanced.mp4")
                    guard let filename = URL(string: enhancedPath) else { return callback(audioURL) }

                    let settings: [String: Any] = [
                        AVSampleRateKey: 48000.0,
                        AVNumberOfChannelsKey: 1,
                        AVFormatIDKey: kAudioFormatMPEG4AAC
                    ]
                    let outputFile = try AKAudioFile(forWriting: filename, settings: settings)
                    try AudioKit.renderToFile(outputFile, duration: file.duration, prerender: {
                        self.start(player: player) {
                            self.stop()
                            callback(filename)
                        }
                    })
                } catch let exportError {
                    print("exportError", exportError)
                    callback(audioURL)
                }
            }
        } catch let error {
            print("AudioManager#enhance error", error)
            callback(audioURL)
        }
    }

    func start(player: AKPlayer, callback: @escaping () -> Void) {
        do {
            player.completionHandler = { callback() }
            player.isLooping = false
            try AudioKit.start()
            player.play()
        } catch let error {
            print("AudioManager#start error", error)
        }
    }

    func stop() {
        do {
            AudioKit.disconnectAllInputs()
            try AudioKit.stop()
        } catch let error {
            print("AudioManager#stop error", error)
        }
    }

    private func addLimiter(node: AKNode) -> AKNode {
        let peakLimiter = AKPeakLimiter(node, attackDuration: 0.02, decayDuration: 0.04, preGain: 0.0)

        return peakLimiter
    }

    private func addEq(node: AKNode) -> AKNode {
        let lowCut = AKHighPassButterworthFilter(node, cutoffFrequency: 250)
        let highAtten = AKEqualizerFilter(lowCut, centerFrequency: 6000, bandwidth: 2000, gain: 0.3)
        let midBoost = AKEqualizerFilter(highAtten, centerFrequency: 3500, bandwidth: 1000, gain: 2.0)
        let midAtten = AKEqualizerFilter(midBoost, centerFrequency: 1200, bandwidth: 400, gain: 0.7)

        return midAtten
    }

    private func addReverb(node: AKNode) -> AKNode {
        let reverb = AKReverb(node, dryWetMix: 0.15)
        reverb.loadFactoryPreset(.smallRoom)

        return reverb
    }

    private func addWidening(node: AKNode, player: AKNode) -> AKNode {
        let stereoAmount = 0.8
        let compressed = AKCompressor(node, threshold: -16, headRoom: -40, attackDuration: 0.2, releaseDuration: 1.0, masterGain: -2.0)
        let noLowDelay = AKHighPassButterworthFilter(player, cutoffFrequency: 800)
        let delayLeft = AKDelay(noLowDelay, time: 0.005, feedback: 0.0, dryWetMix: 1.0)
        let delayRight = AKDelay(noLowDelay, time: 0.015, feedback: 0.0, dryWetMix: 1.0)
        let leftBooster = AKBooster(delayLeft, gain: stereoAmount)
        let rightBooster = AKBooster(delayRight, gain: stereoAmount)
        let mixed = AKMixer(leftBooster, rightBooster, compressed)

        return mixed
    }

    private func setAudioSettings() {
        AKSettings.channelCount = 1
        AKSettings.sampleRate = 48000
    }
}
