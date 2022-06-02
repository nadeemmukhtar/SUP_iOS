//
//  QuestionCategoryCard.swift
//  sup
//
//  Created by Justin Spraggins on 7/29/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct QuestionCategoryCard: View {
    @State var cardState = CGSize.zero
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    var onClose: (() -> Void)? = nil
    var onSelect: (() -> Void)? = nil
    let cardHeight: CGFloat = 230

    var body: some View {
        VStack {
            Spacer()
            VStack (spacing: 8) {
                Capsule().frame(width: 30, height: 8)
                    .foregroundColor(Color.white.opacity(0.6))
                     .onTapGesture { self.onClose?() }

                Text("questions")
                    .modifier(TextModifier(size: 21, font: Font.textaAltBlack))
                    .frame(height: 44)
                    .multilineTextAlignment(.center)
                    .lineSpacing(1.5)
                    .padding(.top, 2)

                Spacer().frame(height: 1)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack (spacing: 10) {
                        ForEach(0..<3) { value in
                            QuestionCategoryTitle(title: "category",
                                                  tapAction: { self.onSelect?() })
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(width: screenWidth, height: 58)

                Spacer()
            }
             .padding(.horizontal, 20)
             .padding(.top, 12)
             .padding(.bottom, isIPhoneX ? 70 : 60)
             .frame(width: screenWidth, height: cardHeight)
             .background(
                BackgroundBlurView(style: .systemUltraThinMaterialDark)
                    .frame(width: screenWidth, height: cardHeight, alignment: .center)
                    .overlay(Color.white.opacity(0.1))
                    .cornerRadius(radius: isIPhoneX ? 30 : 18, corners: [.topLeft, .topRight]))
                 .offset(y: self.cardState.height)
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
                             self.self.onClose?()
                             self.cardState = CGSize.zero
                         } else {
                             self.cardState = CGSize(width: 0, height: 0)
                         }
                 })
        }
        .transition(.move(edge: .bottom))
        .animation(.spring())
    }
}

struct QuestionCategoryTitle: View {
    let title: String
    var tapAction: (() -> Void)? = nil

    var body: some View {
        Button(action: { self.tapAction?() }) {
            HStack {
                Text(title)
                    .modifier(TextModifier(size: 18))
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .frame(height: 56)
                    .foregroundColor(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(ButtonBounceLight())
    }
}
