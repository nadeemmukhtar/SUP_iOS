//
//  SquareVideoBackground.swift
//  sup
//
//  Created by Justin Spraggins on 6/8/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct SquareVideoBackground: View {
    let sup: Sup
    let coverSize: CGFloat = screenWidth - 130
    let bitmojiSize: CGFloat = 44

    var body: some View {
        ZStack {
            VStack {
                Image("socialVideo-circle")

                Spacer()
                HStack {
                    Image("socialVideo-circleBig")
                        .opacity(0.6)
                    Spacer()
                }
                .padding(.leading, -200)
                Spacer().frame(height: 10)
            }
            .frame(width: screenWidth, height: screenWidth)

            VStack {
                Spacer().frame(width: coverSize, height: coverSize)
                Image("socialVideo-mouth")
                    .padding(.top, 50)
            }
            .frame(width: screenWidth, height: screenWidth)
        }
        .frame(width: screenWidth, height: screenWidth)
        .background(
            Color.black
                .frame(width: screenWidth, height: screenHeight)
                .overlay(Color(sup.color.color()).opacity(0.8))
        )
    }
}

struct SquareVideoCentered: View {
    let sup: Sup
    let coverSize: CGFloat = screenWidth - 130
    let bitmojiSize: CGFloat = 44

    var body: some View {
        VStack {
            ZStack {
                Color.black
                    .frame(width: coverSize * 0.8, height: coverSize * 0.8)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(.top, 20)

                Color.white.opacity(0.2)
                    .frame(width: coverSize + 20, height: coverSize + 20)
                    .clipShape(RoundedRectangle(cornerRadius: 42))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)

                WebImage(url: sup.coverArtUrl)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .background(Color.black)
                    .frame(width: coverSize, height: coverSize)
                    .clipShape(RoundedRectangle(cornerRadius: 38))

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
                    Spacer().frame(height: 20)
                }
                .frame(width: coverSize, height: coverSize)
            }
            Spacer().frame(width: screenWidth, height: 50)
        }
        .frame(width: screenWidth, height: screenWidth)
    }
}
