//
//  ProfileNavigation.swift
//  sup
//
//  Created by Justin Spraggins on 3/6/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

private var renders = 0

struct ProfileNavigation: View {
    @ObservedObject var state: AppState

    private func showSettingsCard() {
        impact(style: .soft)
        self.state.audioPlayer.stopPlayback()
        self.state.showMediaPlayerDrawer = false
        self.state.showSettingsCard = true
    }

    private func showCoinsCard() {
        impact(style: .soft)
        self.state.audioPlayer.stopPlayback()
        self.state.showMediaPlayerDrawer = false
        self.state.showCoinsCard = true
    }

    var body: some View {
        if debugViewRenders {
            renders += 1
            print("ProfileNavigation#body renders=\(renders)")
        }

        return ZStack {
            ProfileScreen(
                state: state,
                tapSettings: { self.showSettingsCard() },
                tapCoins: { self.showCoinsCard() }
            )
            .frame(width: screenWidth, height: screenHeight)
            .edgesIgnoringSafeArea(.all)

            VStack {
                Color.backgroundColor
                    .frame(width: screenWidth, height: isIPhoneX ? 145 : 95)
//                    .shadow(color: Color.backgroundColor.opacity(0.5), radius: 10, x: 0, y: 0)
                Spacer()
            }
            .frame(width: screenWidth, height: screenHeight)
            .edgesIgnoringSafeArea(.all)
        }
    }
}
