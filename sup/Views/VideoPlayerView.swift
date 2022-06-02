//
//  VideoPlayerView.swift
//  sup
//
//  Created by Justin Spraggins on 2/3/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import UIKit
import AVFoundation

class PlayerUIView: UIView {
    var looper: AVPlayerLooper?
    let name: String = ""

    private let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let path = Bundle.main.path(forResource: "nosups", ofType: "mp4")!
        let url = URL(fileURLWithPath: path)
        let player = AVQueuePlayer()
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(asset: AVAsset(url: url)))
        player.play()

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct PlayerView: UIViewRepresentable {
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {}

    func makeUIView(context: Context) -> UIView {
        return PlayerUIView(frame: .zero)
    }
}

class PlayerSplashUIView: UIView {
    var looper: AVPlayerLooper?

    private let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let path = Bundle.main.path(forResource: "splash-video", ofType: "mp4")!
        let url = URL(fileURLWithPath: path)
        let player = AVQueuePlayer()
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(asset: AVAsset(url: url)))
        player.play()

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct PlayerSplashView: UIViewRepresentable {
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerSplashView>) {
    }

    func makeUIView(context: Context) -> UIView {
        return PlayerSplashUIView(frame: .zero)
    }
}

class PlayerGuestPassUIView: UIView {
    var looper: AVPlayerLooper?

    private let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let path = Bundle.main.path(forResource: "guestPass-video", ofType: "mp4")!
        let url = URL(fileURLWithPath: path)
        let player = AVQueuePlayer()
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(asset: AVAsset(url: url)))
        player.play()

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct PlayerGuestPassView: UIViewRepresentable {
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerGuestPassView>) {
    }

    func makeUIView(context: Context) -> UIView {
        return PlayerGuestPassUIView(frame: .zero)
    }
}

class PlayerSigninUIView: UIView {
    private let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let path = Bundle.main.path(forResource: "signIn-video", ofType: "mp4")!
        let url = URL(fileURLWithPath: path)
        let player = AVPlayer(url: url)
        player.play()

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct PlayerSigninView: UIViewRepresentable {
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerSigninView>) {
    }

    func makeUIView(context: Context) -> UIView {
        return PlayerSigninUIView(frame: .zero)
    }
}

class PlayerHappyHourUIView: UIView {
    private let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let path = Bundle.main.path(forResource: "happy-hour", ofType: "mp4")!
        let url = URL(fileURLWithPath: path)
        let player = AVPlayer(url: url)
        player.play()

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct PlayerHappyHourView: UIViewRepresentable {
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerHappyHourView>) {
    }

    func makeUIView(context: Context) -> UIView {
        return PlayerHappyHourUIView(frame: .zero)
    }
}
