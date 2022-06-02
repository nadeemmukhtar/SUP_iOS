//
//  MediaPlayerDrawer.swift
//  sup
//
//  Created by Justin Spraggins on 5/15/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

private var renders = 0

struct MediaPlayerDrawer: View {
    @ObservedObject var state: AppState
    @EnvironmentObject var audioPlayer: AudioPlayer
    let loadingURL: URL?
    let visible: Bool
    let url: URL
    let sup: Sup
    var onTap: (() -> Void)? = nil
    var onPlay: ((Sup) -> Void)? = nil
    var onPause: ((Sup) -> Void)? = nil

    @State var isPlaying = false

    private func isPlayingClip() -> Bool {
        self.audioPlayer.playingURL == url && self.audioPlayer.isPlaying
    }

    var body: some View {
        if debugViewRenders {
            renders += 1
            print("MediaPlayerDrawer#body renders=\(renders)")
        }

        return VStack {
            Spacer()
            ZStack (alignment: .top) {
                BackgroundBlurView(style: .prominent)
                    .frame(width: screenWidth, height: isIPhoneX ? 177 : 157)
                    .cornerRadius(radius: 8, corners: [.topLeft, .topRight])
                    .shadow(color: Color.backgroundColor.opacity(0.1), radius: 15, x: 0, y: -10)

                Rectangle()
                    .foregroundColor(Color(sup.color.color()).opacity(0.5))
                    .frame(width: screenWidth, height: isIPhoneX ? 177 : 157)
                    .cornerRadius(radius: 8, corners: [.topLeft, .topRight])
                    .onTapGesture{
                        impact(style: .soft)
                        self.onTap?()
                        // self.state.audioPlayer.pausePlayback()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                            self.state.showMediaPlayer = true
                        }
                }

                HStack (spacing: 0){

                    Button(action: {
                        impact(style: .soft)
                        self.onTap?()
                        // self.state.audioPlayer.pausePlayback()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                            self.state.showMediaPlayer = true
                        }
                    }) {
                        ZStack {
                            WebImage(url: sup.coverArtUrl)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 9))
                                .contentShape(Rectangle())
                                .opacity(visible ? 1 : 0)
                                .animation(nil)
                            if loadingURL == sup.url {
                                ZStack {
                                    Circle()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(Color.black.opacity(0.2))
                                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y:0)
                                    LoaderCircle(size: 12, innerSize: 10, tint: .white)
                                }
                            }
                        }
                    }
                    .buttonStyle(ButtonBounceLight())
                    Spacer().frame(width: 14)

                    Button(action: {
                        impact(style: .soft)
                        self.onTap?()
                        // self.state.audioPlayer.pausePlayback()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                            self.state.showMediaPlayer = true
                        }
                    }) {
                        VStack (alignment: .leading, spacing: -1) {
                            if sup.description.isNotEmpty {
                                Text(sup.description)
                                    .modifier(TextModifier(size: 18, font: Font.textaBold, color: .white))
                                    .lineLimit(0)
                                    .truncationMode(.tail)
                                    .animation(nil)
                            }
                            ZStack {
                                Text(sup.username)
                                    .modifier(TextModifier(size: 18, font: Font.textaBold, color: Color.white.opacity(0.1)))
                                    .truncationMode(.tail)
                                    .animation(nil)
                                Text(sup.username)
                                    .modifier(TextModifier(size: 18, font: Font.textaBold, color: .white))
                                    .truncationMode(.tail)
                                    .animation(nil)
                                    .blendMode(.overlay)
                            }
                        }
                        .animation(nil)
                        .opacity(visible ? 1 : 0)
                    }
                    .buttonStyle(ButtonBounceNone())

                    Spacer()

                    ZStack {
                        Spacer().frame(width: 50, height: 50)
                        TintImageButton(
                            image: isPlayingClip() ? "playerDrawer-pause" : "playerDrawer-play",
                            background: Color.clear,
                            tint: .white,
                            action: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    if self.isPlayingClip() {
                                        self.onPause?(self.sup)
                                    } else {
                                        self.onPlay?(self.sup)
                                    }
                                }
                        })
                            .opacity(visible ? 1 : 0)
                    }
                }
                .padding(.top, 15)
                .padding(.leading, 15)
                .padding(.trailing, 25)
            }
        }
        .frame(width: screenWidth, height: screenHeight)
    }
}

struct MediaPlayerDrawerPlacholder: View {
    var body: some View {
        VStack {
            Spacer()
            ZStack (alignment: .top) {
                RoundedRectangle(cornerRadius: 9)
                    .foregroundColor(Color.mediaPlayerText)
                    .frame(width: screenWidth, height: isIPhoneX ? 120 : 85)
                    .shadow(color: Color.backgroundColor.opacity(0.4), radius: 10, x: 0, y: -4)

                HStack (spacing: 20){
                    Color.mediaPlayerText
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack (alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 180, height: 10)
                            .foregroundColor(Color.mediaPlayerText.opacity(0.4))
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 80, height: 10)
                            .background(Color.mediaPlayerText.opacity(0.4))
                    }

                    Spacer()
                    TintImageButton(
                        image: "playerDrawer-play",
                        background: Color.clear,
                        tint: Color.mediaPlayerText.opacity(0.4),
                        action: {})
                }
            }
            .padding(.top, isIPhoneX ? 15 : 10)
            .padding(.leading, 15)
            .padding(.trailing, 25)
        }
        .frame(width: screenWidth, height: screenHeight)
    }
}
