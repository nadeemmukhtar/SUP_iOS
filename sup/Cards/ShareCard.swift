//
//  ShareCard.swift
//  sup
//
//  Created by Justin Spraggins on 3/1/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import Combine
import MessageUI
import SDWebImageSwiftUI

private let supBaseURL = "https://listen.onsup.fyi/sups/"
private let onPresent$ = PassthroughSubject<Void, Never>()

struct ShareCard: View {
    @ObservedObject var state: AppState
    @EnvironmentObject var audioPlayer: AudioPlayer
    @State private var initialState = true
    @State private var showingShare = false
    @State private var loadingYouTube = false
    @State private var isDeleting = false
    let sup: Sup
    let image: URL
    let username: String

    @State var cardState = CGSize.zero
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)

    var onClose: (() -> Void)? = nil
    var showUserProfile: (() -> Void)? = nil
    let cardHeight: CGFloat = 305
    @State var showAlert = false
    @State var showSaveAlert = false
    @State var showCopyAlert = false
    @State var showDownloadAlert = false
    @State var showTikTokAlert = false

    let cellColor: Color = Color.cardCellBackground
    let pColor: Color = Color.white

    var showReport: Bool {
        self.sup.userID != self.state.currentUser?.uid && !self.sup.guests.contains(self.state.currentUser?.username ?? "")
    }

    var showViewProfile: Bool {
        self.sup.userID != self.state.currentUser?.uid
    }

    var isCurrentUser: Bool {
        self.sup.userID == self.state.currentUser?.uid
    }

    private var duration: Double {
        AudioTime(duration: sup.duration, audioPlayer: audioPlayer).call()
    }

    var isLoading: Bool {
        self.loadingYouTube
    }

    var body: some View {
        VStack {
            Spacer()
            VStack (spacing: 0) {
                ZStack {
                    Capsule().frame(width: 30, height: 8)
                        .foregroundColor(Color.white.opacity(0.1))
                    Capsule().frame(width: 30, height: 8)
                        .foregroundColor(Color.white)
                }
                .onTapGesture {
                    if !self.isLoading {
                        self.onClose?()
                    }
                }

                Spacer().frame(height: 25)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack (alignment: .top, spacing: 10) {
                        Spacer()
                        ShareCardHostProfile(image: self.image,
                                          username: self.username,
                                          tapAction: {
                                            impact(style: .soft)
                                            if self.showViewProfile {
                                                self.showUserProfile?()
                                            }
                        })
                        ForEachWithIndex(self.sup.guests, id: \.self) { index, item in
                            ShareCardProfiles(image: self.sup.guestAvatars[index],
                                              username: item,
                                              tapAction: {
                                                impact(style: .soft)
                                                if self.showViewProfile {
                                                    self.state.selectedMention = item
                                                    self.showUserProfile?()
                                                }
                            })
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 90)
                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack (spacing: 4) {
                            VStack {
                                Spacer()
                                ZStack {
                                    ShareCardButton(
                                        image: self.showReport ? "share-report" : self.isDeleting ? "" : "share-delete",
                                        tint: self.pColor,
                                        action: {
                                            self.state.audioPlayer.stopPlayback()
                                            if self.showReport {
                                                self.showAlert = true
                                            } else {
                                                self.removeSup()
                                            }
                                    })
                                        .alert(isPresented: self.$showAlert) {
                                            Alert(title: Text("reported"),
                                                  message: Text("thank you for reporting this sup. our policy is to remove any content deemed inappropriate within 24hrs."),
                                                  dismissButton: .default(Text("okay")) {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                        self.onClose?()
                                                    }
                                                }
                                            )
                                    }
                                    .foregroundColor(Color.redColor)

                                    if self.isDeleting {
                                        ZStack {
                                            Spacer()
                                                .frame(width: 70, height: 70)
                                            LoaderCircle(size: 26, innerSize: 20, isButton: true)
                                        }
                                    }
                                }
                                ZStack {
                                    Text(self.showReport ? "report" : "delete")
                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white.opacity(0.1)))
                                    Text(self.showReport ? "report" : "delete")
                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white))
                                        .blendMode(.overlay)
                                }
                                Spacer()
                            }
                            .frame(width: 80)

                            VStack {
                                ZStack {
                                    ShareCardButton(
                                        image: "settings-twitter",
                                        tint: self.pColor,
                                        action: {
                                            SupAnalytics.shareTwitter()
                                            self.showingShare.toggle()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                self.onClose?()
                                            }
                                    })
                                        .sheet(isPresented: self.$showingShare) {
                                            ShareSheet(activityItems: ["tap the link to listen to this sup 🎧 \(supBaseURL)\(self.sup.id)"])
                                    }
                                }

                                ZStack {
                                    Text("twitter")
                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white.opacity(0.1)))
                                        .animation(nil)
                                    Text("twitter")
                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white))
                                        .animation(nil)
                                        .blendMode(.overlay)
                                }
                                .frame(height: 20)
                            }
                            .frame(width: 80)

                            //                        if self.state.isAdmin {
                            //                            VStack {
                            //                                ZStack {
                            //                                    ShareCardButton(
                            //                                        image: self.loadingYouTube ? "" : "share-youtube",
                            //                                        tint: self.pColor,
                            //                                        action: {
                            //                                            self.state.photosPermissions { allowed in
                            //                                                if allowed {
                            //                                                    self.loadingYouTube = true
                            //                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            //                                                        self.presentYoutube { _ in
                            //                                                            self.openYoutube()
                            //                                                        }
                            //                                                    }
                            //                                                } else {
                            //                                                    // show alert
                            //                                                }
                            //                                            }
                            //                                    }).animation(nil)
                            //
                            //                                    if self.loadingYouTube {
                            //                                        ZStack {
                            //                                            Spacer().frame(width: 70, height: 70)
                            //                                            LoaderCircle(size: 26, innerSize: 20, isButton: true)
                            //                                        }
                            //                                    }
                            //                                }
                            //
                            //                                ZStack {
                            //                                    Text(self.loadingYouTube  ? "exporting..." : "youtube")
                            //                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white.opacity(0.1)))
                            //                                        .animation(nil)
                            //                                    Text(self.loadingYouTube  ? "exporting..." : "youtube")
                            //                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white))
                            //                                        .animation(nil)
                            //                                        .blendMode(.overlay)
                            //                                }
                            //                            }
                            //                            .frame(width: 80)
                            //                        }

                            VStack {
                                Spacer()
                                ShareCardButton(
                                    image: "share-snapchat",
                                    tint: self.pColor,
                                    action: {
                                        self.presentSnapchat()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.onClose?()
                                        }
                                })
                                ZStack {
                                    Text("snapchat")
                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white.opacity(0.1)))
                                    Text("snapchat")
                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white))
                                        .blendMode(.overlay)
                                }
                                Spacer()
                            }
                            .frame(width: 80)


                            VStack {
                                Spacer()
                                ShareCardButton(
                                    image: "share-iMessage",
                                    tint: self.pColor,
                                    action: {
                                        onPresent$.send()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.onClose?()
                                        }
                                }
                                )
                                ZStack {
                                    Text("iMessage")
                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white))
                                    Text("iMessage")
                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white.opacity(0.1)))
                                        .blendMode(.overlay)
                                }
                                Spacer()
                            }
                            .frame(width: 80)


                            VStack {
                                Spacer()
                                ShareCardButton(
                                    image: "invite-copy",
                                    tint: self.pColor,
                                    action: {
                                        let url = "\(supBaseURL)\(self.sup.id)"
                                        let pasteboard = UIPasteboard.general
                                        pasteboard.string = url
                                        self.showCopyAlert = true
                                }
                                )
                                    .alert(isPresented: self.$showCopyAlert) {
                                        Alert(title: Text("copied to clipboard"),
                                              message: Text("you can now paste the sup url anywhere"),
                                              dismissButton: .default(Text("thnx")) {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    self.onClose?()
                                                }
                                            })
                                }
                                ZStack {
                                    Text("copy")
                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white.opacity(0.1)))
                                    Text("copy")
                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white))
                                        .blendMode(.overlay)
                                }
                                Spacer()
                            }
                            .frame(width: 80)

                            if self.isCurrentUser {
                                VStack {
                                    Spacer()
                                    ShareCardButton(
                                        image: "download-icon",
                                        tint: self.pColor,
                                        action: {
                                            let pasteboard = UIPasteboard.general
                                            pasteboard.string = self.sup.url.absoluteString
                                            self.showDownloadAlert = true

                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                self.onClose?()
                                            }
                                    }
                                    )
                                        .alert(isPresented: self.$showDownloadAlert) {
                                            Alert(title: Text("copied"),
                                                  message: Text("audio file url saved to your clipboard.\n\npro tip: you can paste this in the Chrome browser to download"),
                                                  dismissButton: .default(Text("thnx")) {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                        self.onClose?()
                                                    }
                                                })
                                    }
                                    ZStack {
                                        Text("download")
                                            .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white.opacity(0.1)))
                                        Text("download")
                                            .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white))
                                            .blendMode(.overlay)
                                    }
                                    Spacer()
                                }
                                .frame(width: 80)
                            }

                            VStack {
                                Spacer()
                                ShareCardButton(
                                    image: "nav-more",
                                    tint: self.pColor,
                                    action: {
                                        self.showingShare.toggle()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.onClose?()
                                        }
                                }
                                )
                                    .sheet(isPresented: self.$showingShare) {
                                        ShareSheet(activityItems: ["tap the link to listen to this sup 🎧 \(supBaseURL)\(self.sup.id)"])
                                }
                                ZStack {
                                    Text("more")
                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white.opacity(0.1)))
                                    Text("more")
                                        .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white))
                                        .blendMode(.overlay)
                                }
                                Spacer()
                            }
                            .frame(width: 80)

                        }
                        .padding(.horizontal, 20)
                        .frame(maxHeight: .infinity)
                    }
                    .frame(height: 160)
                }
                .frame(height: 120)

                Spacer()

                MessageComposeView(
                    body: "tap the link to listen to this sup 🎧 \(supBaseURL)\(self.sup.id)",
                    onPresent$: onPresent$
                ).frame(width: 0, height: 0)
            }
            .padding(.top, 12)
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
                            if !self.isLoading {
                                self.onClose?()
                            }
                            self.cardState = CGSize.zero
                        } else {
                            self.cardState = CGSize(width: 0, height: 0)
                        }
                })
        }
        .frame(width: screenWidth, height: screenHeight)
        .transition(.move(edge: .bottom))
        .animation(.spring())
    }

    func savePlaylist(callback: @escaping (Playlist) -> Void) {
        guard let userID = self.state.currentUser?.uid else {
            return AuthService.logout() {
                self.state.isOnboarding = true
                self.state.currentUser = nil
            }
        }

        if !self.state.profilePlaylist.contains(where: { $0.id == self.sup.id }) {
            Playlist.create(userID: userID, sup: self.sup) { savedPlaylist in
                self.state.profilePlaylist.append(self.sup)
                callback(savedPlaylist)
            }
        }
    }

    func removeSup() {
        self.isDeleting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            Sup.update(sup: self.sup) { sup in
                self.state.supDidDelete.send(sup)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isDeleting = false
                }
            }
        }
    }
    
    func openYoutube() {
        self.loadingYouTube = false
        guard let url = URL(string: "youtube://") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.onClose?()
        }
    }
}

// MARK: The message part
extension ShareCard {
    private func presentSnapchat() {
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        let url = "\(supBaseURL)\(self.sup.id)"
        SocialManager.sharedManager.postToSnapchat(sup: sup, url: url, vc: vc)
    }

    private func presentInstagramStories(completion: @escaping (Bool) -> Void) {
        let startTime = self.state.audioPlayer.audioPlayer?.currentTime ?? 0
        let endTime = (startTime + 15 <= duration) ? startTime + 15 : duration
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postToInstagramStoriesImage(sup: sup, startTime: startTime, endTime: endTime, vc: vc, completion: completion)
    }

    private func presentYoutube(completion: @escaping (Bool) -> Void) {
        let startTime = 0.0
        let endTime = duration
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postToYoutube(sup: sup, startTime: startTime, endTime: endTime, vc: vc, completion: completion)
    }
}


struct ShareCardProfiles: View {
    let image: String
    let username: String
    var tapAction: (() -> Void)? = nil

    var body: some View {
        Button(action: { self.tapAction?() }) {
            HStack {
                WebImage(url: URL(string: image))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .padding(.bottom, 2)

                Text(username)
                    .modifier(TextModifier(size: 18))
            }
            .padding(.leading, 15)
            .padding(.trailing, 25)
            .frame(height: 56)
            .background(
                BackgroundBlurView(style: .prominent)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 25)))
        }
        .buttonStyle(ButtonBounceLight())
    }
}

struct ShareCardHostProfile: View {
    let image: URL
    let username: String
    var tapAction: (() -> Void)? = nil

    var body: some View {
        Button(action: { self.tapAction?() }) {
            HStack {
                WebImage(url: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .padding(.bottom, 2)

                Text(username)
                    .modifier(TextModifier(size: 18))
            }
            .padding(.leading, 15)
            .padding(.trailing, 25)
            .frame(height: 56)
            .background(
                BackgroundBlurView(style: .prominent)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 25)))
        }
        .buttonStyle(ButtonBounceLight())
    }
}
