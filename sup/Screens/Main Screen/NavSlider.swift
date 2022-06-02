//
//  NavSlider.swift
//  sup
//
//  Created by Justin Spraggins on 5/17/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct NavSlider: View {
    @ObservedObject var state: AppState

    var hideNavBar: Bool {
        self.state.showAddFriend ||
            self.state.hideNav ||
            self.state.moveMainUp ||
            self.state.isConnect ||
            self.state.isConnecting ||
            self.state.isConnectHappyHour
    }

    private func moveToFriends() {
        impact(style: .soft)
        self.state.moveToFriends = true
        self.state.moveToProfile = false
        self.state.moveToHome = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.state.showMediaPlayerDrawer = true
        }
    }

    private func moveToMain() {
        impact(style: .soft)
        self.state.audioPlayer.pausePlayback()
        self.state.moveToHome = true
        self.state.moveToProfile = false
        self.state.moveToFriends = false
        self.state.showMediaPlayerDrawer = false
    }

    private func moveToProfile() {
        impact(style: .soft)
        self.state.moveToHome = false
        self.state.moveToFriends = false
        self.state.moveToProfile = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.state.showMediaPlayerDrawer = true
        }
    }

    private func showSettingsCard() {
        impact(style: .soft)
        self.state.audioPlayer.stopPlayback()
        self.state.showMediaPlayerDrawer = false
        self.state.showSettingsCard = true
    }

    private func toggleRecents() {
        impact(style: .soft)
        self.state.showRecents.toggle()
    }

    var body: some View {
        VStack (spacing: 0) {
            HStack {
                ZStack {
                    if self.state.moveToFriends {
                        TintImageButton(image: "nav-phone",
                                        width: 50,
                                        height: 50,
                                        corner: 25,
                                        background: Color.black.opacity(0.0001),
                                        tint: .white,
                                        action: { self.moveToMain() })
                            .transition(AnyTransition.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 50, height: 50)

                Spacer()

                ZStack {
                    if self.state.moveToProfile && !self.state.showNotifications {
                        Text("\(self.state.currentUser?.username ?? "profile")")
                            .modifier(TextModifier(size: 22, font: Font.textaAltBlack, color: Color.white))
                            .frame(width: 200)
                            .lineLimit(0)
                            .truncationMode(.tail)
                            .animation(.none)
                    }

                    if self.state.showNotifications {
                        Text("notifications")
                            .modifier(TextModifier(size: 22, font: Font.textaAltBlack, color: Color.white))
                            .animation(.none)
                    }

                    if self.state.moveToFriends && !self.state.moveToProfile && !self.state.showNotifications {
                        Button(action: { self.toggleRecents() }) {
                            HStack {
                                    Text(self.state.showRecents ? "recents" : "following")
                                        .modifier(TextModifier(size: self.state.showRecents ? 22 : 20, font: Font.textaAltBlack, color: Color.white))
                                        .animation(nil)
                                        .frame(width: 88, height: 20)

                                VStack (spacing: 5) {
                                    Circle()
                                        .frame(width: 7, height: 7)
                                        .foregroundColor(self.state.showRecents ?
                                            Color.white.opacity(0.4) :
                                            Color.yellowAccentColor)
                                    
                                    Circle()
                                        .frame(width: 7, height: 7)
                                        .foregroundColor(self.state.showRecents ?
                                            Color.redColor :
                                            Color.white.opacity(0.4))
                                }
                                }
                        }
                        .buttonStyle(ButtonBounce())
                    }
                }
                .frame(width: 200)

                Spacer()
                ZStack {
                    if self.state.moveToHome {
                        TintImageButton(image: "nav-profile",
                                        width: 50,
                                        height: 50,
                                        corner: 25,
                                        background: Color.black.opacity(0.0001),
                                        tint: .white,
                                        action: { self.moveToFriends() })
                            .transition(AnyTransition.scale.combined(with: .opacity))
                    }

                    if self.state.moveToProfile && !self.state.showNotifications {
                        TintImageButton(image: "nav-settings",
                                        width: 50,
                                        height: 50,
                                        corner: 25,
                                        background: Color.black.opacity(0.0001),
                                        tint: .white,
                                        action: { self.showSettingsCard() })
                            .animation(.none)
                    }
                }
                .frame(width: 50, height: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, isIPhoneX ? 72 : 26)
            .frame(width: screenWidth, height: isIPhoneX ? 145 : 95)

            Spacer()
        }
        .frame(width: screenWidth, height: screenHeight)
        .opacity(hideNavBar ? 0 : 1)
        .animation(.easeInOut(duration: 0.2))
        .edgesIgnoringSafeArea(.all)
    }
}
