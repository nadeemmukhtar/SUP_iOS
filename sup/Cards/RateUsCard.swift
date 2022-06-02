//
//  RateUsCard.swift
//  sup
//
//  Created by Justin Spraggins on 6/25/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct RateUsCard: View {
    @ObservedObject var state: AppState
    var onClose: (() -> Void)? = nil
    @State var cardState = CGSize.zero
    let cardHeight: CGFloat = 470
    let bottomPadding: CGFloat = 60

    func rateUs() {
        let url = URL(string: "https://apps.apple.com/us/app/id1502204715?action=write-review")!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.onClose?()
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            VStack (spacing: 5) {
                Image("rate-us")
                Text("help us get to #1?")
                    .modifier(TextModifier(size: 22, font: Font.ttNormsBold))
                Image("rate-text")
                Spacer()

                Button(action: { self.rateUs() }) {
                    HStack {
                        Text("rate sup 5 stars")
                            .modifier(TextModifier(size: 22, font: Font.textaAltBlack, color: Color.white))
                            .padding(.bottom, 2)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .frame(width: 228, height: 62)
                            .foregroundColor(Color(#colorLiteral(red: 0.1803921569, green: 0.5647058824, blue: 1, alpha: 1)))
                    )
                }
                .frame(width: 228, height: 62)
                .buttonStyle(ButtonBounceLight())

                Spacer().frame(height: 5)

                Text("skip")
                    .modifier(TextModifier(size: 18, font: Font.textaAltHeavy, color: Color.secondaryTextColor))
                    .onTapGesture {
                        self.onClose?()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            .padding(.bottom, bottomPadding)
            .frame(width: screenWidth, height: cardHeight)
            .background(
                BackgroundBlurView(style: .systemUltraThinMaterialLight)
                    .frame(width: screenWidth, height: cardHeight, alignment: .center)
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
                            self.onClose?()
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

