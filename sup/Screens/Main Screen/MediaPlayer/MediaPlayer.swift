//
//  MediaPlayer.swift
//  sup
//
//  Created by Justin Spraggins on 5/15/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

private var renders = 0

struct MediaPlayer: View {
    @ObservedObject var state: AppState
    @EnvironmentObject var audioPlayer: AudioPlayer
    @State var itsYouAlert = false
    @State var animatePlaying = false
    @State var isPlaying = false
    @State var cardState = CGSize.zero
    @State var value: Double = 0
    @State private var playToggled = false
    @State private var loadingIG = false
    @State private var mainStage = true
    @State private var shareStage = false
    @State private var tikTokStage = false
    let loadingURL: URL?
    let url: URL
    let isPlayingSup: Bool
    let sup: Sup
    var onPlay: ((Sup) -> Void)? = nil
    var onPause: ((Sup) -> Void)? = nil
    var tapShareCard: (() -> Void)? = nil
    let cardHeight: CGFloat = 440
    let bitmojiSize: CGFloat = 38

    let coverSize: CGFloat = screenWidth - (isIPhoneX ? 40 : isIPhoneSE ? 120 : 104)

    private func isPlayingClip(_ audioPlayerCheck: Bool = true) -> Bool {
        if audioPlayerCheck {
            return isPlayingSup && self.audioPlayer.playingURL == url && self.audioPlayer.isPlaying
        } else {
            return isPlayingSup && self.audioPlayer.playingURL == url
        }
    }

    private func closePlayer() {
        self.state.showMediaPlayer = false
        self.state.showMediaPlayerDrawer = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.state.showMediaPlayerDrawer = true
        }
    }

    private func showShareCard() {
        self.audioPlayer.pausePlayback()
        self.playToggled = false
        self.state.showShareCard = true
    }

    private func showShareVideoCard() {
        self.audioPlayer.pausePlayback()
        self.playToggled = false
        self.state.showShareVideoCard = true
    }

    private func closeShareVideoCard() {
        impact(style: .soft)
        self.state.showShareVideoCard = false
    }

    private func showMessageCard() {
        self.audioPlayer.pausePlayback()
        self.playToggled = false
        self.state.showMessageCard = true
    }

    private func closeMessageCard() {
        impact(style: .soft)
        self.state.showMessageCard = false
    }

    private var currentUser: Bool {
        self.state.selectedSup?.username == self.state.currentUser?.username
    }

    private var disableDrag: Bool {
        self.state.showShareCard || self.state.showShareVideoCard || self.state.showMessageCard
    }

    private var duration: Double {
        AudioTime(duration: sup.duration, audioPlayer: audioPlayer).call()
    }

    var body: some View {
        if debugViewRenders {
            renders += 1
            print("MediaPlayer#body renders=\(renders)")
        }

        return VStack {
            ZStack {
                VStack {
                    ZStack {
                        BackgroundColorView(color: Color(sup.color.color()).opacity(0.8))
                            .background(Color.black)
                            .cornerRadius(isIPhoneX ? 40 : 12)
                        VStack (spacing: 0) {
                            Group {
                                Spacer().frame(height: isIPhoneX ? 38 : 15)
                                HStack {
                                    MediaPlayerButton(
                                        image: "player-down",
                                        action: { self.closePlayer() }
                                    )
                                    Spacer()
                                    Button(action:{}) {
                                        ZStack {
                                            Spacer().frame(height: bitmojiSize)
                                            HStack(spacing: -5) {
                                                WebImage(url: sup.avatarUrl)
                                                    .resizable()
                                                    .renderingMode(.original)
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: bitmojiSize, height: bitmojiSize)
                                                    .clipShape(Circle())
                                                    .animation(nil)

                                                ForEach(sup.guestAvatars, id: \.self) { value in
                                                    WebImage(url: URL(string: value))
                                                        .resizable()
                                                        .renderingMode(.original)
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: self.bitmojiSize, height: self.bitmojiSize)
                                                        .clipShape(Circle())
                                                        .animation(nil)
                                                }
                                            }
                                        }
                                    }
                                    .disabled(true)

                                    Spacer()
                                    Spacer().frame(width: 48)
                                }
                                .frame(width: screenWidth - 40)

                                Spacer()
                                WebImage(url: sup.coverArtUrl)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: coverSize, height: coverSize)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .contentShape(Rectangle())
                                    .scaleEffect(animatePlaying ? 1 : 0.88)
                                    .shadow(color: animatePlaying ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 20, x: 0, y: 5)
                                    .animation(.easeInOut(duration: 0.3))
                                    .padding(.top, isIPhoneX ? -25 : -20)
                                Spacer().frame(height: isIPhoneX ? 30 : 20)
                            }

                            VStack (spacing: 0) {
                                HStack {
                                    Text(sup.description)
                                        .modifier(TextModifier(size: 22, font: Font.textaBold, color: .white))
                                        .lineLimit(0)
                                        .truncationMode(.tail)
                                        .lineSpacing(0)
                                    Spacer()
                                }
                                .frame(width: screenWidth - 44)

                                HStack {
                                    ZStack {
                                        Text(sup.username)
                                            .modifier(TextModifier(size: 22, font: Font.textaBold, color: Color.white.opacity(0.1)))
                                        Text(sup.username)
                                            .modifier(TextModifier(size: 22, font: Font.textaBold, color: .white))
                                            .blendMode(.overlay)
                                    }

                                    Spacer()
                                }
                                .padding(.bottom, isIPhoneX ? 20 : 15)
                                .frame(width: screenWidth - 44)
                            }

                            VStack {
                                PlayBar(
                                    state: state,
                                    value: isPlayingClip(false) ? $value : .constant(0),
                                    isPlaying: isPlayingClip(),
                                    duration: duration,
                                    width: screenWidth - 44
                                )
                                HStack {
                                    Button(action: {}) {
                                        ZStack {
                                            Text(isPlayingClip(false) ? calculateValue().toTime : "00:00")
                                                .modifier(TextModifier(size: 16, color: Color.white.opacity(0.1)))
                                                .animation(nil)
                                            Text(isPlayingClip(false) ? calculateValue().toTime : "00:00")
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
                            HStack (spacing: 45) {
                                MediaPlayerButton(image: "player-back", action: {
                                    impact(style: .soft)
                                    if self.isPlayingClip() {
                                        self.setBackValue()
                                    }
                                })
                                Button(action: {
                                    impact(style: .soft)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        if self.isPlayingClip() {
                                            self.animatePlaying = false
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                                self.onPause?(self.sup)
                                            }
                                        } else {
                                            self.animatePlaying = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                                self.onPlay?(self.sup)
                                            }
                                        }
                                    }
                                }) {
                                    ZStack {
                                        Spacer().frame(width: 68, height: 68)
                                        if self.loadingURL == sup.url {
                                            ZStack {
                                                Circle()
                                                    .frame(width: 50, height: 50)
                                                    .foregroundColor(Color.black.opacity(0.2))
                                                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y:0)
                                                LoaderCircle(size: 20, innerSize: 20, tint: .white)
                                            }
                                        } else {
                                            Image(self.animatePlaying ? "player-pause" : "player-play")
                                                .renderingMode(.template)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(ButtonBounceHeavy())
                                MediaPlayerButton(image: "player-forward", action: {
                                    impact(style: .soft)
                                    if self.isPlayingClip() {
                                        self.setForwardValue()
                                    }
                                })
                            }

                            Spacer()
                            HStack {
                                if self.currentUser {
                                    MediaPlayerButton(image: "player-tiktok",
                                                      action: {
                                                        self.mainStage = false
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                            self.shareStage = true
                                                            self.tikTokStage = true
                                                        }
                                                        self.showShareVideoCard() })

                                } else {
                                    MediaPlayerButton(image: "player-share",
                                                      action: { self.showShareVideoCard()
                                    })
                                }

                                Spacer()

                                if self.currentUser {
                                    MediaPlayerButton(image: "player-instagram",
                                                      action: {self.showShareVideoCard()})
                                } else {
                                    MediaPlayerButton(image: "player-comment",
                                                      action: { self.showMessageCard()
                                    })
                                }

                                Spacer()
                                MediaPlayerButton(image: "player-more",
                                                  action: { self.showShareCard() })
                            }
                            .frame(width: screenWidth - 30)

                            Spacer().frame(height: isIPhoneX ? 38 : 22)
                        }

                    }
                    .offset(y: self.cardState.height)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !self.disableDrag {
                                    self.cardState = value.translation
                                    if self.cardState.height < -5 {
                                        self.cardState = CGSize.zero
                                    }
                                }
                        }
                        .onEnded { value in
                            if self.cardState.height > 10 {
                                self.closePlayer()
                                self.cardState = CGSize.zero
                            } else {
                                self.cardState = CGSize(width: 0, height: 0)
                            }
                    })
                }

                if self.state.showShareVideoCard || self.state.showMessageCard {
                    VStack {
                        Color.black.opacity(0.4)
                            .frame(width: screenWidth, height: screenHeight)
                            .onTapGesture {
                                if self.state.showShareVideoCard {
                                    self.closeShareVideoCard()
                                } else {
                                    self.closeMessageCard()
                                }
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3))
                }

                if self.state.showShareVideoCard && self.state.selectedSup != nil {
                    ShareVideoCard(state: state,
                                   mainStage: $mainStage,
                                   shareStage: $shareStage,
                                   tikTokStage: $tikTokStage,
                                   sup: state.selectedSup!,
                                   onClose: { self.closeShareVideoCard()})
                }

                if (self.state.showMessageCard && self.state.selectedSup != nil) {
                    SendMessageCard(state: state,
                                    audioRecorder: .constant(AudioRecorder()),
                                    isMessage: state.showMessageCard,
                                    comment: state.selectedComment,
                                    sup: state.selectedSup!,
                                    onClose: { self.closeMessageCard()})
                }
            }
        }
        .transition(.move(edge: .bottom))
        .animation(.spring())
        .onReceive(self.state.showMediaPlayer$) { isShowing in
            if !self.isPlayingSup {
                self.animatePlaying = false
            } else if self.isPlayingClip() {
                self.animatePlaying = true
            }
        }
        .onReceive(self.state.audioPlayer.finishWillChange) { isFinished in
            if isFinished {
                self.animatePlaying = false
            }
        }
        .frame(width: screenWidth, height: screenHeight)
    }
    
    func setForwardValue() {
        let value = self.state.audioPlayer.audioPlayer!.currentTime + 30
        self.state.audioPlayer.audioPlayer?.currentTime = value
    }
    
    func setBackValue() {
        let value = self.state.audioPlayer.audioPlayer!.currentTime - 30
        self.state.audioPlayer.audioPlayer?.currentTime = value
    }
    
    func calculateValue() -> Double {
        let value = duration * self.value // To increase
        //let value = duration - (self.value * duration) // To decrease
        return value
    }
}


// MARK: The message part
extension MediaPlayer {
    private func presentInstagramStories(completion: @escaping (Bool) -> Void) {
        let startTime = self.state.audioPlayer.audioPlayer?.currentTime ?? 0
        let endTime = (startTime + 15 <= duration) ? startTime + 15 : duration
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postToInstagramStoriesImage(sup: sup, startTime: startTime, endTime: endTime, vc: vc, completion: completion)
    }
}
