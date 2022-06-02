//
//  AudioPlayer.swift
//  sup
//
//  Created by Robert Malko on 1/4/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import MediaPlayer
import AVFoundation
import OneSignal

class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var state: AppState {
        return AppDelegate.appState!
    }
    
    override init() {
        super.init()
    }

    deinit {
        stopSecondsPlayed()
        timer?.invalidate()
    }

    let objectWillChange = PassthroughSubject<AudioPlayer, Never>()
    let playingSupWillChange = PassthroughSubject<Bool, Never>()
    let progressWillChange = PassthroughSubject<Double, Never>()
    let finishWillChange = PassthroughSubject<Bool, Never>()
    let completeWillChange = PassthroughSubject<Bool, Never>()
    let indexWillChange = PassthroughSubject<Int, Never>()

    var audioPlayer: AVAudioPlayer?
    var playingURL: URL?
    var selectedSup: Sup?

    var currentPlayingSupIndex = 0 {
        didSet {
            indexWillChange.send(currentPlayingSupIndex)
        }
    }
    var isFinished = false {
        didSet {
            finishWillChange.send(isFinished)
        }
    }
    var isComplete = false {
        didSet {
            completeWillChange.send(isComplete)
        }
    }
    var isPaused = false {
        didSet {
            objectWillChange.send(self)
        }
    }
    var isPlaying = false {
        didSet {
            objectWillChange.send(self)
        }
    }
    var playingSup = false {
        didSet {
            playingSupWillChange.send(playingSup)
        }
    }
    var progress = 0.0 {
        didSet {
            progressWillChange.send(progress)
        }
    }

    private var cancellables: Set<AnyCancellable> = []
    private var clipsToPlay = [SoundClip]()
    private var lastPlayedSup: Sup?
    private var numberOfSups = 0
    private var secondsPlayed = 0
    private var timer: CADisplayLink?

    func playAppSound(resource: String, of type: String) {
        if let player = self.audioPlayer {
            player.stop()
        }

        do {
            if let fileURL = Bundle.main.path(forResource: resource, ofType: type) {
                let myPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: fileURL))
                myPlayer.volume = 0.1
                myPlayer.play()

                self.audioPlayer = myPlayer
            } else {
                Logger.log("No file with specified name exists", log: .debug, type: .error)
            }
        } catch let error {
            Logger.log("Can't play the audio file: %{public}@", log: .debug, type: .error, error.localizedDescription)
        }
    }

    func playRingTone(resource: String, of type: String) {
        if let player = self.audioPlayer {
            player.stop()
        }

        do {
            if let fileURL = Bundle.main.path(forResource: resource, ofType: type) {
                let myPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: fileURL))
                myPlayer.numberOfLoops = -1
                myPlayer.play()

                self.audioPlayer = myPlayer
            } else {
                Logger.log("No file with specified name exists", log: .debug, type: .error)
            }
        } catch let error {
            Logger.log("Can't play the audio file failed with an error: %{public}@", log: .debug, type: .error, error.localizedDescription)
        }
    }

    func stopRingTone() {
        guard let player = self.audioPlayer else { return }
        player.stop()
    }

    func startPlayback(audio: URL, loadingURL: Binding<URL?>, sup: Sup? = nil) {
        loadingURL.wrappedValue = audio
        DispatchQueue.global(qos: .background).async {
            self.startPlayback(audio: audio, sup: sup)
            DispatchQueue.main.async {
                loadingURL.wrappedValue = nil
            }
        }
    }

    func startPlayback(audio: URL, sup: Sup? = nil, atTime: Double? = nil) {
        DispatchQueue.main.async {
            self.playingSup = false
            self.isFinished = false
            self.isComplete = false
        }

        do {
            try self.playURL(audio: audio, sup: sup, atTime: atTime)
            DispatchQueue.main.async {
                self.stopSecondsPlayed()
                self.timer = CADisplayLink(target: self, selector: #selector(self.trackAudio))
                DispatchQueue.main.schedule(after: .init(.now()), interval: 1) {
                    self.secondsPlayed += 1
                }.store(in: &self.cancellables)
                self.timer?.preferredFramesPerSecond = 60
                self.timer?.add(to: .current, forMode: .common)
            }
        } catch {
            Logger.log("Playback failed", log: .debug, type: .error)
        }
    }

    func playURL(audio: URL, sup: Sup? = nil, atTime: Double? = nil) throws {
        DispatchQueue.main.async {
            self.setupNowPlayingInfoCenter()
        }
        
        let playbackSession = AVAudioSession.sharedInstance()

        /// NOTE: Play even in silent mode
        do {
            try playbackSession.setCategory(.playback, options: [])
            try playbackSession.setActive(true)
        } catch {
            Logger.log("Updating playbackSession failed", log: .debug, type: .error)
        }

        let isPausedAudio = audio == playingURL
        DispatchQueue.main.async {
            self.selectedSup = sup
        }

        if !isPaused || !isPausedAudio {
            if audio.absoluteString.starts(with: "http") {
                let data = try Data(contentsOf: audio)
                self.audioPlayer = try AVAudioPlayer(data: data)
            } else {
                audioPlayer = try AVAudioPlayer(contentsOf: audio)
            }
            audioPlayer?.delegate = self
        }

        DispatchQueue.main.async {
            self.playingURL = audio
            self.startPlayback(sup: sup, atTime: atTime)
        }
    }
    
    func startPlayback(sup: Sup? = nil, atTime: Double? = nil) {
        if atTime != nil {
            audioPlayer?.currentTime = atTime!
        }
        if sup != nil {
            self.lastPlayedSup = sup
            SupAnalytics.playSup(sup: sup!)
        }
        audioPlayer?.play()
        isPaused = false
        isPlaying = true

        DispatchQueue.main.async {
            self.updateNowPlayingInfoCenter(sup: sup)
        }
        
        if atTime == nil {
            if let sup = sup {
                DispatchQueue.global(qos: .background).async {
                    self.state.saveComment(sup: sup, type: "listen") { _ in
                        User.get(userID: sup.userID) { user in
                            if let user = user {
                                self.sendPush(user: user, sup: sup)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func sendPush(user: User, sup: Sup) {
        guard let username = self.state.currentUser?.username else { return }
        var playerIds = [String]()
        playerIds.append(user.oneSignalPlayerId ?? "")
        OneSignal.postNotification(
            ["contents": ["en": "\(username) listened to: \(sup.description)"],
             "include_player_ids": playerIds])
    }

    func stopPlayback() {
        audioPlayer?.stop()
        playingURL = nil
        isPaused = false
        isPlaying = false
        progress = 0.0
        isFinished = true
        stopSecondsPlayed()
        timer?.invalidate()
    }

    func pausePlayback() {
        audioPlayer?.pause()
        isPaused = true
        isPlaying = false
        isFinished = true
        stopSecondsPlayed()
        timer?.invalidate()
    }

    func audioLength(audio: URL) -> Double {
        let asset = AVURLAsset(url: audio)
        return Double(CMTimeGetSeconds(asset.duration))
    }

    @objc func trackAudio() {
        guard let currentTime = audioPlayer?.currentTime,
            let duration = audioPlayer?.duration else { return }

        progress = currentTime / duration
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            playingURL = nil
            isPaused = false
            isPlaying = false
            progress = 0.0
            isFinished = true
            isComplete = true

            currentPlayingSupIndex += 1
            if playingSup {
                playingSup = false
            }
        }

        if !playingSup {
            stopSecondsPlayed()
            timer?.invalidate()
        }
    }
    
    private func setupNowPlayingInfoCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents();
        MPRemoteCommandCenter.shared().playCommand.addTarget {event in
            self.startPlayback(sup: self.selectedSup)
            return .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.addTarget {event in
            self.pausePlayback()
            return .success
        }
    }
    
    private func updateNowPlayingInfoCenter(sup: Sup? = nil) {
        if let sup = sup {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyTitle: sup.username,
                MPMediaItemPropertyAlbumTitle: sup.description,
                //MPMediaItemPropertyArtist: sup.username,
                MPMediaItemPropertyPlaybackDuration: audioPlayer!.duration,
                MPNowPlayingInfoPropertyElapsedPlaybackTime: audioPlayer!.duration * self.progress
            ]
            
            let coverData = try? Data(contentsOf: sup.coverArtUrl)
            if coverData == nil { return }
            guard let coverImage = UIImage(data: coverData!) else { return }
            
            let image = aspectFill(image: coverImage)

            let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {  (_) -> UIImage in
                return image
            })
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyPlaybackDuration: audioPlayer!.duration,
                MPNowPlayingInfoPropertyElapsedPlaybackTime: audioPlayer!.duration * self.progress
            ]
        }
    }
    
    func aspectFill(image:UIImage) -> UIImage {
        let imgView = UIImageView(frame: CGRect(width: image.size.width, height: image.size.width))
        imgView.image = image
        imgView.contentMode = .scaleAspectFill
        
        UIGraphicsBeginImageContext(imgView.bounds.size)
        imgView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img ?? image
    }

    private func stopSecondsPlayed() {
        self.cancellables.forEach({ $0.cancel() })
        self.cancellables = []
        SupAnalytics.secondsPlayed(
            seconds: self.secondsPlayed,
            sup: self.lastPlayedSup
        )
        self.secondsPlayed = 0
    }
}
