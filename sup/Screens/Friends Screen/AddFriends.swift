//
//  AddFriends.swift
//  sup
//
//  Created by Justin Spraggins on 5/7/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import Combine
import OneSignal
import MessageUI

private let onPresent$ = PassthroughSubject<Void, Never>()

struct AddFriends: View {
    @ObservedObject var state: AppState
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    @State var showNotification = false
    @State var notification = "there was an error"
    @State private var text: String = ""
    @State var keyboardOpen = true
    @State private var friendAdded = false
    @State private var usernameInvalid = false
    @State private var friends = [User]()
    @State private var hideFriend = false
    @State private var isTyping = false

    private func closeKeyboard() {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        keyWindow!.endEditing(true)
    }

    func isFriend() -> Bool {
        self.state.friends.contains(where: { $0.username == text })
    }

    func addUser() {
        if !text.isEmpty {
            if !isFriend() {
                User.get(username: text) { user in
                    if let user = user {
                        guard let username = self.state.currentUser?.username else { return }
                        if user.username != username {
                            Friend.create(username: username, friendnames: [user.username!]) { friend in
                                self.state.friendDidAdd.send(true)
                                self.sendPush(user: user)
                                self.text = ""

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    self.closeAddFriend()
                                }

                                let keyWindow = UIApplication.shared.connectedScenes
                                    .filter({$0.activationState == .foregroundActive})
                                    .map({$0 as? UIWindowScene})
                                    .compactMap({$0})
                                    .first?.windows
                                    .filter({$0.isKeyWindow}).first
                                keyWindow!.endEditing(true)
                            }
                        } else {
                            self.usernameInvalid = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.usernameInvalid = false
                            }
                            self.show(note: "that's you!")
                        }
                    } else {
                        self.usernameInvalid = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.usernameInvalid = false
                        }
                        self.show(note: "username invalid")
                    }
                }
            } else {
                self.usernameInvalid = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.usernameInvalid = false
                }
                self.show(note: "already following friend")
            }
        }
    }
    
    func isFriend(text: String) -> Bool {
        self.state.friends.contains(where: { $0.username == text })
    }
    
    func followUser(text: String) {
        User.get(username: text) { user in
            if let user = user {
                guard let username = self.state.currentUser?.username else { return }
                Friend.create(username: username, friendnames: [user.username!]) { friend in
                    self.state.friendDidAdd.send(true)
                    self.sendPush(user: user)
                }
            } else {
                self.usernameInvalid = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.usernameInvalid = false
                }
                self.show(note: "username invalid")
            }
        }
    }
    
    func unfollowUser(text: String) {
        guard let username = self.state.currentUser?.username else { return }
        let selectedUsername = text
        Friend.delete(username: username, friendnames: [selectedUsername]) { _ in
            self.state.friendDidAdd.send(true)
        }
    }

    private func show(note: String) {
        self.notification = note
        self.showNotification = true
    }

    private func closeAddFriend() {
        self.state.animateAddFriend = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.closeKeyboard()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.state.showAddFriend = false
                    self.state.showMediaPlayerDrawer = true
                }
        }
    }
    
    private func sendPush(user: User) {
        guard let usernameName = self.state.currentUser?.username else { return }
        var playerIds = [String]()
        playerIds.append(user.oneSignalPlayerId ?? "")
        OneSignal.postNotification(
            ["contents": ["en": "\(usernameName) followed you"],
             "include_player_ids": playerIds])
    }

    var body: some View {
        ZStack {
            ScrollableView(self.$contentOffset, animationDuration: 0.5, action: { _ in }) {
                VStack (alignment: .leading) {
                    Spacer().frame(height: isIPhoneX ? 105 : 100)
                    if !self.state.guestUsers.isEmpty {
                        HStack {
                            Text("recent guests")
                                .modifier(TextModifier(size: 22,  color: Color.secondaryTextColor))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(1)
                                .opacity(self.state.animateAddFriend ? 1 : 0)
                                .animation(.easeInOut(duration: 0.2))
                            Spacer()
                        }
                        .padding(.leading, 10)
                        .opacity(self.state.animateAddFriend && self.text.isEmpty ? 1 : 0)

                        ForEach(self.state.guestUsers) { user in
                            FollowerCell(user: user,
                                         isFriend: self.isFriend(text: user.username ?? ""),
                                         follow: {
                                            impact(style: .soft)
                                            if let text = user.username {
                                                if !self.isFriend(text: text) {
                                                    self.followUser(text: text)
                                                } else {
                                                    self.unfollowUser(text: text)
                                                }
                                            }
                            })
                        }
                        .opacity(self.state.animateAddFriend && self.text.isEmpty ? 1 : 0)
                    } else {
                        HStack {
                            Text("follow friends to\nlisten to their latest\nsups")
                                .modifier(TextModifier(size: 30, font: Font.ttNormsBold))
                                .multilineTextAlignment(.leading)
                                .opacity(self.state.animateAddFriend ? 1 : 0)
                            Spacer()
                        }
                        .padding(.leading, 10)
                    }

                    Spacer().frame(height: 20)
                    HStack {
                        Text("don’t know a friend’s username? message them a request")
                            .modifier(TextModifier(size: 17, font: Font.textaBold, color: Color.secondaryTextColor))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(1)
                            .opacity(self.state.animateAddFriend && self.text.isEmpty ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2))
                        Spacer()
                    }
                    .padding(.leading, 10)
                    Spacer().frame(height: 5)
                }
                .frame(width: screenWidth - 40)

                Spacer().frame(height: 20)
                Button(action: {
                    impact(style: .soft)
                    onPresent$.send()
                }) {
                    HStack (spacing: 20) {
                        ZStack {
                            Circle()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.greenAccentColor)
                            Image("startcall-imessage")
                                .renderingMode(.template)
                                .foregroundColor(Color.white )
                        }
                        Text("iMessage")
                            .modifier(TextModifier(size: 20, font: Font.textaAltBold, color: Color.white))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .foregroundColor(Color.greenDarkColor)
                            .frame(width: screenWidth, height: 72)
                    )
                }
                .buttonStyle(ButtonBounceLight())
                .opacity(self.state.animateAddFriend && self.text.isEmpty ? 1 : 0)
                .animation(.easeInOut(duration: 0.2))
                .scaleEffect(self.state.animateAddFriend && self.text.isEmpty ? 0.9 : 1)
                .animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0))

                Spacer()
                Spacer().frame(height: isIPhoneX ? 50 : 20)
            }

            VStack (spacing: 0) {
                ZStack (alignment: .bottom) {
                    Color.backgroundColor
                        .frame(width: screenWidth, height: isIPhoneX ? 125 : 90)
                        .shadow(color: Color.backgroundColor.opacity(0.5), radius: 12, x: 0, y: 0)

                    HStack (spacing: 5) {
                        ZStack {
                            if self.text.isEmpty {
                                HStack {
                                    Text("enter username")
                                        .modifier(TextModifier(size: 20, font: Font.textaAltBold))
                                        .padding(.leading, 0)
                                        .padding(.bottom, 4)
                                    Spacer()
                                }
                            }

                            TextView(isFirstResponder: self.keyboardOpen,
                                     returnKeyClosesKeyboard: true,
                                     autoCap: false,
                                     autoCorrect: false,
                                     spellCheck: false,
                                     text: $text,
                                     didEditing: $isTyping,
                                     blackText: false)
                                .padding(.top, 9)
                                .accentColor(Color.yellowAccentColor)
                                .padding(.leading, 0)
                        }
                        .padding(.horizontal, 20)
                        .frame(width: screenWidth - 140, height: 52)
                        .background(Capsule().foregroundColor(Color.cellBackground))
                        .opacity(state.animateAddFriend ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2))
                        .scaleEffect(state.animateAddFriend ? 1 : 0.95)
                        .animation(Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0).speed(0.8))

                        Spacer()

                        Button(action: { self.closeAddFriend() } ){
                            Text("cancel")
                                .modifier(TextModifier(size: 21, font: Font.textaAltBlack, color: Color.primaryTextColor))
                                .frame(height: 52)
                        }
                        .opacity(state.animateAddFriend ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2))
                        .scaleEffect(state.animateAddFriend ? 1 : 0.6)
                        .animation(Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0).speed(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, isIPhoneX ? 15 : 10)
                }

                Spacer()
            }

            VStack {
                Spacer()
                Button(action: {
                    impact(style: .soft)
                    self.addUser()
                }) {
                    HStack (spacing: 15){
                        Text("follow")
                            .modifier(TextModifier(size: 22, font: Font.textaAltBlack, color: Color.backgroundColor))
                            .padding(.top, 1)
                    }
                    .background(
                        Color.yellowAccentColor
                            .frame(width: 220, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                    )
                        .opacity(self.text.isEmpty ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3))
                        .scaleEffect(self.text.isEmpty ? 0.9 : 1)
                        .animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0))
                }
                .buttonStyle(ButtonBounceLight())

                Spacer().frame(height: isTyping ? (isIPhoneX ? 330 : 265) : (isIPhoneX ? 70 : 60))
            }
            .alert(isPresented: self.$showNotification) {
                Alert(title: Text(self.notification),
                      message: Text(""),
                      dismissButton: .default(Text("👍👌"))
                )
            }
            MessageComposeView(
                body: "I want to follow you on sup. What's your username?",
                onPresent$: onPresent$
            ).frame(width: 0, height: 0)

            Spacer()
        }
        .frame(width: screenWidth, height: screenHeight)
         .onDisappear() {
            self.keyboardOpen = false
        }
    }
}
