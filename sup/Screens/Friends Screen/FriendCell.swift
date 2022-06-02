//
//  FriendCell.swift
//  sup
//
//  Created by Justin Spraggins on 5/5/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct FriendCell: View {
    @ObservedObject var state: AppState
    let hasPlayed: Bool
    let url: URL
    let image: URL
    let cover: URL
    let username: String
    let description: String
    let sup: Sup
    let isSelected: Bool
    var tapAvatar: ((Sup) -> Void)? = nil
    let coverWidth: CGFloat = screenWidth/2 - 20
    let coverHeight: CGFloat = screenWidth/2 + 10

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.tapAvatar?(self.sup)
        }) {
            VStack (spacing: 0) {
                ZStack (alignment: .topLeading) {

                    WebImage(url: cover)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: coverWidth, height: coverHeight - 66)
                        .animation(nil)
                        .cornerRadius(radius: 24, corners: [.topLeft, .topRight])
                        .cornerRadius(radius: 5, corners: [.bottomLeft, .bottomRight])
                        .contentShape(Rectangle())

                    if !hasPlayed {
                        ZStack {
                            Color.redColor
                                .frame(width: 51, height: 26)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 0)
                            Text("new")
                                .modifier(TextModifier(size: 17, color: Color.white))
                        }
                        .padding(.leading, 15)
                        .padding(.top, 20)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3))
                    }
                }
                HStack (spacing: 5) {
                    HStack(spacing: -14) {
                        WebImage(url: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        ForEach(self.sup.guestAvatars, id: \.self) { value in
                            WebImage(url: URL(string: value))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        }
                    }
                    Button(action: {}) {
                        VStack (spacing: 0) {
                            HStack {
                                Text(username)
                                    .modifier(TextModifier(size: 17, color: Color.white))
                                    .lineLimit(0)
                                    .truncationMode(.tail)
                                    .multilineTextAlignment(.leading)
                                    .animation(nil)
                                if sup.username == "sup" {
                                    Image("verified-badge")
                                        .renderingMode(.original)
                                }
                                Spacer()
                            }

                            HStack {
                                Text(description)
                                    .modifier(TextModifier(size: 17, color: Color.secondaryTextColor))
                                    .lineLimit(0)
                                    .truncationMode(.tail)
                                    .multilineTextAlignment(.leading)
                                    .animation(nil)
                                Spacer()
                            }
                        }
                    }
                    .disabled(true)
                    .buttonStyle(ButtonBounceNone())

                    Spacer()
                }
                .frame(width: coverWidth - 20, height: 66)
                .padding(.bottom, 2)

            }
            .frame(width: coverWidth, height: coverHeight)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .foregroundColor(Color.cellBackground)
            )
        }
        .buttonStyle(ButtonBounceLight())
    }
}

