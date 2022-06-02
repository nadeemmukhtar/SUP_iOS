//
//  OnboardingTextCard.swift
//  sup
//
//  Created by Justin Spraggins on 2/23/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct OnboardingTextCard: View {
    @ObservedObject var state: AppState
    @Binding var usernameInput : Bool
    @Binding var usernameLoader: Bool
    @State private var text: String = ""
    @Binding var keyboardOpen: Bool
    @Binding var isTyping: Bool
    let usernamePressed: (String) -> Void

    var username: Bool {
        self.state.onboardingStage == .ClaimUsername
    }
    
    var body: some View {
        VStack (spacing: 10) {
            Spacer()
            ZStack {
                if usernameLoader {
                    VStack (spacing: 20) {
                        LoaderCircle(size: 30, innerSize: 24, isButton: true, tint: Color.backgroundColor)
                        Text("creating account...")
                            .modifier(TextModifier(size: 19, font: Font.textaAltHeavy, color: Color.backgroundColor))
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3))
                }

                VStack (spacing: 10) {
                    HStack {
                        Text("@")
                            .modifier(TextModifier(size: 32, font: Font.ttNormsBold, color: Color.yellowAccentColor.opacity(0.6)))
                            .padding(.bottom, 5)
                        ZStack {
                            if text.isEmpty {
                                HStack {
                                    Text("username")
                                        .modifier(TextModifier(size: 20, color: Color.yellowAccentColor))
                                    Spacer()
                                }
                            }

                            OnboardingTextView(isFirstResponder: keyboardOpen, text: $text, didEditing: $isTyping)
                                .modifier(TextModifier(size: 20, color: Color.yellowAccentColor))
                                .padding(.top, 17)
                                .accentColor(Color.yellowAccentColor)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(width: screenWidth - 75, height: 64)
                    .background(Color.yellowDarkColor.opacity(0.5).cornerRadius(22))
                    .shadow(color: Color.shadowColor.opacity(0.4), radius: 20, x: 0, y: 5)
                    .padding(.top, 20)
                    .opacity(usernameInput ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3))
                    .scaleEffect(usernameInput ? 1 : 0.95)
                    .animation(.spring())

                    Button(action: {
                        impact(style: .soft)
                        let textFromInput = self.text
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.usernamePressed(textFromInput)
                        }
                        self.text = ""
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .foregroundColor(self.text.isEmpty ? Color.backgroundColor.opacity(0.2) : Color.yellowAccentColor)
                                .frame(width: screenWidth - 75, height: 56)
                            HStack (spacing: 20) {
                                Text("next")
                                    .modifier(TextModifier(size: 23,
                                                           color: self.text.isEmpty ? Color.lightBackground : Color.backgroundColor))
                                Image("post-arrow")
                                    .renderingMode(.template)
                                    .foregroundColor(self.text.isEmpty ? Color.lightBackground : Color.backgroundColor)
                            }
                        }
                    }
                    .frame(width: screenWidth - 75, height: 56)
                    .buttonStyle(ButtonBounceLight())
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 0)
                    .opacity(usernameInput ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3))
                    .scaleEffect(usernameInput ? 1 : 0.95)
                    .animation(.spring())
                }
            }
            Spacer().frame(height: isIPhoneX ? 300 : 235)
        }
        .frame(width: screenWidth, height: screenHeight)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3))
    }
}
