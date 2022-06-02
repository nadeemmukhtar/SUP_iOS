//
//  ProfileSup.swift
//  sup
//
//  Created by Justin Spraggins on 2/21/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProfileSup: View {
    @ObservedObject var state: AppState
    @EnvironmentObject var audioPlayer: AudioPlayer
    @Binding var isUserProfile: Bool
    @State var isPrivateSup = false

    let loadingURL: URL?
    let url: URL
    let image: URL
    let cover: URL
    let username: String
    let description: String
    let date: String
    let sup: Sup
    var onPlay: ((Sup) -> Void)? = nil
    var onPause: ((Sup) -> Void)? = nil
    var shareCard: ((Sup) -> Void)? = nil
    var tapProfile: ((Sup) -> Void)? = nil
    @State private var descs = [String]()

    private func isPlayingClip() -> Bool {
        self.audioPlayer.playingURL == url && self.audioPlayer.isPlaying
    }

    var body: some View {
        Button(action: {
            impact(style: .soft)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if self.isPlayingClip() {
                    self.onPause?(self.sup)
                } else {
                    self.onPlay?(self.sup)
                }
            }
        })
        {
            HStack (spacing: 5) {
                WebImage(url: cover)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .background(Color.backgroundColor.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .contentShape(Rectangle())
                Spacer().frame(width: 10)
                VStack (alignment: .leading, spacing: 6){

                    Text(date)
                        .modifier(TextModifier(size: 20, font: Font.textaAltBlack, color: Color.primaryTextColor))
                        .padding(.bottom, description.isEmpty ? 3 : -2)

                    if !description.isEmpty {
                        HStack {
                            Text(description)
                                .modifier(TextModifier(size: 19, font: Font.textaBold
                                    , color: isUserProfile ? Color.white.opacity(0.6) : Color.secondaryTextColor))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(1)
                            Spacer()
                        }
                        .padding(.bottom, 2)
                    }
                    HStack (spacing: 0) {
                        HStack(spacing: -8) {
                            WebImage(url: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())

                            ForEach(self.sup.guestAvatars, id: \.self) { value in
                                WebImage(url: URL(string: value))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            }
                        }
                        Spacer().frame(width: 10)
                        Text(username)
                            .modifier(TextModifier(size: 17, color: isUserProfile ? Color.white.opacity(0.6) : Color.secondaryTextColor))
                            .lineLimit(0)
                            .truncationMode(.tail)
                        Spacer()
                        if self.sup.isPrivate {
                            Image("profile-lock")
                                .renderingMode(.template)
                                .foregroundColor(isUserProfile ? Color.white.opacity(0.6) : Color.secondaryTextColor)
                        }
                    }
                }
                .onAppear {
                    let comps = self.description.components(separatedBy: .whitespacesAndNewlines)
                    for comp in comps {
                        self.descs.append(comp)
                    }
                }

                Spacer()
            }
            .padding(.leading, 14)
            .padding(.trailing, 14)
            .padding(.vertical, 14)
            .frame(width: isUserProfile ? screenWidth - 40 : screenWidth - 20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .foregroundColor(isUserProfile ? Color.black.opacity(0.2) : Color.cellBackground)
            )
        }
        .buttonStyle(ButtonBounceLight())
    }
}
