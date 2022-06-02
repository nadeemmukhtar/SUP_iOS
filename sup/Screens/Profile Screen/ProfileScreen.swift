//
//  ProfileScreen.swift
//  sup
//
//  Created by Justin Spraggins on 12/17/19.
//  Copyright © 2019 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import FirebaseStorage
import SDWebImageSwiftUI
import OneSignal

struct ProfileScreen: View {
    @ObservedObject var state: AppState
    @State private var profileSups: [Sup]? = nil
    @State private var comments: [Comment]? = nil
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    @State private var loadingURL: URL? = nil
    @State private var mySups = true
    @State private var inbox = false
    @State private var newMessage = true
    @State private var animateSups = true
    @State private var animateInbox = false
    @State private var hideNotifications = false
    @State private var isReply = false
    @State private var isListen = false
    @State private var isListener = false

    var tapUserProfile: (() -> Void)? = nil
    var tapSettings: (() -> Void)? = nil
    var tapCoins: (() -> Void)? = nil

    private let supWebsiteURL = "https://onsup.fyi"

    private func getSups() {
        Sup.all(
            userID: self.state.currentUser?.uid ?? "",
            username: self.state.currentUser?.username ?? ""
        ) { sups in
            self.profileSups = sups
        }
    }

    private func addSupListener() {
        guard let username = self.state.currentUser?.username else { return }
        Sup.listener(username: username) { sup in
            guard self.isListener else { self.isListener = true; return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.state.publishedSup = sup
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.state.showPublishSocials = true
                }
            }
        }
    }

    private func getComments() {
        guard let username = self.state.currentUser?.username else { return }
        Comment.all(supUsername: username) { comments in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.comments = self.recentComments(comments: comments)
            }

            /// Latest Comments
            DispatchQueue.global(qos: .background).async {
                var latestComments = comments.map({ $0.id })

                if let playedComments = self.state.currentUser?.playedComments {
                    latestComments = latestComments.filter({ !playedComments.contains($0) })
                }

                guard let userID = self.state.currentUser?.uid else { return }
                User.update(userID: userID, data: ["latestComments": latestComments]) { updated in
                    if updated {
                        let user = self.state.currentUser
                        user?.latestComments = latestComments
                        self.state.currentUser = user
                    }
                }
            }
        }
    }

    private func addCommentListener() {
        guard let username = self.state.currentUser?.username else { return }
        Comment.listener(supUsername: username) { comment in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.comments?.append(comment)
            }

            /// Latest Comments
            DispatchQueue.global(qos: .background).async {
                var latestComments = [comment.id]

                if let playedComments = self.state.currentUser?.playedComments {
                    latestComments = latestComments.filter({ !playedComments.contains($0) })
                }

                guard let userID = self.state.currentUser?.uid else { return }
                User.update(userID: userID, data: ["latestComments": latestComments]) { updated in
                    if updated {
                        let user = self.state.currentUser
                        user?.latestComments = latestComments
                        self.state.currentUser = user
                    }
                }
            }
        }
    }

    private func getAllComments() {
        guard let username = self.state.currentUser?.username else { return }
        Comment.allAdded(username: username) { comments in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.state.allComments = self.recentComments(comments: comments)
            }
        }
    }

    private func recentComments(comments: [Comment]) -> [Comment] {
        return comments.sorted(by: {
            $0.expireAt.compare($1.expireAt) == .orderedDescending
        })
    }

    private func updatePlayedComments() {
        guard let userID = self.state.currentUser?.uid else { return }
        guard var playedComments = self.state.currentUser?.playedComments else { return }
        guard var latestComments = self.state.currentUser?.latestComments else { return }

        playedComments.append(contentsOf: latestComments)
        latestComments.removeAll()

        User.update(userID: userID, data: ["playedComments": playedComments, "latestComments": latestComments]) { updated in
            if updated {
                let user = self.state.currentUser
                user?.playedComments = playedComments
                user?.latestComments = latestComments
                self.state.currentUser = user
            }
        }
    }

    private func hasLatest() -> Bool {
        guard let latestComments = self.state.currentUser?.latestComments else { return false }
        return latestComments.count > 0
    }

    private func tapMySups() {
        impact(style: .soft)
        self.animateSups = true
        self.animateInbox = false
        DispatchQueue.main.async {
            self.inbox = false
            self.mySups = true
        }
    }

    private func tapInbox() {
        impact(style: .soft)
        self.animateSups = false
        self.animateInbox = true
        DispatchQueue.main.async {
            self.inbox = true
            self.mySups = false

            if self.hasLatest() {
                self.updatePlayedComments()
            }
        }
    }

    var body: some View {
        ZStack {
            ScrollableView(self.$contentOffset, animationDuration: 0.5, action: { _ in }) {
                  VStack (spacing: 10) {
                      Spacer().frame(height: isIPhoneX ? 144 : 98)
                      ProfileHeader(state: self.state,
                                    tapCoins: { self.tapCoins?() },
                                    tapAction: { self.tapSettings?() })

                      HStack (spacing: 20) {
                          Button(action: { self.tapMySups() }){
                              Text("my sups")
                                  .modifier(TextModifier(size: 22, color: self.animateSups ? Color.white : Color.secondaryTextColor))
                          }
                          .buttonStyle(ButtonBounce())

//                          HStack (spacing: 10) {
//                              Button(action: { self.tapInbox() }){
//                                  Text("inbox")
//                                      .modifier(TextModifier(size: 22, color: self.animateInbox ? Color.white : Color.secondaryTextColor))
//                              }
//                              .buttonStyle(ButtonBounce())
//
//                              if self.hasLatest() {
//                                  Circle()
//                                      .foregroundColor(Color.redColor)
//                                      .frame(width: 7, height: 7)
//                                      .padding(.top, 1)
//                              }
//                          }
                          Spacer()
                      }
                      .padding(.horizontal, 28)
                      .padding(.top, 10)
                      .frame(width: screenWidth, height: 44)
                      .zIndex(10)

                      if self.mySups {
                          VStack (spacing: 10) {
                              Group {
                                  if self.profileSups == nil {
                                      ForEach(0..<2) { value in
                                        ProfilePlaceholderLoading(isUserProfile: .constant(false))
                                      }
                                  } else if self.profileSups != nil && self.profileSups!.isEmpty {
                                      ProfilePlaceholder(isUserProfile: .constant(false))
                                  } else if self.profileSups != nil && !self.profileSups!.isEmpty {
                                    ForEach(self.profileSups!) { item in
                                        ProfileSup(
                                            state: self.state,
                                            isUserProfile: .constant(false),
                                            loadingURL: self.loadingURL,
                                            url: item.url,
                                            image: item.avatarUrl,
                                            cover: item.coverArtUrl,
                                            username: item.username,
                                            description: item.description,
                                            date: DateTimeHelpers.date(from: item.created),
                                            sup: item,
                                            onPlay: { sup in
                                                self.state.playingSup = sup
                                                self.state.selectedSup = sup
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                    self.state.showMediaPlayer = true
                                                }
                                        },
                                            onPause: { sup in
                                                self.state.audioPlayer.pausePlayback()
                                                // self.state.selectedSup = sup
                                        })
                                    }
                                }
                                if SupUserDefaults.timesNotificationShown == 0 {
                                    VStack (spacing: 13) {
                                        Spacer().frame(height: 1)
                                        Button(action: {
                                            self.state.promptForPushPermissions()
                                            SupUserDefaults.timesNotificationShown = SupUserDefaults.timesNotificationShown + 1
                                            self.hideNotifications = true
                                            guard var coins = self.state.currentUser?.coins else { return }
                                            coins = coins + 100
                                            self.state.add(coins: coins) { _ in }
                                        }){
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 28)
                                                    .frame(width: 286, height: 62)
                                                    .foregroundColor(Color(#colorLiteral(red: 0.1098039216, green: 0.1529411765, blue: 0, alpha: 1)))

                                                HStack (spacing: 15) {
                                                    Image("profile-bell")
                                                        .renderingMode(.original)
                                                        .padding(.bottom, 2)
                                                    Text("enable notifications")
                                                        .modifier(TextModifier(size: 20, color: Color.yellowAccentColor))
                                                        .padding(.bottom, 1)
                                                }

                                            }
                                        }
                                        .buttonStyle(ButtonBounce())
                                        .opacity(self.hideNotifications ? 0 : 1)
                                        .animation(.easeInOut(duration: 0.3))
                                        .scaleEffect(self.hideNotifications ? 0.9 : 1)
                                        .animation(.spring())

                                        HStack {
                                            Text("to collect 100")
                                                .modifier(TextModifier(size: 17, color: Color.secondaryTextColor))

                                            Image("sup-coin")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 18, height: 18)
                                        }
                                        .opacity(self.hideNotifications ? 0 : 1)
                                        .animation(.easeInOut(duration: 0.3))
                                    }
                                }
                            }
                          }
                      }
                      else {
                          VStack (spacing: 10) {
                              Group {
                                  if self.comments == nil {
                                      InboxCellPlaceholderLoading()
                                  } else if self.comments != nil && self.comments!.isEmpty {
                                      InboxCellPlaceholder()
                                  } else if self.comments != nil && !self.comments!.isEmpty {
                                      ForEach(self.comments!) { comment in
                                          InboxCell(state: self.state,
                                                    isReply: self.$isReply,
                                                    isListen: comment.type == "listen",
                                                    loadingURL: self.loadingURL,
                                                    comment: comment,
                                                    onPlay: { comment in
                                                      self.state.audioPlayer.startPlayback(
                                                          audio: comment.audioFile,
                                                          loadingURL: self.$loadingURL)
                                          },        onPause: { comment in
                                              self.state.audioPlayer.pausePlayback()
                                          },
                                          onReply: { comment in
                                              self.state.selectedComment = comment
                                              self.showReplyCard()
                                          }
                                          )
                                      }
                                      Spacer().frame(height: 20)
                                      HStack {
                                          Image("footer-clock")
                                          Text("messages disappear in 24hrs")
                                              .modifier(TextModifier(size: 17, font: Font.textaBold, color: Color.secondaryTextColor))
                                      }
                                      Spacer().frame(height: 20)
                                  }
                              }
                          }
                      }
                  }

                  Spacer()
                  Spacer().frame(width: screenWidth, height: isIPhoneX ? 170 : 150)
              }

            if self.state.showReplyCard {
                SendMessageCard(state: self.state,
                                audioRecorder: .constant(AudioRecorder()),
                                isMessage: self.state.showMessageCard,
                                comment: self.state.selectedComment,
                                sup: self.state.selectedSup!,
                                onClose: { self.closeMessageCard()})
            }
        }
        .onAppear(perform: {
            /// For new and logout users
            self.getSups()
            self.addSupListener()
            self.getComments()
            self.getAllComments()
            self.addCommentListener()
        })
            .onReceive(self.state.userDidLoad$.eraseToAnyPublisher(), perform: { _ in
                self.getSups()
                self.addSupListener()
                self.getComments()
                self.getAllComments()
                self.addCommentListener()
            })
            .onReceive(self.state.supDidCreate.eraseToAnyPublisher()) { sup in
                self.getSups()
        }
        .onReceive(self.state.supDidDelete.eraseToAnyPublisher()) { sup in
            var sups = self.profileSups
            sups?.removeAll(where: { $0.id == sup.id })
            self.profileSups = sups
        }
        .onReceive(self.state.$moveToProfile) { isProfile in
            if isProfile {
                self.getSups()
                self.getComments()
            }
        }
        .onReceive(self.state.audioPlayer.completeWillChange) { isComplete in
            if isComplete {
                self.isReply = true
            }
        }
    }

    private func isPlayingClip() -> Bool {
        guard let sup = self.state.selectedSup else { return false }
        return self.state.audioPlayer.playingURL == sup.url && self.state.audioPlayer.isPlaying
    }

    private func showReplyCard() {
        self.state.audioPlayer.pausePlayback()
        self.state.showMediaPlayerDrawer = false
        self.state.showReplyCard = true
    }

    private func closeMessageCard() {
        impact(style: .soft)
        self.state.showReplyCard = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8){
            self.state.showMediaPlayerDrawer = true
        }
    }
}
