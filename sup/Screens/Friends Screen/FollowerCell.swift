//
//  FollowerCell.swift
//  sup
//
//  Created by Justin Spraggins on 6/22/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct FollowerCell: View {
    var user: User
    let isFriend: Bool
    var follow: () -> Void

    var body: some View {
        HStack (spacing: 12) {
            ZStack {
                WebImage(url: URL(string: user.avatarUrl ?? ""))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
            }
            Text(user.username ?? "")
                .modifier(TextModifier())
                .lineLimit(0)
                .truncationMode(.tail)
            Spacer()
            Button(action: { self.follow() }) {
                HStack (spacing: 8) {
                    Text(self.isFriend ? "following" : "follow")
                        .modifier(TextModifier(size: self.isFriend  ? 17 : 18,
                                               font: Font.textaAltHeavy,
                                               color: self.isFriend ? Color.secondaryTextColor : Color.backgroundColor))
                        .animation(nil)
                }
                .padding(.horizontal, 15)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(self.isFriend ? Color.cardCellBackground : Color.yellowAccentColor))
            }
            .buttonStyle(ButtonBounce())

        }
        .padding(.horizontal, 20)
        .frame(width: screenWidth - 30, height: 84)
        .background(Color.cellBackground.clipShape(RoundedRectangle(cornerRadius: 21)))
    }
}

