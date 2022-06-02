//
//  HorizontalVideoBackground.swift
//  sup
//
//  Created by Justin Spraggins on 6/15/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct HorizontalVideoBackground: View {
    let sup: Sup
    let coverSize: CGFloat = screenWidth - 130
    let bitmojiSize: CGFloat = 44
    let width: CGFloat = 1920
    let height: CGFloat = 1080

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Image("socialVideo-circle")
                }
                Spacer()
                HStack {
                    Image("socialVideo-circleBig")
                        .opacity(0.6)
                    Spacer()
                }
                .padding(.leading, -200)

                Spacer().frame(height: 100)
            }
            VStack {
                Image("socialVideo-headphone")
                Spacer().frame(height: coverSize + 85)

                HStack (spacing: 5) {
                    Text("new episode")
                        .modifier(TextModifier(size: 20, color: Color.white))
                    Text("@onsupfyi")
                        .modifier(TextModifier(size: 18, font: Font.ttNormsBold, color: Color.white))
                        .padding(.bottom, 2)
                }

                Spacer().frame(height: 60)
                Image("socialVideo-mouth")
            }
        }
        .frame(width: width, height: height)
        .background(
            Color.black
                .frame(width: width, height: height)
                .overlay(Color(sup.color.color()).opacity(0.8))
        )
    }
}

struct HorizontalVideoCentered: View {
    let sup: Sup
    let coverSize: CGFloat = screenWidth - 130
    let bitmojiSize: CGFloat = 44

    var body: some View {
        ZStack {
            Color.black
                .frame(width: coverSize * 0.8, height: coverSize * 0.8)
                .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
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
    }
}
