//
//  UserProfileCard.swift
//  sup
//
//  Created by Justin Spraggins on 5/5/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import FirebaseStorage
import OneSignal
import SDWebImageSwiftUI
import SwiftUI

struct UserProfileCard: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var state: AppState
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    @State private var profileSups: [Sup]? = nil
    @State private var loadingURL: URL? = nil
    @State var showNotification = false
    @State var notification = "there was an error"
    @State var showActionSheet = false
    @State var animateBitmoji = false
    var showShareCard: (() -> Void)? = nil
    let cardHeight: CGFloat = 328
    @State var cardState = CGSize.zero
    var onClose: (() -> Void)? = nil

    private func isFriend() -> Bool {
        self.state.friends.contains(where: {
            $0.username == self.state.selectedUser?.username
        })
    }

    func addUser() {
        if self.state.friends.count < 9 {
            if let user = self.state.selectedUser {
                guard let username = self.state.currentUser?.username else { return }
                Friend.create(username: username, friendnames: [user.username!]) { friend in
                    self.state.friendDidAdd.send(true)
                    self.sendPush(user: self.state.selectedUser!)
                }
            }
        } else {
            self.show(note: "you are already following 8 friends, remove a friend if you want to follow a new friend")
        }
    }

    func removeUser() {
        guard let username = self.state.currentUser?.username else { return }
        guard let selectedUser = self.state.selectedUser else { return }
        guard let selectedUsername = selectedUser.username else { return }
        Friend.delete(username: username, friendnames: [selectedUsername]) { _ in
            self.state.friendDidAdd.send(true)
        }
    }

    private func sendPush(user: User) {
        guard let username = self.state.currentUser?.username else { return }
        var playerIds = [String]()
        playerIds.append(user.oneSignalPlayerId ?? "")
        OneSignal.postNotification(
            [
                "contents": ["en": "\(username) followed you"],
                "include_player_ids": playerIds
            ]
        )
    }

    private func show(note: String) {
        self.notification = note
        self.showNotification = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showNotification = false
        }
    }

    private func getUserSups(username: String) {
        User.get(username: username) { user in
            self.state.selectedMention = nil
            self.state.selectedUser = user
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                Sup.allPublic(
                    userID: self.state.selectedUser?.uid ?? "",
                    username: username
                ) { sups in
                    self.profileSups = sups.sorted(by: { $0.created.compare($1.created) == .orderedDescending
                    })
                }
            }
        }
    }

    private func getUser() {
        User.get(username: self.state.selectedSup?.username ?? "") { user in
            self.state.selectedUser = user
        }
    }

    private func getSups() {
        Sup.allPublic(
            userID: self.state.selectedSup?.userID ?? "",
            username: self.state.selectedSup?.username ?? ""
        ) { sups in
            self.profileSups = sups.sorted(by: {
                $0.created.compare($1.created) == .orderedDescending
            })
        }
    }

    private var selectedAvatarImage: WebImage? {
        if let url = self.state.selectedUser?.avatarUrl {
            guard let url = URL(string: url) else { return nil }
            return WebImage(url: url)
        }

        return nil
    }

    private func closeUserProfile() {
        self.onClose?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.state.selectedUser = nil
            self.profileSups?.removeAll()
            self.profileSups = nil
        }
    }

    func rateUs() {
        impact(style: .soft)
        let url = URL(string: "https://apps.apple.com/us/app/sup-bitesize-podcasts/id1502204715?action=write-review")!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Capsule().frame(width: 30, height: 8)
                    .foregroundColor(Color.white.opacity(0.6))
                    .onTapGesture { self.closeUserProfile() }
                    .padding(.top, 12)

                Spacer().frame(height: 15)
                HStack {
                    ZStack {
                        Spacer().frame(width: 50, height: 50)
                        self.selectedAvatarImage?
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                    }
                    Button(action: {}) {
                        Text("\(self.state.selectedUser?.username ?? "")")
                            .modifier(TextModifier(size: 22))
                            .lineLimit(0)
                            .truncationMode(.tail)
                            .animation(nil)
                    }
                    .disabled(true)

                    Spacer()

                    if self.state.selectedUser?.username == "sup"  {
                        Button(action: { self.rateUs() }) {
                            HStack (spacing: 11) {
                                Text("rate us")
                                    .modifier(TextModifier(size: 20, font: Font.textaAltHeavy, color: Color.yellowAccentColor))
                            }
                            .padding(.horizontal, 22)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color.yellowDarkColor.opacity(0.3)))
                        }
                        .buttonStyle(ButtonBounce())
                    } else {
                        Button(action: {
                            impact(style: .soft)
                            if !self.isFriend() {
                                self.addUser()
                            } else {
                                self.showActionSheet = true
                            }
                        }) {
                            HStack (spacing: 11) {
                                Text(self.isFriend() ? "following" : "follow")
                                    .modifier(TextModifier(size: 19,
                                                            font: Font.textaAltHeavy,
                                                            color: self.isFriend() ? Color.white.opacity(0.6) : Color.backgroundColor))
                                .animation(nil)
                            }
                            .padding(.horizontal, 22)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundColor(self.isFriend() ? Color.black.opacity(0.3) : Color.yellowAccentColor))
                        }
                        .buttonStyle(ButtonBounce())
                        .alert(isPresented: self.$showNotification) {
                            Alert(title: Text(self.notification),
                                    message: Text(""),
                                    dismissButton: .default(Text("👍👌"))
                            )
                        }
                        .actionSheet(isPresented: self.$showActionSheet) {
                            ActionSheet(title: Text("@\(self.state.selectedUser?.username ?? "")"),
                                        message: Text("Are you sure you want to remove your friend?"),
                                        buttons: [
                                            .destructive(Text("Remove friend")) { self.removeUser() },
                                            .cancel()
                            ])
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 20)
                HStack {
                    Text("latest sups")
                        .modifier(TextModifier(size: 19, font: Font.textaAltBold, color: Color.white.opacity(0.8)))
                    Spacer()
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack (spacing: 10) {
                        if self.profileSups == nil {
                            ForEach(0..<6) { value in
                                ProfilePlaceholderLoading(isUserProfile: .constant(true))
                            }
                        } else if self.profileSups != nil && self.profileSups!.isEmpty {
                            ProfilePlaceholder(isUserProfile: .constant(true))
                        } else if self.profileSups != nil && !self.profileSups!.isEmpty {
                            ForEach(self.profileSups!) { item in
                                ProfileSup(
                                    state: self.state,
                                    isUserProfile: .constant(true),
                                    loadingURL: self.loadingURL,
                                    url: item.url,
                                    image: item.avatarUrl,
                                    cover: item.coverArtUrl,
                                    username: item.username,
                                    description: item.description,
                                    date: DateTimeHelpers.date(from: item.created),
                                    sup: item,
                                    onPlay: { sup in
                                        DispatchQueue.main.async {
                                            self.state.playingSup = sup
                                            self.state.selectedSup = sup
                                            self.closeUserProfile()
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 100)
                Spacer()
            }
            .padding(.top, 12)
            .frame(width: screenWidth, height: cardHeight)
            .background(
                BackgroundBlurView(style: .systemUltraThinMaterialLight)
                    .clipShape(RoundedRectangle(cornerRadius: isIPhoneX ? 30 : 18))
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
                            self.closeUserProfile()
                            self.cardState = CGSize.zero
                        } else {
                            self.cardState = CGSize(width: 0, height: 0)
                        }
                })
        }
        .frame(width: screenWidth, height: screenHeight)
        .transition(.move(edge: .bottom))
        .animation(.spring())
        .onReceive(self.state.showUserProfile$) { isShowing in
            if isShowing {
                if let mention = self.state.selectedMention {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        self.getUserSups(username: mention)
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            self.animateBitmoji = true
                        }
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        self.getUser()
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            self.animateBitmoji = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self.getSups()
                            }
                        }
                    }
                }
            } else {
                self.closeUserProfile()
                self.state.audioPlayer.stopPlayback()
                self.animateBitmoji = false
            }
        }
    }
}
