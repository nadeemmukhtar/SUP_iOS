//
//  WelcomeCard.swift
//  sup
//
//  Created by Justin Spraggins on 5/5/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import AVFoundation

struct WelcomeCard: View {
    @ObservedObject var state: AppState
    var onOkay: () -> Void
    @State var firstCheck = false
    @State var secondCheck = false
    @State var thirdCheck = false

    var showButton: Bool {
        self.firstCheck && self.secondCheck && self.thirdCheck
    }

    var body: some View {
        VStack (spacing: 10) {
            Spacer()
            Image("socials-headphones")
                .padding(.bottom, isIPhoneX ? 15 : 10)
            Text("record sups with\nfriends")
                .modifier(TextModifier(size: 22, font: Font.ttNormsBold))
                .multilineTextAlignment(.center)
                .lineSpacing(0)

            Spacer().frame(height: 10)

            HStack (spacing: 15) {
                Text("sups are 12min")
                    .modifier(TextModifier())
                Spacer()

                Button(action: {
                    impact(style: .soft)
                    self.firstCheck = true
                }) {
                    ZStack {
                        Circle()
                            .frame(width: 48, height: 48)
                            .foregroundColor(firstCheck ? Color.yellowAccentColor : Color.clear)
                            .overlay(Circle().stroke(firstCheck ? Color.yellowAccentColor : Color.yellowBaseColor, lineWidth: 2))
                        Image("profile-check")
                            .renderingMode(.template)
                            .foregroundColor(firstCheck ? Color.backgroundColor : Color.yellowAccentColor)
                    }
                }
                .buttonStyle(ButtonBounce())
            }
            .padding(.horizontal, 25)
            .frame(width: screenWidth - 30, height: 80)
            .background(Color.cellBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            HStack (spacing: 15) {
                VStack (alignment: .leading, spacing: 0) {
                    Text("the audio saves")
                        .modifier(TextModifier())
                    Text("enable microphone")
                        .modifier(TextModifier(font: Font.textaAltBold, color: Color.secondaryTextColor))
                }
                Spacer()

                Button(action: {
                    impact(style: .soft)
                    self.state.micPermissions { allowed in
                        if allowed {
                            self.secondCheck = true
                        } else {
                            self.state.promptForPermissions()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .frame(width: 48, height: 48)
                            .foregroundColor(secondCheck ? Color.yellowAccentColor : Color.clear)
                            .overlay(Circle().stroke(secondCheck ? Color.yellowAccentColor : Color.yellowBaseColor, lineWidth: 2))
                        Image("check-icon")
                            .renderingMode(.template)
                            .foregroundColor(secondCheck ? Color.backgroundColor : Color.yellowAccentColor)
                    }
                }
                .buttonStyle(ButtonBounce())
            }
            .padding(.horizontal, 25)
            .frame(width: screenWidth - 30, height: 80)
            .background(Color.cellBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            HStack (spacing: 15) {
                VStack (alignment: .leading, spacing: 0) {
                    Text("add cover photo")
                        .modifier(TextModifier())
                    Text("allow photo access")
                        .modifier(TextModifier(font: Font.textaAltBold, color: Color.secondaryTextColor))
                }
                Spacer()

                Button(action: {
                    impact(style: .soft)
                    self.state.photosPermissions { allowed in
                        if allowed {
                            self.thirdCheck = true
                        } else {
                            self.state.promptForPhotoPermissions()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .frame(width: 48, height: 48)
                            .foregroundColor(thirdCheck ? Color.yellowAccentColor : Color.clear)
                            .overlay(Circle().stroke(thirdCheck ? Color.yellowAccentColor : Color.yellowBaseColor, lineWidth: 2))
                        Image("check-icon")
                            .renderingMode(.template)
                            .foregroundColor(thirdCheck ? Color.backgroundColor : Color.yellowAccentColor)
                    }
                }
                .buttonStyle(ButtonBounce())
            }
            .padding(.horizontal, 25)
            .frame(width: screenWidth - 30, height: 80)
            .background(Color.cellBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            Spacer()
            ZStack {
                Text("tap the checks to continue")
                    .modifier(TextModifier(size: 19, color: Color.secondaryTextColor.opacity(0.8)))
                    .opacity(showButton ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3))

                YellowTextButton(
                    title: "i'm ready!",
                    action: { self.onOkay()})
                    .padding(.bottom, 20)
                    .opacity(showButton ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3))
                    .scaleEffect(showButton ? 1 : 0.6)
                    .animation(.spring())
            }
            .padding(.bottom, isIPhoneX ? 70 : 50)
        }
        .frame(width: screenWidth, height: screenHeight)
    }
}
