//
//  SnapchatInviteSticker.swift
//  sup
//
//  Created by Justin Spraggins on 6/20/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct SnapchatInviteSticker: View {
    var body: some View {
        ZStack {
            BackgroundColorView(color: Color.lightBackground)
            VStack(spacing: 0) {
                ZStack {
                    Image("snapchat-lanyard")
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 0)
                    VStack (spacing: 0) {
                        Spacer()
                        if AppDelegate.appState != nil {
                            ProfileAvatar(state: AppDelegate.appState!,
                                          currentUser: .constant(true),
                                          tapAction: { },
                                          size: 82)
                        }

                        Spacer().frame(height: 46)
                        Text("\(AppDelegate.appState?.currentUser?.username ?? "my") podcast")
                            .modifier(TextModifier(size: 15, font: Font.textaAltBlack, color: Color.backgroundColor))
                            .frame(width: 110)
                            .truncationMode(.tail)
                            .lineLimit(0)
                        Spacer().frame(height: 28)
                    }
                    .frame(width: 209, height: 495)
                }
                .zIndex(1)
                .padding(.top, -35)
                Spacer().frame(height: 20)
                Image("swipeUp-text")
                Spacer().frame(height: 30)
                Image("swipeup-arrow")
                    .renderingMode(.template)
                    .foregroundColor(Color.black)
                Spacer().frame(height: 10)
                Text("accept my guest pass")
                    .modifier(TextModifier(size: 20, color: Color.black))
            }
            .padding(.top, isIPhoneX ? -110 : -95)
        }
        .frame(width: screenWidth, height: screenHeight)
    }
}
