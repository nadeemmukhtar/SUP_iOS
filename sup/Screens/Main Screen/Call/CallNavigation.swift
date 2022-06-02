 //
 //  CallNavigation.swift
 //  sup
 //
 //  Created by Justin Spraggins on 4/20/20.
 //  Copyright © 2020 Episode 8, Inc. All rights reserved.
 //

 import SwiftUI
 import Combine
 import PaperTrailLumberjack
 import SDWebImageSwiftUI

 private let onPresent$ = PassthroughSubject<Void, Never>()

 struct CallNavigation: View {
    @ObservedObject var state: AppState
    @Binding var timeEnding: Bool
    @Binding var timeEnded: Bool
    @State var animateTimer = true
    @State var endActionSheet = false
    @State var stopRecordingActionSheet = false
    @State private var muteMic = false
    @State private var reportActionSheet = false
    @State private var showAlert = false

    @Binding var value: Double
    var callerHangUp: (() -> Void)
    var callerStartedRecording: (() -> Void)
    var stopArchive: (() -> Void)

    private var showTimer: Bool {
        self.state.isConnect
    }

    private var showStartRecording: Bool {
        AppDelegate.isCaller && state.animateStartRecording && !state.browseQuestions
    }

    func callerStartRecording() {
        impact(style: .soft)
        self.state.animateStartRecording = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.state.animateIsRecording = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.callerStartedRecording()

            }
        }
    }

    private func callerEndRecording() {
        impact(style: .soft)
        self.state.animateIsRecording = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.state.animateAudioSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.stopArchive()
            }
        }
    }

    private func callerTappedHangUp() {
        impact(style: .soft)
            self.state.browseQuestions = false
            self.state.hideNav = true
            self.callerHangUp()
    }

    var body: some View {
        ZStack {

            ///Nav Bottom bar
            VStack {
                Spacer().frame(height: isIPhoneX ? 44 : 26)
                HStack {
                    Spacer()
                    Button(action: {
                        impact(style: .soft)
                        self.reportActionSheet = true
                    }) {
                        ZStack {
                            Circle()
                                .foregroundColor(Color.black.opacity(0.0001))
                                .frame(width: 50, height: 50)
                            Image("vertical-more")
                                .renderingMode(.template)
                                .foregroundColor(Color.white)
                        }
                    }
                    .buttonStyle(ButtonBounceHeavy())
                    .actionSheet(isPresented: $reportActionSheet) {
                        ActionSheet(title: Text("report user"),
                                    message: Text("Are you sure you want to report this user?"),
                                    buttons: [
                                        .destructive(Text("report inappropriate")) { self.showAlert = true },
                                        .cancel()
                        ])
                    }
                }
                .padding(.horizontal, 10)
                .alert(isPresented: self.$showAlert) {
                    Alert(title: Text("reported"),
                          message: Text("thank you for reporting this users. our policy is to remove any users deemed inappropriate within 24hrs."),
                          dismissButton: .default(Text("okay"))
                    )
                }

                Spacer()
                HStack (spacing: 16) {
                    Spacer()
                    Button(action: {
                        impact(style: .soft)
                        self.muteMic.toggle()
                        AppPublishers.micMute$.send(self.muteMic)
                    }) {
                        ZStack {
                            Circle()
                                .foregroundColor(muteMic ? Color.white : Color.white.opacity(0.1))
                                .frame(width: 54, height: 54)
                            Image("mute-icon")
                                .renderingMode(.template)
                                .foregroundColor(muteMic ? Color.black : Color.white)
                        }
                    }
                    .buttonStyle(ButtonBounceHeavy())

                    Group {
                        if AppDelegate.isCaller && state.animateAudioSaved {
                            Button(action: {
                                impact(style: .soft)
                                self.callerTappedHangUp()
                            }) {
                                ZStack {
                                    BackgroundBlurView(style: .systemUltraThinMaterialDark)
                                        .frame(width: 54, height: 54)
                                        .overlay(Color.redColor.opacity(0.7))
                                        .clipShape(Circle())
                                    Image("call-end")
                                        .renderingMode(.template)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 54, height: 54)
                            }
                            .buttonStyle(ButtonBounce())
                        }
                    }
                }
                .padding(.horizontal, 22)
                Spacer().frame(height: isIPhoneX ? 45 : 20)

            }
            .frame(width: screenWidth, height: screenHeight)

            ///Center Buttons
            if state.animateIsRecording && !state.browseQuestions {
                VStack {
                    Button(action: {
                        impact(style: .soft)
                        self.stopRecordingActionSheet = true
                    }) {
                        ZStack {
                            BackgroundBlurView(style: .systemUltraThinMaterialLight)
                                .frame(width: AppDelegate.isCaller ? 252 : 222, height: 70)
                                .cornerRadius(24)
                            RoundedRectangle(cornerRadius: 22)
                                .frame(width: AppDelegate.isCaller ? 242 : 212, height: 60)
                                .foregroundColor(Color.redDark.opacity(0.8))

                            HStack (spacing: 12) {
                                if AppDelegate.isCaller {
                                    RoundedRectangle(cornerRadius: 4)
                                        .frame(width: 18, height: 18)
                                        .foregroundColor(Color.redColor)
                                }
                                Text("recording")
                                    .modifier(TextModifier(size: 21, font: Font.textaAltBlack, color: Color.redColor))
                                    .padding(.bottom, 4)

                                Text(showTimer ? value.toTime : "")
                                    .modifier(TextModifier(size: 22, font: Font.ttNormsBold, color: Color.redColor))
                                    .animation(nil)
                                    .frame(width: 72, height: 66)
                                    .padding(.bottom, 1)
                            }
                        }
                    }
                    .disabled(AppDelegate.isCaller ? false : true)
                    .buttonStyle(ButtonBounceLight())
                    .actionSheet(isPresented: $stopRecordingActionSheet) {
                        ActionSheet(
                            title: Text(""),
                            message: Text("Are you sure you want to stop recording audio?"),
                            buttons: [.destructive(Text("Stop recording audio")) { self.callerEndRecording() }, .cancel()]
                        )
                    }
                }
                .transition(AnyTransition.scale(scale: 0.9).combined(with: .opacity))
            }

            if self.state.animateAudioSaved && !state.browseQuestions {
                VStack {
                    Button(action: {}) {
                        ZStack {
                            BackgroundBlurView(style: .systemUltraThinMaterialLight)
                                .frame(width: 222, height: 70)
                                .cornerRadius(24)
                            RoundedRectangle(cornerRadius: 22)
                                .frame(width: 212, height: 60)
                                .foregroundColor(Color.black.opacity(0.2))

                            HStack (spacing: 12) {
                                Image("call-check")
                                    .renderingMode(.template)
                                    .foregroundColor(Color.white)
                                Text("audio saved")
                                    .modifier(TextModifier(size: 21, font: Font.textaAltBlack, color: Color.white))
                                    .padding(.bottom, 4)
                            }
                        }
                    }
                    .disabled(true)
                }
                .transition(AnyTransition.scale(scale: 0.9).combined(with: .opacity))
            }

            if !AppDelegate.isCaller && state.animateStartRecording && !state.browseQuestions {
                VStack {
                    Button(action: {}) {
                        ZStack {
                            BackgroundBlurView(style: .systemUltraThinMaterialLight)
                                .frame(width: 252, height: 70)
                                .cornerRadius(24)
                            RoundedRectangle(cornerRadius: 22)
                                .frame(width: 242, height: 60)
                                .foregroundColor(Color.black.opacity(0.2))

                            Text("recording hasn't started")
                                .modifier(TextModifier(size: 20, font: Font.textaAltBlack, color: Color.white))
                                .padding(.bottom, 2)
                        }
                    }
                    .disabled(true)
                }
                .transition(AnyTransition.scale(scale: 0.9).combined(with: .opacity))
            }

            if showStartRecording {
                VStack {
                    Button(action: { self.callerStartRecording() }) {
                        ZStack {
                            BackgroundBlurView(style: .systemUltraThinMaterialLight)
                                .frame(width: 228, height: 70)
                                .cornerRadius(24)
                            RoundedRectangle(cornerRadius: 22)
                                .frame(width: 218, height: 60)
                                .foregroundColor(Color.yellowDarkColor.opacity(0.2))

                            HStack (spacing: 12) {
                                Image("mic-small")
                                    .renderingMode(.template)
                                    .foregroundColor(Color.yellowAccentColor)
                                Text("start recording")
                                    .modifier(TextModifier(size: 21, font: Font.textaAltBlack, color: Color.yellowAccentColor))
                                    .padding(.bottom, 4)
                            }
                        }
                    }
                    .buttonStyle(ButtonBounce())
                }
                .transition(AnyTransition.scale(scale: 0.9).combined(with: .opacity))
            }

            if self.state.callBaseURL != nil {
                MessageComposeView(
                    body: "tap the link to record a sup with me 👇 \(self.state.callBaseURL!)",
                    onPresent$: onPresent$
                ).frame(width: 0, height: 0)
            }
        }
        .frame(width: screenWidth, height: screenHeight)
        .onReceive(AppPublishers.callStatusUpdated$.removeDuplicates().eraseToAnyPublisher()) { callStatus in
            DDLogVerbose("onReceive - callStatusUpdated$ callStatus=\(callStatus) isCaller=\(AppDelegate.isCaller)")
            if AppDelegate.isCaller { return }

            if callStatus == "recording-started" {
                self.state.animateStartRecording = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.state.animateIsRecording = true
                }
            }
            if callStatus == "recording-stopped" {
                self.state.animateIsRecording = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.state.animateAudioSaved = true
                }
            }
        }
        .onAppear() {
            self.timeEnding = false
            self.state.browseQuestions = false
            self.state.animateStartRecording = true
            self.state.animateIsRecording = false
            self.state.animateAudioSaved = false

            if AppDelegate.callStatus == "recording-started" {
                self.state.animateStartRecording = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.state.animateIsRecording = true
                }
            }
        }
    }
 }

 // MARK: The message part
 extension CallNavigation {
    private func presentSnapchat() {
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postInviteToSnapchat(url: "\(self.state.callBaseURL!)", vc: vc)
    }
 }

