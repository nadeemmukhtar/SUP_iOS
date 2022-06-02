//
//  NavigationScreen.swift
//  sup
//
//  Created by Justin Spraggins on 12/16/19.
//  Copyright © 2019 Episode 8, Inc. All rights reserved.
//

import SwiftUI

private var renders = 0

struct NavigationScreen: View {
    @ObservedObject var state: AppState
    @ObservedObject var newSupState: NewSupState
    @State private var loadingURL: URL? = nil

    var showMediaPlayerDrawer: Bool {
        self.state.showMediaPlayerDrawer && !self.state.moveToHome
    }

    var mediaPlayerDrawerSup: Sup? {
        self.state.playingSup ?? self.state.selectedSup
    }

    private func closeMediaPlayer() {
        impact(style: .soft)
        self.state.showMediaPlayer = false
    }

    private func closePhotoLibrary() {
        if self.state.showPublish {
            self.state.animatePhotoLibrary = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.state.hidePublish = false
                self.state.showPhotoLibrary = false
            }
        } else {
            self.state.animatePhotoLibrary = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.state.showPhotoLibrary = false
                self.state.showMediaPlayerDrawer = true
                self.state.hideNav = false
                self.state.hideProfile = false
                self.state.showOverlay = false
            }
        }
    }

    private func refreshPhotoLibrary() {
        self.state.fetchPhotoAlbums(refresh: true)
    }

    private func closeMessageCard() {
        impact(style: .soft)
        self.state.showReplyCard = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8){
            self.state.showMediaPlayerDrawer = true
        }
    }

    var body: some View {
        if debugViewRenders {
            renders += 1
            print("NavigationScreen#body renders=\(renders)")
        }

        if state.showSplashVideo {
            return AnyView(
                ZStack {
                    BackgroundColorView(color: Color(#colorLiteral(red: 0.05490196078, green: 0.05490196078, blue: 0.05490196078, alpha: 1)))
                    PlayerSplashView()
                        .frame(width: screenWidth, height: screenHeight + 20)
                }
                .onAppear() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
                        self.state.showSplashVideo = false
                    }
                }
            )
        } else if state.isOnboarding {
            return AnyView(
                OnboardingCard(state: state)
                    .environmentObject(state.audioPlayer)
            )
        } else {
            return AnyView(
                ZStack {
                    BackgroundColorView(color: Color.backgroundColor)
                    ///MainUI
                    HStack (spacing: 0) {
                        MainScreen(state: self.state, newSupState: self.newSupState)
                            .environmentObject(self.state.audioPlayer)
                            .frame(width: screenWidth, height: screenHeight)
                            .zIndex(0)
                        ZStack {
                            FriendsNavigation(state: state)
                                .frame(width: screenWidth, height: screenHeight)
                                .background(Color.backgroundColor)

                            ProfileNavigation(state: state)
                                .environmentObject(self.state.audioPlayer)
                                .frame(width: screenWidth, height: screenHeight)
                                .background(Color.backgroundColor)
                                .opacity(state.moveToProfile && !state.hideProfile ? 1 : 0)
                                .animation(.none)

                            NotificationScreen(state: state)
                                .environmentObject(self.state.audioPlayer)
                                .opacity(state.showNotifications ? 1 : 0)
                                .animation(.none)

                            if mediaPlayerDrawerSup != nil && self.state.selectedSup != nil {
                                MediaPlayerDrawer(
                                    state: state,
                                    loadingURL: self.loadingURL,
                                    visible: !state.showMediaPlayer && mediaPlayerDrawerSup != nil,
                                    url: mediaPlayerDrawerSup!.url,
                                    sup: mediaPlayerDrawerSup!,
                                    onTap: {
                                        DispatchQueue.main.async {
                                            if self.state.playingSup != nil {
                                                self.state.selectedSup = self.state.playingSup
                                            }
                                        }
                                },
                                    onPlay: { sup in
                                        DispatchQueue.main.async {
                                            self.state.playingSup = sup
                                            self.state.audioPlayer.startPlayback(
                                                audio: sup.url,
                                                loadingURL: self.$loadingURL,
                                                sup: sup
                                            )
                                        }
                                },
                                    onPause: { sup in
                                        self.state.audioPlayer.pausePlayback()
                                        // self.state.selectedSup = sup
                                })
                                    .environmentObject(self.state.audioPlayer)
                                    .offset(y: showMediaPlayerDrawer ? 5 : 235)
                                    .animation(Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0).speed(0.9))
                            }
                            TabBar(state: state)
                        }

                    }
                    .offset(x: state.moveToFriends ? -screenWidth/2 : screenWidth/2)
                    .animation(Animation.spring().speed(1.4))
                    .opacity(self.state.showPhotoLibrary ? 0 : 1)


                    ///NavBar
                    NavSlider(state: state)
                        .opacity(self.state.showPhotoLibrary ? 0 : 1)

                    ///Media Players
                    Group {
                        BackgroundColorView(color: Color.black)
                            .opacity(self.state.showMediaPlayer ? 0.4 : 0)
                            .animation(.easeInOut(duration: 0.3))

                        if mediaPlayerDrawerSup != nil && self.state.selectedSup != nil && self.state.showMediaPlayer {
                            MediaPlayer(
                                state: state,
                                loadingURL: self.loadingURL,
                                url: mediaPlayerDrawerSup!.url,
                                isPlayingSup: mediaPlayerDrawerSup!.url == self.state.selectedSup!.url,
                                sup: self.state.selectedSup!,
                                onPlay: { sup in
                                    DispatchQueue.main.async {
                                        self.state.playingSup = sup
                                        self.state.audioPlayer.startPlayback(
                                            audio: sup.url,
                                            loadingURL: self.$loadingURL,
                                            sup: sup
                                        )
                                    }
                            },
                                onPause: { sup in
                                    self.state.audioPlayer.pausePlayback()
                            },
                                tapShareCard: { }
                            )
                                .environmentObject(self.state.audioPlayer)
                                .statusBar(hidden: state.showMediaPlayer && !state.showUserProfile)

                        }
                    }

                    ///Cards
                    CardNavigation(state: state)

                    if self.state.showPhotoLibrary {
                        CoverPhotoLibrary(state: state,
                                          tapRefresh: { self.refreshPhotoLibrary()},
                                          onClose: { self.closePhotoLibrary()},
                                          onComplete: {self.closePhotoLibrary()})
                            .frame(width: screenWidth, height: screenHeight)
                    }

                    if self.state.showReplyCard {
                        SendMessageCard(state: self.state,
                                        audioRecorder: .constant(AudioRecorder()),
                                        isMessage: self.state.showMessageCard,
                                        comment: self.state.selectedComment,
                                        sup: self.state.selectedSup!,
                                        onClose: { self.closeMessageCard()})
                        .environmentObject(self.state.audioPlayer)
                    }
                }
            )
        }
    }
    
    private func addQuesion(title: String) {
        let question = Question(id: randomString(), title: title, isFeatured: true)
        self.state.questions.insert(question, at: 0)
    }
    
    private func randomString() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<10).map{ _ in letters.randomElement()! })
    }
}

#if DEBUG
struct NavigationScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationScreen(state: AppState(), newSupState: NewSupState())
    }
}
#endif
