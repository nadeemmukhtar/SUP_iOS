//
//  SnapchatCard.swift
//  sup
//
//  Created by Justin Spraggins on 7/21/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct SnapchatCard: View {
    @State var cardState = CGSize.zero

    var body: some View {
        VStack {
            VStack (spacing: 25) {
                LoaderCircle(size: 30,
                             innerSize: 30,
                             isButton: true,
                             tint: Color.black)
                Text("creating your guest pass for Snapchat")
                    .modifier(TextModifier(size: 20,
                                       color: Color.black.opacity(0.9)))
                    .lineSpacing(0.4)
                    .multilineTextAlignment(.center)
                Image("card-snapchat")
                    .renderingMode(.original)
                    .padding(.top, 5)
            }
            .padding(.horizontal, 20)
            .frame(width: 260, height: 270)
            .background(Color.snapchatYellow.cornerRadius(34)
            .overlay(
                RoundedRectangle(cornerRadius: 34)
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 260, height: 270)
            ))
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 0)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        self.cardState = value.translation
                        if self.cardState.height < -5 {
                            self.cardState = CGSize.zero
                        }
                }
                .onEnded { value in
                    if self.cardState.height > 10 {
                        self.cardState = CGSize.zero
                    } else {
                        self.cardState = CGSize(width: 0, height: 0)
                    }
            })

        }
        .frame(width: screenWidth, height: screenHeight)
        .transition(AnyTransition.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
        .animation(.spring())
    }
}
