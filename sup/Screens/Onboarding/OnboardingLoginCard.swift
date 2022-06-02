//
//  OnboardingLoginCard.swift
//  sup
//
//  Created by Justin Spraggins on 2/23/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct OnboardingLoginCard: View {
    @ObservedObject var state: AppState
    @Binding var showLoader: Bool
    @State var cardState = CGSize.zero
    let cardHeight: CGFloat = 300
    let loginPressed: () -> Void
    let connectPressed: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack (spacing: 10) {
                ZStack {
                    Capsule().frame(width: 30, height: 8)
                        .foregroundColor(Color.white.opacity(0.1))
                    Capsule().frame(width: 30, height: 8)
                        .foregroundColor(Color.white)
                }
                .onTapGesture { self.onClose() }
                
                Spacer().frame(height: 20)

                Button(action: { self.connectPressed() }) {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color.snapchatYellow)
                            .frame(width: screenWidth - 80, height: 64, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 0)
                        HStack (spacing: 12) {
                            Image("onboarding-snapchat")
                                .renderingMode(.original)
                                .animation(nil)
                            Text("connect with Snap")
                                .modifier(TextModifier(size: 19, color: Color.black))
                        }
                        .padding(.horizontal, 25)
                        .frame(width: 260, height: 64)
                    }
                }
                .buttonStyle(ButtonBounce())
                .opacity(!showLoader ? 1 : 0)
                .animation(.easeInOut(duration: 0.3))
                .scaleEffect(!showLoader ? 1 : 0.9)
                .animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0))


                Button(action: { self.loginPressed() }) {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color.backgroundColor)
                            .frame(width: screenWidth - 80, height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                        HStack (spacing: 10) {
                            Image("onboarding-apple")
                                .renderingMode(.template)
                                .foregroundColor(.white)
                                .scaleEffect(0.8)
                                .padding(.bottom, 4)
                            Text("Sign in with Apple")
                                .modifier(TextModifier(size: 19, color: Color.white))
                        }
                        .padding(.horizontal, 25)
                        .frame(width: 260, height: 64)
                    }
                }
                .buttonStyle(ButtonBounce())
                .opacity(!showLoader ? 1 : 0)
                .animation(.easeInOut(duration: 0.3))
                .scaleEffect(!showLoader ? 1 : 0.9)
                .animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0))

                Spacer().frame(height: 5)
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            .padding(.bottom, isIPhoneX ? 70 : 60)
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
                            self.self.onClose()
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

