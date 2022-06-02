//
//  ProfilePlaceholder.swift
//  sup
//
//  Created by Justin Spraggins on 3/2/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct ProfilePlaceholder: View {
    @Binding var isUserProfile: Bool

    var body: some View {
        ZStack {
            PlayerView()
                .frame(width: isUserProfile ? 220 : screenWidth - 30, height: isUserProfile ? 100 : 190)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack {
                Spacer()
                Text("no sups yet")
                    .modifier(TextModifier(size: 18, font: Font.ttNormsBold, color: Color.white))
                    .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 0)
                Spacer().frame(height: 20)
            }
            .frame(width: isUserProfile ? 220 : screenWidth - 30, height: isUserProfile ? 100 : 190)
        }
    }
}

struct ProfilePlaceholderLoading: View {
    @Binding var isUserProfile: Bool

    var body: some View {
        HStack (spacing: 15) {
            RoundedRectangle(cornerRadius: 18)
                .frame(width: 100, height: 100)
                .foregroundColor(isUserProfile ? Color.white.opacity(0.1) : Color.backgroundColor.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack (alignment: .leading, spacing: 10){
                Rectangle()
                    .frame(width: 140, height: 20)
                    .foregroundColor(isUserProfile ? Color.white.opacity(0.1) : Color.backgroundColor.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Rectangle()
                    .frame(width: 80, height: 20)
                    .foregroundColor(isUserProfile ? Color.white.opacity(0.1) : Color.backgroundColor.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            Spacer()
        }
        .padding(14)
        .frame(width: isUserProfile ? screenWidth - 40 : screenWidth - 20)
        .background(isUserProfile ? Color.black.opacity(0.2) : Color.cellBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct CallPlaceholderLoading: View {
    let coverSize: CGFloat = screenWidth/2 - 20

    var body: some View {
        HStack (spacing: 10){
            VStack (spacing: 8) {
                Color.white.opacity(0.1)
                    .frame(width: coverSize, height: coverSize)
                    .clipped()

                HStack (spacing: 5) {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(Color.white.opacity(0.1))
                        .frame(width: 80, height: 20)
                    Spacer()
                }
                .padding(.top, 5)
                .frame(width: coverSize - 30)
                Spacer()
            }
            .frame(width: coverSize, height: coverSize + 54)
            .background(Color.cellBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack (spacing: 8) {
                Color.white.opacity(0.1)
                    .frame(width: coverSize, height: coverSize)
                    .clipped()

                HStack (spacing: 5) {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(Color.white.opacity(0.1))
                        .frame(width: 80, height: 20)
                    Spacer()
                }
                .padding(.top, 5)
                .frame(width: coverSize - 30)
                Spacer()
            }
            .frame(width: coverSize, height: coverSize + 54)
            .background(Color.cellBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}
