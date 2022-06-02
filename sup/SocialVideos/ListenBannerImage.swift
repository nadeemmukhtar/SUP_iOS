//
//  ListenBannerImage.swift
//  sup
//
//  Created by Justin Spraggins on 6/24/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct ListenBannerImage: View {
    let sup: Sup
    let coverImage: UIImage?
    let coverSize: CGFloat = 290
    let bitmojiSize: CGFloat = 48

    var body: some View {
        ZStack {
            Image("listnBanner-circles")
            VStack (spacing: 40) {
                ZStack {
                    Color.black
                        .frame(width: coverSize * 0.8, height: coverSize * 0.8)
                        .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                        .padding(.top, 20)

                    Color.white.opacity(0.2)
                        .frame(width: coverSize + 20, height: coverSize + 20)
                        .clipShape(RoundedRectangle(cornerRadius: 44))
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)

                    if coverImage != nil {
                        Image(uiImage: coverImage!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: coverSize, height: coverSize)
                        .clipShape(RoundedRectangle(cornerRadius: 42))
                    } else {
                        WebImage(url: sup.coverArtUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: coverSize, height: coverSize)
                        .clipShape(RoundedRectangle(cornerRadius: 42))
                    }

                    VStack {
                        Spacer()
                        HStack(spacing: -5) {
                            WebImage(url: sup.avatarUrl)
                                .resizable()
                                .renderingMode(.original)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: bitmojiSize, height: bitmojiSize)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 0)

                            ForEach(sup.guestAvatars, id: \.self) { value in
                                WebImage(url: URL(string: value))
                                    .resizable()
                                    .renderingMode(.original)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: self.bitmojiSize, height: self.bitmojiSize)
                                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 0)
                            }
                        }
                        Spacer().frame(height: 35)
                    }
                    .frame(width: coverSize, height: coverSize)
                }
                Image("listenBanner-mouth")
                    .padding(.top, 10)
            }
        }
        .frame(width: 1200, height: 630)
        .background(
            Color.black
                .frame(width: 1200, height: 630)
                .overlay(Color(sup.color.color()).opacity(0.8)))
    }
}
