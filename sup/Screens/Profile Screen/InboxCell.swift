//
//  InboxCell.swift
//  sup
//
//  Created by Justin Spraggins on 5/27/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct InboxCell: View {
    @ObservedObject var state: AppState
    @Binding var isReply: Bool
    let isListen: Bool
    let loadingURL: URL?
    let comment: Comment
    var onPlay: ((Comment) -> Void)? = nil
    var onPause: ((Comment) -> Void)? = nil
    var onReply: ((Comment) -> Void)? = nil

    private func isPlayingClip() -> Bool {
       self.state.audioPlayer.playingURL == comment.audioFile && self.state.audioPlayer.isPlaying
    }

    private func tapPlay() {
        impact(style: .soft)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if self.isPlayingClip() {
                self.onPause?(self.comment)
            } else {
                self.onPlay?(self.comment)
            }
        }
    }

    private func tapReply() {
        impact(style: .soft)
        self.onReply?(self.comment)
    }

    var body: some View {
        Button(action: {}) {
            HStack (spacing: 10) {
                WebImage(url: comment.avatarUrl)
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 38, height: 38)

                Text(isListen ? "\(comment.username) listened to: \(comment.supTitle)" : comment.type == "comment" ? "\(comment.username) sent you a message : \(comment.supTitle)" : "\(comment.username) replied to your comment : \(comment.supTitle)")
                    .modifier(TextModifier(size: 18, font: Font.textaBold, color: Color.primaryTextColor))

                Spacer()
                ZStack {
                    Button(action: { self.tapPlay() }){
                        ZStack {
                            Circle()
                                .foregroundColor(self.isPlayingClip() ? Color.yellowDarkColor : Color.yellowAccentColor)
                                .frame(width: 48, height: 48)

                            if loadingURL == comment.audioFile {
                                LoaderCircle(size: 16, innerSize: 16, isButton: true, tint: Color.backgroundColor)
                            }

                            Image(self.isPlayingClip() ? "inbox-pause" : "inbox-play")
                                .renderingMode(.template)
                                .foregroundColor(self.isPlayingClip() ? Color.yellowAccentColor : Color.backgroundColor)
                                .opacity(loadingURL == comment.audioFile ? 0 : 1)
                                .animation(.easeInOut(duration: 0.3))
                        }
                    }
                    .buttonStyle(ButtonBounce())
                    .opacity(!isReply && !isListen ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3))
                    .scaleEffect(!isReply && !isListen ? 1 : 0.4)
                    .animation(.spring())

                    Button(action: { self.tapReply() }){
                         ZStack {
                             Circle()
                                 .foregroundColor(Color(#colorLiteral(red: 0.02745098039, green: 0.2509803922, blue: 0.09803921569, alpha: 1)))
                                 .frame(width: 48, height: 48)

                             Image("inbox-reply")
                                 .renderingMode(.template)
                                 .foregroundColor(Color(#colorLiteral(red: 0.09803921569, green: 1, blue: 0.5803921569, alpha: 1)))
                         }
                     }
                     .buttonStyle(ButtonBounce())
                     .opacity(isReply && !isListen ? 1 : 0)
                     .animation(.easeInOut(duration: 0.3))
                     .scaleEffect(isReply && !isListen ? 1 : 0.4)
                     .animation(.spring())


                    ZStack {
                        Circle()
                            .foregroundColor(Color.white.opacity(0.1))
                            .frame(width: 48, height: 48)

                        Image("inbox-airpods")
                            .renderingMode(.template)
                            .foregroundColor(Color.white)
                    }
                    .opacity(isListen ? 1 : 0)


                    if self.isPlayingClip() {
                        CircularProgressBar(
                            circleProgress: .constant(nil),
                            label: .constant(nil),
                            hasBackground: false,
                            completedStroke: Color.yellowAccentColor,
                            circleSize: 38,
                            strokeWidth: 8
                        )
                    }
                }
            }
            .padding(.leading, 15)
            .padding(.trailing, 20)
            .padding(.vertical, 20)
            .frame(width: screenWidth - 20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .foregroundColor(Color.cellBackground)
            )
        }
        .buttonStyle(ButtonBounceNone())
    }
}

struct InboxCellPlaceholder: View {
    var body: some View {
        VStack (spacing: 12) {
            Spacer().frame(height: 40)
          Image("inbox-bigClock")
            .renderingMode(.template)
            .foregroundColor(Color.secondaryTextColor)
            Text("no new messages within the\nlast 24hrs")
                .modifier(TextModifier(size: 18, color: Color.secondaryTextColor))
                .multilineTextAlignment(.center)
                .lineSpacing(1.5)
        }
    }
}

struct InboxCellPlaceholderLoading: View {
    var body: some View {
        HStack (spacing: 15) {
            VStack (alignment: .leading, spacing: 10){
                Rectangle()
                    .frame(width: 140, height: 20)
                    .foregroundColor(Color.backgroundColor.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Rectangle()
                    .frame(width: 80, height: 20)
                    .foregroundColor(Color.backgroundColor.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            Spacer()
            Circle()
                .frame(width: 42, height: 42)
                .foregroundColor(Color.backgroundColor.opacity(0.8))
        }
        .padding(.leading, 30)
        .padding(.trailing, 20)
        .padding(.vertical, 20)
        .frame(width: screenWidth - 20)
        .background(Color.cellBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
