//
//  SnapchatGuestPassVideo.swift
//  sup
//
//  Created by Justin Spraggins on 7/16/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct SnapchatGuestPassVideo: View {
    @State var showUser = false

    var body: some View {
        VStack (spacing: 0) {
            Spacer().frame(height: 18)

            ZStack {
                if AppDelegate.appState != nil {
                    ProfileAvatar(
                        state: AppDelegate.appState!,
                        currentUser: .constant(true),
                        tapAction: {},
                        size: 230
                    )
                }
            }

            Spacer().frame(height: 134)

            Text("\(AppDelegate.appState?.currentUser?.username ?? "my")")
                .modifier(TextModifier(
                    size: 38,
                    font: Font.textaAltBlack,
                    color: Color.backgroundColor
                ))
                .frame(width: 440)
                .truncationMode(.tail)
                .lineLimit(0)
        }
        .frame(width: 500, height: 430)
    }
}
