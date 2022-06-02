//
//  SnapchatPlaySticker.swift
//  sup
//
//  Created by Justin Spraggins on 6/20/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct SnapchatPlaySticker: View {
    let sup: Sup
    let coverSize: CGFloat = 160
    let bitmojiSize: CGFloat = 36

    var body: some View {
        ZStack {
            ZStack {
                 Color.black
                     .frame(width: coverSize * 0.8, height: coverSize * 0.8)
                     .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                     .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                     .padding(.top, 20)

                 Color.white.opacity(0.2)
                     .frame(width: coverSize + 18, height: coverSize + 18)
                     .clipShape(RoundedRectangle(cornerRadius: 32))
                     .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)

                 WebImage(url: sup.coverArtUrl)
                     .resizable()
                     .aspectRatio(contentMode: .fill)
                     .background(Color.black)
                     .frame(width: coverSize, height: coverSize)
                     .clipShape(RoundedRectangle(cornerRadius: 28))

                 VStack {
                     Spacer()
                     HStack(spacing: -5) {
                         WebImage(url: sup.avatarUrl)
                             .resizable()
                             .renderingMode(.original)
                             .aspectRatio(contentMode: .fill)
                             .frame(width: bitmojiSize, height: bitmojiSize)
                             .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)

                         ForEach(sup.guestAvatars, id: \.self) { value in
                             WebImage(url: URL(string: value))
                                 .resizable()
                                 .renderingMode(.original)
                                 .aspectRatio(contentMode: .fill)
                                 .frame(width: self.bitmojiSize, height: self.bitmojiSize)
                                 .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)
                         }
                     }
                     Spacer().frame(height: 15)
                 }
                 .frame(width: coverSize, height: coverSize)
             }
            .padding(.top, 10)
            Image("sticker-play")
        }
    }
}
