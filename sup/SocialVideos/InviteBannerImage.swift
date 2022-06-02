//
//  InviteBannerImage.swift
//  sup
//
//  Created by Justin Spraggins on 6/22/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct InviteBannerImage: View {
    var body: some View {
        ZStack {
            Color.lightBackground
                .frame(width: 1200, height: 630)

            VStack {
                ZStack {
                    Image("sticker-inviteLanyard")
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 0)
                    VStack (spacing: 0) {
                        Spacer().frame(height: 255)
                        if AppDelegate.appState != nil {
                            ProfileAvatar(state: AppDelegate.appState!,
                                          currentUser: .constant(true),
                                          tapAction: { },
                                          size: 145)
                        }
                        Spacer().frame(height: 55)
                        Text("\(AppDelegate.appState?.currentUser?.username ?? "my")")
                            .modifier(TextModifier(size: 26, font: Font.textaAltBlack, color: Color.backgroundColor))
                            .frame(width: 260)
                            .truncationMode(.tail)
                            .lineLimit(0)
                    }
                }
                Spacer()
            }
            .frame(width: 1200, height: 630)
        }
    }
}
