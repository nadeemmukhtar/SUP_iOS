//
//  SendMessageCard.swift
//  sup
//
//  Created by Justin Spraggins on 5/27/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import OneSignal
import SDWebImageSwiftUI

struct SendMessageCard: View {
    @ObservedObject var state: AppState
    @Binding var audioRecorder: AudioRecorder
    @State private var interactionInCard = false
    @State var cardState = CGSize.zero
    @State var sentAlert = false
    @State var isSending = false
    @State var showHint = false
    @State var isSent = false
    let isMessage: Bool
    let comment: Comment?
    let sup: Sup
    let username: String = "username"
    let pColor: Color = Color.white
    let cardHeight: CGFloat = isIPhoneX ? 410 : 390
    var onClose: (() -> Void)? = nil
    var onComplete: (() -> Void)? = nil

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
                .onTapGesture { self.onClose?() }

                Spacer().frame(height: 20)

                WebImage(url: isMessage ? sup.avatarUrl : comment!.avatarUrl)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(Circle())

                Text(isMessage ? "send \(sup.username) a comment" : "reply to \(comment!.username)'s comment")
                    .modifier(TextModifier(size: 20, font: Font.ttNormsBold, color: Color.white))
                    .lineSpacing(0)
                    .frame(width: screenWidth - 80)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 0)
                    .padding(.top, 5)

                Spacer()
                ZStack (alignment: .center) {
                    Button(action: {}) {
                        Text(isSending ? "sending..." : "sent!")
                        .frame(width: screenWidth)
                            .multilineTextAlignment(.center)
                            .animation(nil)
                            .modifier(TextModifier(size: 22))
                            .shadow(color: Color.black.opacity(0.3), radius: 19, x: 0, y: 0)
                    }
                    .padding(.bottom, 15)
                    .disabled(true)
                    .opacity(isSent || isSending ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3))
                    TapAndHoldPopover(state: state, isRecording: self.$state.isRecording)
                        .opacity(self.isSending || self.isSent || !self.showHint ? 0 : 1)
                        .animation(.linear(duration: 0.1))
                        .scaleEffect(showHint ? 1 : 0.01)
                        .animation(.spring())
                }

                ZStack {
                    ZStack {
                        BackgroundBlurView(style: .prominent)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .opacity(isSending || isSent ? 1 : 0)
                            .animation(.easeInOut(duration: 0.3))
                            .scaleEffect(isSending || isSent ? 1 : 0.01)
                            .animation(.spring())
                        if isSending {
                            LoaderCircle(size: 30, innerSize: 30, isButton: true, tint: Color.white)
                        }
                        Image("sent-check")
                            .opacity(isSent ? 1 : 0)
                            .animation(.easeInOut(duration: 0.3))
                            .scaleEffect(isSent ? 1 : 0.01)
                            .animation(.spring())
                    }
                    .padding(.top, -15)

                    RecordButton(
                        state: state,
                        isRecording: self.$state.isRecording,
                        audioRecorder: self.$state.audioRecorder,
                        isRecordingIntro: false,
                        maxSeconds: 15.0,
                        onRecordingStart: {
                            self.state.audioPlayer.stopPlayback()
                    },
                        onRecordingStop: {
                            self.isSending = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                self.state.saveComment(sup: self.sup, comment: self.isMessage ? nil : self.comment, type: "comment") { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        self.isSending = false
                                        self.isSent = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            self.onClose?()
                                        }
                                    }

                                    DispatchQueue.global(qos: .background).async {
                                        User.get(userID: self.isMessage ? self.sup.userID : self.comment!.userID) { user in
                                            if let user = user {
                                                self.sendPush(user: user)
                                            }
                                        }
                                    }
                                }
                            }
                    }
                    )
                        .opacity(isSending || isSent ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3))
                        .scaleEffect(isSending || isSent ? 0.01 : 1)
                        .animation(.spring())
                }
                }
                .padding(.top, 12)
                .padding(.bottom, isIPhoneX ? 75 : 70)
                .frame(width: screenWidth, height: cardHeight)
                .background(
                    ZStack {
                        BackgroundBlurView(style: .systemUltraThinMaterialLight)
                            .frame(width: screenWidth, height: cardHeight)
                            .cornerRadius(radius: isIPhoneX ? 30 : 18, corners: [.topLeft, .topRight])
                    }
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
                                self.self.onClose?()
                                self.cardState = CGSize.zero
                            } else {
                                self.cardState = CGSize(width: 0, height: 0)
                            }
                    })
            }
        .transition(.move(edge: .bottom))
        .animation(.spring())
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showHint = true
            }
        }
        .onDisappear() {
            self.isSending = false
            self.isSent = false
        }
            .frame(width: screenWidth, height: screenHeight)
            .edgesIgnoringSafeArea(.bottom)
    }
    
    private func sendPush(user: User) {
        guard let displayName = self.state.currentUser?.displayName else { return }
        var playerIds = [String]()
        playerIds.append(user.oneSignalPlayerId ?? "")
        let pushText = isMessage ? "\(displayName) sent you a comment on your sup: \(sup.description)" : "\(displayName) replied to your comment: \(comment!.supTitle)"
        OneSignal.postNotification(
            ["contents": ["en": pushText],
             "include_player_ids": playerIds])
    }
}
