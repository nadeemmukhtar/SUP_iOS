//
//  RecentScreen.swift
//  sup
//
//  Created by Justin Spraggins on 5/28/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import FirebaseStorage

struct RecentScreen: View {
    @ObservedObject var state: AppState
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    @State private var latestSups = [Sup]()
    @State private var loadingURL: URL? = nil

    private func getLatestSups() {
        Sup.latest { sups in
            self.latestSups = sups
        }
    }

    var body: some View {
        ZStack {
            ScrollableView(self.$contentOffset, animationDuration: 0.5, action: { _ in }) {
                VStack (spacing: 10) {
                    Spacer().frame(height: isIPhoneX ? 144 : 98)
                    ForEach(self.latestSups) { item in
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
                            }).environmentObject(self.state.audioPlayer)
                    }
                }
                .frame(width: screenWidth)

                Spacer().frame(width: screenWidth, height: isIPhoneX ? 170 : 150)
            }
        }
        .frame(width: screenWidth, height: screenHeight)
        .background(Color.backgroundColor)
        //.offset(y: state.animateRecents ? 0 : screenHeight)
           .onAppear(perform: {
             self.getLatestSups()
         })
         .onReceive(self.state.userDidLoad$.eraseToAnyPublisher(), perform: { _ in
             self.getLatestSups()
         })
    }
}
