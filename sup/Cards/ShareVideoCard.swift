//
//  ShareVideoCard.swift
//  sup
//
//  Created by Justin Spraggins on 5/27/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct ShareVideoCard: View {
    @ObservedObject var state: AppState
    @EnvironmentObject var audioPlayer: AudioPlayer
    @State var cardState = CGSize.zero
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    @State private var loadingStories = false
    @State private var loadingFeed = false
    @State private var loadingTikTok = false
    @Binding var mainStage: Bool
    @Binding var shareStage: Bool
    @Binding var tikTokStage: Bool
    @State private var openTikTokStage = false
    @State private var storiesStage = false
    @State private var feedStage = false
    @State private var timer: Timer? = nil
    @State private var storiesAlert = false
    @State var showTikTokAlert = false
    @State var tprogress: CGFloat? = 0
    @State var progress: CGFloat? = 0
    @State var value: Double = 0
    @State var startTime: Double = 0
    @State var endTime: Double = 0
    let sup: Sup
    let pColor: Color = Color.white
    let cardHeight: CGFloat = isIPhoneX ? 408 : 398
    var onClose: (() -> Void)? = nil

    private func isPlayingClip() -> Bool {
        self.audioPlayer.playingURL == sup.url && self.audioPlayer.isPlaying
    }

    func shareToTikTok() {
        SupAnalytics.shareTiktok()
        impact(style: .soft)
        self.state.photosPermissions { allowed in
            if allowed {
                DispatchQueue.main.async {
                    self.loadingTikTok = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.presentTikTok { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self.loadingTikTok = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    self.close()
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
                                    self.close()
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
                                    self.close()
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

    func moveToTikTokStage() {
        self.mainStage = false
        self.tikTokStage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.shareStage = true
        }
    }

    func moveToFeedStage() {
        impact(style: .soft)
        self.mainStage = false
        self.feedStage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.shareStage = true
        }
    }

    func moveToStoriesStage() {
        impact(style: .soft)
        self.mainStage = false
        self.storiesStage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.shareStage = true
        }
    }

    private var shareStories: Bool {
        shareStage && storiesStage
    }

    private var shareFeed: Bool {
        shareStage && feedStage
    }

    private var isLoading: Bool {
        self.loadingFeed || self.loadingStories || self.loadingTikTok
    }

    func calculateValue() -> Double {
        let value = duration * self.value // To increase
        //let value = duration - (self.value * duration) // To decrease
        return value
    }

    func close() {
        if !isLoading {
            self.onClose?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.mainStage = true
                self.shareStage = false
                self.feedStage = false
                self.storiesStage = false
                self.openTikTokStage = false
                self.tikTokStage = false
            }
        }
    }

    private var duration: Double {
        AudioTime(duration: sup.duration, audioPlayer: audioPlayer).call()
    }

    var body: some View {
        VStack {
           Spacer()
            VStack (spacing: 10) {
                ZStack {
                    Capsule().frame(width: 30, height: 8)
                        .foregroundColor(Color.white.opacity(0.1))
                    Capsule().frame(width: 30, height: 8)
                        .foregroundColor(Color.white)
                }
                .onTapGesture { self.close() }

                Spacer()

                ZStack {
                    VStack (spacing: 10) {
                        Spacer()
                        Button(action: { self.moveToTikTokStage() }) {
                            HStack (spacing: 18) {
                                ZStack {
                                    Circle()
                                        .foregroundColor(Color.white.opacity(0.1))
                                        .frame(width: 54, height: 54)

                                    Image("card-tiktok")
                                        .renderingMode(.template)
                                        .foregroundColor(.white)
                                }

                                VStack (alignment: .leading, spacing: -4) {
                                    Text("Tiktok")
                                        .modifier(TextModifier(size: 20, font: Font.textaAltBold, color: Color.white))
                                    Text("1 min video")
                                        .modifier(TextModifier(size: 18, font: Font.textaAltBold, color: Color.white.opacity(0.6)))
                                }
                                Spacer()

                            }
                            .padding(.leading, 18)
                            .padding(.trailing, 20)
                            .frame(width: screenWidth - 30, height: 78)
                            .background(BackgroundBlurView(style: .prominent).clipShape(RoundedRectangle(cornerRadius: 23)))
                        }
                        .buttonStyle(ButtonBounceLight())

                        Button(action: { self.moveToFeedStage() }) {
                            HStack (spacing: 18) {
                                ZStack {
                                    Circle()
                                        .foregroundColor(Color.white.opacity(0.1))
                                        .frame(width: 54, height: 54)

                                    Image("instagram-feed")
                                        .renderingMode(.template)
                                        .foregroundColor(.white)
                                }

                                VStack (alignment: .leading, spacing: -4) {
                                    Text("Instagram feed")
                                        .modifier(TextModifier(size: 20, font: Font.textaAltBold, color: Color.white))
                                    Text("1 min video")
                                        .modifier(TextModifier(size: 18, font: Font.textaAltBold, color: Color.white.opacity(0.6)))
                                }
                                Spacer()
                            }
                            .padding(.leading, 18)
                            .padding(.trailing, 20)
                            .frame(width: screenWidth - 30, height: 78)
                            .background(BackgroundBlurView(style: .prominent).clipShape(RoundedRectangle(cornerRadius: 23)))
                        }
                        .buttonStyle(ButtonBounceLight())

                        Button(action: { self.shareToStories() }) {
                            HStack (spacing: 18) {
                                ZStack {
                                    Circle()
                                        .foregroundColor(Color.white.opacity(0.1))
                                        .frame(width: 54, height: 54)
                                    Image("instagram-stories")
                                        .renderingMode(.template)
                                        .foregroundColor(.white)
                                        .opacity(isLoading ? 0 : 1)
                                        .animation(.easeInOut(duration: 0.3))
                                        .scaleEffect(isLoading ? 0.01 : 1)
                                        .animation(.spring())

                                    if self.isLoading  {
                                        LoaderCircle(size: 20, innerSize: 20, isButton: true)
                                    }
                                }
                                VStack (alignment: .leading, spacing: -4) {
                                    Text("Instagram stories")
                                        .modifier(TextModifier(size: 20, font: Font.textaAltBold, color: Color.white))
                                    Text("promo image")
                                        .modifier(TextModifier(size: 18, font: Font.textaAltBold, color: Color.white.opacity(0.6)))
                                }
                                Spacer()
                                 }
                                 .padding(.leading, 18)
                                 .padding(.trailing, 20)
                                 .frame(width: screenWidth - 30, height: 78)
                                 .background(BackgroundBlurView(style: .prominent).clipShape(RoundedRectangle(cornerRadius: 23)))
                             }
                        .disabled(self.isLoading ? true : false)
                             .buttonStyle(ButtonBounceLight())
                        .alert(isPresented: self.$storiesAlert) {
                            Alert(title: Text("under maintenance"),
                                  message: Text("sharing to Instagram stories is down right now. we're working on fixing it asap, until then you can still share to Instagram feed and TikTok!"),
                                  dismissButton: .default(Text("👍✌️")) {}
                            )
                        }

                        Spacer().frame(height: 1)
                         }
                        .offset(y: mainStage ? 0 : 400)
                        .animation(.spring())

                    VStack {
                        Text("select your 1min clip")
                            .modifier(TextModifier(size: 22))
                            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 0)
                        Spacer().frame(height: 90)
                        VStack {
                            HighlightPlayBar(
                                state: state,
                                progress: $progress,
                                value: $value,
                                isPlaying: isPlayingClip(),
                                duration: duration,
                                width: screenWidth - 44,
                                sup: sup,
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
                                    if self.isLoading  {
                                        LoaderCircle(size: 20, innerSize: 20, isButton: true)
                                    } else {
                                        Image(feedStage ? "instagram-feed" : tikTokStage ? "card-tiktok" : "instagram-stories")
                                            .renderingMode(.template)
                                            .foregroundColor(.white)
                                    }
                                }
                                Text(feedStage && !isLoading ? "share to feed" :
                                    tikTokStage && !isLoading ? "share to TikTok" :
                                    storiesStage && !isLoading ? "share to stories" : "exporting...")
                                    .modifier(TextModifier(size: 18))
                                    .animation(nil)
                            }
                            .padding(.horizontal, 25)
                            .frame(height: 58)
                            .background(
                                BackgroundBlurView(style: .prominent).clipShape(RoundedRectangle(cornerRadius: 25))
                            )
                        }
                    .buttonStyle(ButtonBounceLight())
                    }
                        .offset(y: shareStage ? 0 : 400)
                        .animation(.spring())
                }
            }
            .padding(.top, 12)
            .padding(.bottom, isIPhoneX ? 70 : 80)
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
                                self.close()
                            self.cardState = CGSize.zero
                        } else {
                            self.cardState = CGSize(width: 0, height: 0)
                        }
                })
        }
        .frame(width: screenWidth, height: screenHeight)
        .transition(.move(edge: .bottom))
        .animation(.spring())
        .onReceive(self.state.audioPlayer.playingSupWillChange.eraseToAnyPublisher()) { isPlayingSup in
            if !isPlayingSup {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.pausePlayback()
                }
            }
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
}

// MARK: The message part
extension ShareVideoCard {
    private func presentInstagramStories(completion: @escaping (Bool) -> Void) {
        let startTime = self.startTime
        let endTime = self.endTime != 0.0 ? self.endTime :
        (self.startTime + (self.feedStage || self.tikTokStage ? 60.0 : 15.0)) > self.duration ? self.duration : self.startTime + (self.feedStage || self.tikTokStage ? 60.0 : 15.0)
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postToInstagramStoriesImage(sup: sup, startTime: startTime, endTime: endTime, vc: vc, completion: completion)
        //SocialManager.sharedManager.postToInstagramStoriesVideo(sup: sup, startTime: startTime, endTime: endTime, vc: vc, completion: completion)
    }

    private func presentInstagramFeed(completion: @escaping (Bool) -> Void) {
        let startTime = self.startTime
        let endTime = self.endTime != 0.0 ? self.endTime :
        (self.startTime + (self.feedStage || self.tikTokStage ? 60.0 : 15.0)) > self.duration ? self.duration : self.startTime + (self.feedStage || self.tikTokStage ? 60.0 : 15.0)
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postToInstagramFeedVideo(sup: sup, startTime: startTime, endTime: endTime, vc: vc, completion: completion)
    }

    private func presentTikTok(completion: @escaping (Bool) -> Void) {
        let startTime = self.startTime
        let endTime = self.endTime != 0.0 ? self.endTime :
            (self.startTime + (self.feedStage || self.tikTokStage ? 60.0 : 15.0)) > self.duration ? self.duration : self.startTime + (self.feedStage || self.tikTokStage ? 60.0 : 15.0)
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
          SocialManager.sharedManager.postToTikTok(sup: sup, startTime: startTime, endTime: endTime, vc: vc, completion: completion)
    }
}
