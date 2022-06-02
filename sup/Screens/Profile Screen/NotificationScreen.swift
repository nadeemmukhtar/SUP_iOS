//
//  NotificationScreen.swift
//  sup
//
//  Created by Justin Spraggins on 8/7/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct NotificationScreen: View {
    @ObservedObject var state: AppState
    @State private var comments: [Comment]? = nil
    @State private var loadingURL: URL? = nil
    @State private var isReply = false

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

    private func getAllComments() {
        guard let username = self.state.currentUser?.username else { return }
        Comment.allAdded(username: username) { comments in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.state.allComments = self.recentComments(comments: comments)
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

    private func recentComments(comments: [Comment]) -> [Comment] {
        return comments.sorted(by: {
            $0.expireAt.compare($1.expireAt) == .orderedDescending
        })
    }

    private func hasLatest() -> Bool {
        guard let latestComments = self.state.currentUser?.latestComments else { return false }
        return latestComments.count > 0
    }

    private func showReplyCard() {
        self.state.audioPlayer.pausePlayback()
        self.state.showMediaPlayerDrawer = false
        self.state.showReplyCard = true
    }
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack (spacing: 10) {
                    Spacer().frame(height: isIPhoneX ? 144 : 98)

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

                    Spacer()
                    Spacer().frame(width: screenWidth, height: isIPhoneX ? 170 : 150)
                }
                .frame(width: screenWidth, height: screenHeight)
                .edgesIgnoringSafeArea(.all)
            }
            VStack {
                Color.backgroundColor
                    .frame(width: screenWidth, height: isIPhoneX ? 145 : 95)
                //                    .shadow(color: Color.backgroundColor.opacity(0.5), radius: 10, x: 0, y: 0)
                Spacer()
            }
        }
        .frame(width: screenWidth, height: screenHeight)
        .background(Color.backgroundColor)
        .edgesIgnoringSafeArea(.all)
        .onAppear(perform: {
                /// For new and logout users
                self.getComments()
                self.getAllComments()
                self.addCommentListener()
            })
                .onReceive(self.state.userDidLoad$.eraseToAnyPublisher(), perform: { _ in
                    self.getComments()
                    self.getAllComments()
                    self.addCommentListener()
                })
            .onReceive(self.state.$moveToProfile) { isProfile in
                if isProfile {
                    self.getComments()
                }
            }
            .onReceive(self.state.audioPlayer.completeWillChange) { isComplete in
                if isComplete {
                    self.isReply = true
                }
            }
    }
}
