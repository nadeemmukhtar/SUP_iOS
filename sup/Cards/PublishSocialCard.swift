//
//  PublishSocialCard.swift
//  sup
//
//  Created by Justin Spraggins on 6/5/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

private let supBaseURL = "https://listen.onsup.fyi/sups/"

struct PublishSocialCard: View {
    @ObservedObject var state: AppState
    @EnvironmentObject var audioPlayer: AudioPlayer
    let publishedSup: Sup
    @State var coverArtUrl: URL? = nil
    @State var mainStage = true
    @State var instagramFeedStage = false
    @State var shareStage = false
    @State var tikTokStage = false
    @State var feedStage = false
    @State var openTikTokStage = false
    @State var loadingStories = false
    @State var loadingFeed = false
    @State var loadingTikTok = false
    @State var loadingYouTube = false
    @State var cardState = CGSize.zero
    @State var tprogress: CGFloat? = 0
    @State var progress: CGFloat? = 0
    @State var value: Double = 0
    @State var startTime: Double = 0
    @State var endTime: Double = 0
    @State private var timer: Timer? = nil
    @State private var showingShare = false
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)

    let coverSize: CGFloat = 120
    let cardHeight: CGFloat = 410
    
    private func isPlayingClip() -> Bool {
        self.audioPlayer.playingURL == publishedSup.url && self.audioPlayer.isPlaying
    }

    func calculateValue() -> Double {
        let value = duration * self.value // To increase
        //let value = duration - (self.value * duration) // To decrease
        return value
    }

    private var duration: Double {
        AudioTime(duration: publishedSup.duration, audioPlayer: audioPlayer).call()
    }

    func moveToTikTokStage() {
        self.mainStage = false
        self.tikTokStage = true
        self.feedStage = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.shareStage = true
        }
    }

    func moveToFeedStage() {
        impact(style: .soft)
        self.mainStage = false
        self.feedStage = true
        self.tikTokStage = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.shareStage = true
        }
    }

    func backToMainStage() {
        impact(style: .soft)
        if !self.loadingTikTok || !self.loadingFeed {
            self.shareStage = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.mainStage = true
                self.tikTokStage = false
                self.feedStage = false
            }
        }
    }

    func shareToTikTok() {
        impact(style: .soft)
        self.state.photosPermissions { allowed in
            if allowed {
                DispatchQueue.main.async {
                    self.loadingTikTok = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.presentTikTok { _ in
                            DispatchQueue.main.async {
                                self.loadingTikTok = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    self.closeSocials()
                                }
                            }
                            
                            guard var coins = self.state.currentUser?.coins else { return }
                            coins = coins + 10
                            self.state.add(coins: coins) { _ in }
                        }
                    }
                }
            } else {
                self.state.promptForPhotoPermissions()
            }
        }
    }

    func openTikTok() {
        impact(style: .soft)
        guard let url = URL(string: "snssdk1233://") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.closeSocials()
        }
    }

    func shareToStories() {
        impact(style: .soft)
        self.state.photosPermissions { allowed in
            if allowed {
                DispatchQueue.main.async {
                    self.loadingStories = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.presentInstagramStories { _ in
                            DispatchQueue.main.async {
                                self.loadingStories = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    self.closeSocials()
                                }
                            }
                            
                            guard var coins = self.state.currentUser?.coins else { return }
                            coins = coins + 5
                            self.state.add(coins: coins) { _ in }
                        }
                    }
                }
            } else {
                self.state.promptForPhotoPermissions()
            }
        }
    }

    func shareToFeed() {
        impact(style: .soft)
        self.state.photosPermissions { allowed in
            if allowed {
                DispatchQueue.main.async {
                    self.loadingFeed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.presentInstagramFeed { _ in
                            DispatchQueue.main.async {
                                self.loadingFeed = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    self.closeSocials()
                                }
                            }
                        }
                    }
                }
            } else {
                self.state.promptForPhotoPermissions()
            }
        }
    }

    func shareToYouTube() {
        impact(style: .soft)
        self.state.photosPermissions { allowed in
            if allowed {
                DispatchQueue.main.async {
                    self.loadingYouTube = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.presentYoutube { _ in
                            DispatchQueue.main.async {
                                self.loadingYouTube = false
                                self.closeSocials()
                            }
                        }
                    }
                }
            } else {
                self.state.promptForPhotoPermissions()
            }
        }
    }

    func closeSocials() {
        if !self.loadingStories || !self.loadingTikTok || !self.loadingFeed  {
            self.state.showPublishSocials = false
        }
    }

    func pausePlayback() {
        self.timer?.invalidate()
        self.timer = nil

        self.startTime = 0
        self.endTime = 0

        self.tprogress = 0
        self.progress = 0

        self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in

            if self.tprogress! >= (self.feedStage || self.tikTokStage ? 60.0 : 15.0) {
                self.state.audioPlayer.pausePlayback()
                self.timer?.invalidate()
                self.timer = nil

                self.endTime = self.state.audioPlayer.audioPlayer?.currentTime ?? 0
            } else {
                self.tprogress! += 0.1
                self.progress = self.tprogress! / (self.feedStage || self.tikTokStage ? 60.0 : 15.0)
            }
        }

        self.startTime = self.state.audioPlayer.audioPlayer?.currentTime ?? 0
    }

    var body: some View {
        VStack {
            Spacer()
            VStack (spacing: 5) {
                ZStack {
                    Capsule().frame(width: 30, height: 8)
                        .foregroundColor(Color.white.opacity(0.1))
                    Capsule().frame(width: 30, height: 8)
                        .foregroundColor(Color.white)
                        .blendMode(.overlay)
                }
                .onTapGesture { self.closeSocials() }

                Spacer().frame(height: 15)

                ZStack {
                    VStack {
                        Spacer().frame(height: 15)
                        ZStack {
                            WebImage(url: coverArtUrl ?? publishedSup.coverArtUrl)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: coverSize, height: coverSize)
                                .background(Color(publishedSup.color.color()))
                                .clipShape(RoundedRectangle(cornerRadius: 17))

                            VStack {
                                Spacer()
                                HStack(spacing: -8) {
                                    WebImage(url: publishedSup.avatarUrl)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)
                                    ForEach(self.publishedSup.guestAvatars, id: \.self) { value in
                                        WebImage(url: URL(string: value))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)
                                    }
                                }
                                Spacer().frame(height: 10)
                            }
                            .frame(width: coverSize, height: coverSize)
                        }

                        Text("share to social")
                            .modifier(TextModifier(size: 18, font: Font.ttNormsBold, color: Color.white.opacity(0.8)))
                            .padding(.top, 5)

                        Spacer()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack (spacing: 10) {
                                ShareSocialsCell(image: "settings-tiktok",
                                                 text: "tiktok",
                                                 isLoading: $loadingTikTok,
                                                 action: { self.moveToTikTokStage() })
                                ShareSocialsCell(image: "settings-instagram",
                                                 text: "instagram",
                                                 isLoading: .constant(false),
                                                 action: { self.moveToFeedStage()})
                                ShareSocialsCell(image: "instagram-stories",
                                                 text: "stories",
                                                 isLoading: $loadingStories,
                                                 action: { self.shareToStories() })
//                                ShareSocialsCell(image: "share-youtube",
//                                                 text: "youtube",
//                                                 isLoading: $loadingYouTube,
//                                                 action: { self.shareToStories() })
                                ShareSocialsCell(image: "share-snapchat",
                                                 text: "snapchat",
                                                 isLoading: .constant(false),
                                                 action: { self.presentSnapchat() })
                                ShareSocialsCell(image: "settings-twitter",
                                                 text: "twitter",
                                                 isLoading: .constant(false),
                                                 action: { self.showingShare = true })
                                    .sheet(isPresented: self.$showingShare) {
                                        ShareSheet(activityItems: ["tap the link to listen to this sup 🎧 \(supBaseURL)\(self.publishedSup.id)"])
                                }
                            }
                            .padding(.horizontal, 25)
                        }
                        .frame(height: 120)
                    }
                    .offset(y: self.mainStage ? 0 : 540)
                    .animation(Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0).speed(0.9))

                    VStack {
                        Spacer().frame(height: 15)
                        Text("select your 1min clip")
                            .modifier(TextModifier(size: 22))
                            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 0)
                        Spacer().frame(height: 70)
                        VStack {
                            HighlightPlayBar(
                                state: state,
                                progress: $progress,
                                value: $value,
                                isPlaying: isPlayingClip(),
                                duration: duration,
                                width: screenWidth - 44,
                                sup: publishedSup,
                                onPlay: { sup in
                                    DispatchQueue.main.async {
                                        self.state.audioPlayer.startPlayback(
                                            audio: sup.url,
                                            sup: sup,
                                            atTime: self.value * self.duration)
                                    }
                            },
                                onPause: { sup in
                                    self.state.audioPlayer.pausePlayback()
                            })
                            HStack {
                                Button(action: {}) {
                                    ZStack {
                                        Text(calculateValue().toTime)
                                            .modifier(TextModifier(size: 16, color: Color.white.opacity(0.1)))
                                            .animation(nil)
                                        Text(calculateValue().toTime)
                                            .modifier(TextModifier(size: 16, color: .white))
                                            .blendMode(.overlay)
                                            .animation(nil)
                                    }
                                    Spacer()
                                    ZStack {
                                        Text(duration.toTime)
                                            .modifier(TextModifier(size: 16, color: Color.white.opacity(0.1)))
                                        Text(duration.toTime)
                                            .modifier(TextModifier(size: 16, color: .white))
                                            .blendMode(.overlay)
                                    }
                                }
                                .disabled(true)
                            }
                            .padding(.top, 4)
                            .frame(width: screenWidth - 44)
                        }

                        Spacer()
                        Button(action: {
                            if self.tikTokStage {
                                self.shareToTikTok()
                            } else if self.feedStage {
                                self.shareToFeed()
                            }
                        }) {
                            HStack (spacing: 15) {
                                ZStack {
                                    Spacer().frame(width: 30, height: 30)
                                    if self.loadingTikTok || self.loadingFeed  {
                                        LoaderCircle(size: 20, innerSize: 20, isButton: true)
                                    } else {
                                        Image(tikTokStage ? "card-tiktok" : "instagram-feed")
                                            .renderingMode(.template)
                                            .foregroundColor(.white)
                                    }
                                }
                                Text(tikTokStage && !loadingTikTok ? "share to TikTok" : feedStage && !loadingFeed ? "share to feed" : "exporting...")
                                    .modifier(TextModifier(size: 18))
                            }
                            .padding(.horizontal, 25)
                            .frame(height: 58)
                            .background(
                                BackgroundBlurView(style: .prominent).clipShape(RoundedRectangle(cornerRadius: 25))
                            )
                        }
                        .buttonStyle(ButtonBounceLight())
                    }
                    .offset(y: shareStage ? 0 : 540)
                    .animation(.spring())
                }
            }
            .padding(.top, 12)
            .padding(.bottom, isIPhoneX ? 70 : 50)
            .frame(width: screenWidth, height: cardHeight)
            .background(
                BackgroundBlurView(style: .systemUltraThinMaterialLight)
                    .frame(width: screenWidth, height: cardHeight)
                    .cornerRadius(radius: isIPhoneX ? 30 : 18, corners: [.topLeft, .topRight])
            )
                .offset(y: self.cardState.height)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            self.cardState = value.translation
                            if self.cardState.height < -5 {
                                self.cardState = CGSize.zero
                            }
                    }
                    .onEnded { value in
                        if self.cardState.height > 10 {
                            self.self.closeSocials()
                            self.cardState = CGSize.zero
                        } else {
                            self.cardState = CGSize(width: 0, height: 0)
                        }
                })
        }
        .transition(.move(edge: .bottom))
        .animation(.spring())
        .onReceive(self.state.audioPlayer.playingSupWillChange.eraseToAnyPublisher()) { isPlayingSup in
            if !isPlayingSup {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.pausePlayback()
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.coverArtUrl = self.publishedSup.coverArtUrl
            }
        }
    }
}

extension PublishSocialCard {
    private func presentSnapchat() {
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        let url = "\(supBaseURL)\(self.publishedSup.id)"
        SocialManager.sharedManager.postToSnapchat(sup: publishedSup, url: url, vc: vc)
    }

    private func presentInstagramStories(completion: @escaping (Bool) -> Void) {
        let startTime = self.startTime
        let endTime = self.endTime != 0.0 ? self.endTime :
            (self.startTime + 60.0) > self.duration ? self.duration : self.startTime + 60.0
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postToInstagramStoriesImage(sup: publishedSup, startTime: startTime, endTime: endTime, vc: vc, completion: completion)
    }

    private func presentInstagramFeed(completion: @escaping (Bool) -> Void) {
        let startTime = self.startTime
        let endTime = self.endTime != 0.0 ? self.endTime :
            (self.startTime + (60.0)) > self.duration ? self.duration : self.startTime + (60.0)
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postToInstagramFeedVideo(sup: publishedSup, startTime: startTime, endTime: endTime, vc: vc, completion: completion)
    }

    private func presentTikTok(completion: @escaping (Bool) -> Void) {
        let startTime = self.startTime
        let endTime = self.endTime != 0.0 ? self.endTime :
            (self.startTime + (60.0)) > self.duration ? self.duration : self.startTime + (60.0)
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postToTikTok(sup: publishedSup, startTime: startTime, endTime: endTime, vc: vc, completion: completion)
    }
    
    private func presentYoutube(completion: @escaping (Bool) -> Void) {
        let startTime = 0.0
        let endTime = duration
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postToYoutube(sup: publishedSup, startTime: startTime, endTime: endTime, vc: vc, completion: completion)
    }
}

struct ShareSocialsCell: View {
    var image: String
    var width: CGFloat = 70
    var height: CGFloat = 70
    var corner: CGFloat = 35
    var text: String
    @Binding var isLoading: Bool
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            VStack {
                ZStack {
                    Color.black.opacity(0.3)
                        .frame(width: width, height: height, alignment: .center)
                        .clipShape(Circle())

                    ZStack {
                        Image(image)
                            .renderingMode(.template)
                            .foregroundColor(Color.white)
                            .opacity(isLoading ? 0 : 1)
                    }
                    if isLoading {
                        LoaderCircle(isButton: true, tint: .white)
                    }
                }
                ZStack {
                    Text(text)
                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white.opacity(0.1)))
                    Text(text)
                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white))
                        .blendMode(.overlay)
                }
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 0)
            }
        }
        .buttonStyle(ButtonBounceLight())
    }
}
