//
//  HappyHourCard.swift
//  sup
//
//  Created by Justin Spraggins on 7/21/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct HappyHourCard: View {
    @ObservedObject var state: AppState
    var onClose: (() -> Void)? = nil
    @State var cardState = CGSize.zero
    @State var isSelected = false

    private func toggleHappyHour() {
        impact(style: .soft)
        let happyHour = !isSelected
        User.update(userID: self.state.currentUser?.uid, data: [
            "happyHour": happyHour
        ])
        self.isSelected = happyHour
    }

    private func timeZoneDiff() -> Int {
        let current = TimeZone.current
        guard let pacific = TimeZone(identifier: "America/Los_Angeles") else {
            return 0
        }

        let seconds = current.secondsFromGMT() - pacific.secondsFromGMT()

        return seconds / 60 / 60
    }

    var body: some View {
        VStack {
            VStack (spacing: 5) {
                ZStack {
                    PlayerHappyHourView()
                        .frame(width: 266, height: 224)
                        .cornerRadius(34)
                        .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 0)
                    VStack {
                        Spacer().frame(height: 95)
                        VStack (spacing: 5) {
                            HappyHourDate(text: "Wednesday", time: "\(5 + timeZoneDiff()) PM")
                            HappyHourDate(text: "Sunday", time: "\(2 + timeZoneDiff()) PM")
                        }
                    }
                    .frame(width: 266, height: 224)
                }

                Spacer()
                HStack {
                      Text("When you pick up the happy hour call, you'll get matched to either be the host or a guest.")
                          .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.white.opacity(0.7)))
                    .frame(height: 70)
                          .lineSpacing(0)
                      Spacer()

                      Button(action: { self.toggleHappyHour() }) {
                          ZStack {
                              Rectangle()
                                  .frame(width: 64, height: 40)
                                .foregroundColor(self.isSelected ? Color(#colorLiteral(red: 0.7019607843, green: 0.2901960784, blue: 0.9647058824, alpha: 1)) : Color.black.opacity(0.2))
                                  .animation(.easeInOut(duration: 0.3))
                                  .cornerRadius(20)
                              Circle()
                                  .frame(width: 26, height: 26)
                                  .foregroundColor(self.isSelected ? Color(#colorLiteral(red: 1, green: 0.7450980392, blue: 0.5647058824, alpha: 1)) : Color.white.opacity(0.6))
                                  .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                  .offset(x: self.isSelected ? 12 : -12)
                                  .animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0))
                          }
                      }
                      .buttonStyle(ButtonBounce())
                  }
                    .frame(width: 262, height: 50)
            }
            .padding(.top, 28)
            .padding(.bottom, 40)
            .frame(width: 310, height: 374)
            .background(
                LinearGradient(gradient: Gradient(colors: [ Color(#colorLiteral(red: 0.7019607843, green: 0.2901960784, blue: 0.9647058824, alpha: 1)), Color(#colorLiteral(red: 0.1411764706, green: 0.2901960784, blue: 0.8823529412, alpha: 1))]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing
                ).cornerRadius(34)
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 0)
            )
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
        .frame(width: screenWidth, height: screenHeight)
        .transition(AnyTransition.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
        .animation(.spring())
        .onAppear {
            self.isSelected = self.state.currentUser?.happyHour ?? false
        }
    }
}

struct HappyHourDate: View {
    let text: String
    let time: String

    var body: some View {
        HStack {
            Spacer().frame(width: 2)
            Text(text)
                .modifier(TextModifier(size: 20, font: Font.textaAltBlack))
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .foregroundColor(Color.white.opacity(0.2))
                    .frame(width: 74, height: 38)

                Text(time)
                    .modifier(TextModifier(size: 20, font: Font.textaAltBlack))
            }
        }
        .padding(.horizontal, 20)
        .frame(width: 262)
    }
}
