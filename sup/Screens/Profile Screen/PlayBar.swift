//
//  PlayBar.swift
//  sup
//
//  Created by Justin Spraggins on 5/2/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct PlayBar: View {
    @ObservedObject var state: AppState
    @Binding var value: Double
    let isPlaying: Bool
    let duration: Double
    let width: CGFloat

    private func pausePlayback() {
        if self.state.audioPlayer.isPlaying {
            self.state.audioPlayer.pausePlayback()
        }
    }

    var body: some View {
        HStack {
            CustomSlider(value: self.value, range: (0, 1), knobWidth: 20,
                         action: {value in
                            self.value = value
                            self.setValue()
                            self.pausePlayback()
            }) { modifiers in
                ZStack {
                    Group {
                        Color.white.opacity(0.3).blendMode(.overlay)
                            .modifier(modifiers.barRight)
                        Color.white
                            .modifier(modifiers.barLeft)
                    }
                    .cornerRadius(4)

                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(Color.white)
                        .modifier(modifiers.knob)
                }
            }
            .frame(width: width, height: 8)
        }
        .padding(.horizontal, 15)
        .onReceive(self.state.audioPlayer.progressWillChange.eraseToAnyPublisher()) { progress in
            if self.isPlaying {
                self.value = progress
            }
        }
    }

    func calculateValue() -> Double {
        //let value = self.duration * self.value // To increase
        let value = self.duration - (self.value * self.duration) // To decrease
        return value
    }

    func setValue() {
        self.state.audioPlayer.audioPlayer?.currentTime = self.value * self.duration
    }
}

struct HighlightPlayBar: View {
    @ObservedObject var state: AppState
    @Binding var progress: CGFloat?
    @Binding var value: Double
    @State var playingClip = false
    let isPlaying: Bool
    let duration: Double
    let width: CGFloat
    let sup: Sup
    var onPlay: ((Sup) -> Void)? = nil
    var onPause: ((Sup) -> Void)? = nil
    
    private func isPlayingClip() -> Bool {
        self.state.audioPlayer.playingURL == sup.url && self.state.audioPlayer.isPlaying
    }

    var body: some View {
        HStack {
            CustomSlider(value: self.value, range: (0, 1), knobWidth: 46,
                         action: {value in
                            self.value = value
                            self.setValue()
                            self.pausePlayback()
            }) { modifiers in
                ZStack {
                    Group {
                        Color.black.opacity(0.2)
                            .modifier(modifiers.barRight)
                        Color.black.opacity(0.2)
                            .modifier(modifiers.barLeft)
                    }
                    .cornerRadius(13)

                    VStack {
                        Button(action: {
                            impact(style: .soft)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if self.isPlayingClip() {
                                    self.onPause?(self.sup)
                                } else {
                                    self.onPlay?(self.sup)
                                }
                            }
                        }) {
                            ZStack {
                                BackgroundBlurView(style: .prominent)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                Image(self.isPlayingClip() ? "share-pause" : "inbox-play")
                                    .renderingMode(.template)
                                    .foregroundColor(.white)
                                if self.isPlayingClip()  {
                                    CircularProgressBar(
                                        circleProgress: self.$progress,
                                        label: .constant(nil),
                                        hasBackground: false,
                                        completedStroke: Color.white,
                                        circleSize: 32,
                                        strokeWidth: 6
                                    )

                                }
                            }
                        }
                        .buttonStyle(ButtonBounceLight())
                        Capsule()
                            .frame(width: 46, height: 26)
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 0)
                        Spacer().frame(height: 48)
                    }
                    .padding(.bottom, 9)
                    .modifier(modifiers.knob)
                }
            }
            .frame(width: width, height: 26)
        }
        .padding(.horizontal, 15)
        .onReceive(self.state.audioPlayer.progressWillChange.eraseToAnyPublisher()) { progress in
            if self.isPlaying {
                self.value = progress
            }
        }
    }

    func calculateValue() -> Double {
        //let value = self.duration * self.value // To increase
        let value = self.duration - (self.value * self.duration) // To decrease
        return value
    }

    func setValue() {
        self.state.audioPlayer.audioPlayer?.currentTime = self.value * self.duration
    }
    
    func pausePlayback() {
        if self.state.audioPlayer.isPlaying {
            self.state.audioPlayer.pausePlayback()
        }
    }
}
