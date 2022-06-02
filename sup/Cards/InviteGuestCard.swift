//
//  InviteGuestCard.swift
//  sup
//
//  Created by Justin Spraggins on 6/18/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import Combine
import MessageUI

private let onPresent$ = PassthroughSubject<Void, Never>()

struct InviteGuestCard: View {
    @ObservedObject var state: AppState
    @State var cardState = CGSize.zero
    @State var showingShare = false
    var onClose: (() -> Void)? = nil
    let cardHeight: CGFloat = 270

    var inviteLink: String? {
        state.currentUser?.inviteURL
    }
    

    var body: some View {
        /// TODO: Think about throwing up an alert if inviteLink is nil in the
        /// rare case that there's a timing issue the first time a link is
        /// being created
        VStack {
            Spacer()
            VStack (spacing: 10) {
                ZStack {
                    Capsule().frame(width: 30, height: 8)
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .onTapGesture { self.onClose?() }

                Text("send guest pass")
                    .modifier(TextModifier(size: 21, font: Font.textaAltBlack))
                    .frame(height: 34)
                    .multilineTextAlignment(.center)
                    .lineSpacing(1.5)
                    .padding(.top, 2)

                Spacer()
                HStack  {
                    Spacer().frame(width: 15)
                    SettingsSocialCell(image: "socials-snapchat",
                                       text: "snapchat",
                                       textColor: Color.snapchatYellow,
                                       backgroundColor: Color.snapchatYellow.opacity(0.1),
                                       isInstagram: .constant(false),
                                       action: {
                                        impact(style: .soft)
                                        self.presentSnapchat() })
                    Spacer()
                    SettingsSocialCell(image: "socials-iMessage",
                                       text: "iMessage",
                                       textColor: Color.greenAccentColor,
                                       backgroundColor: Color.greenAccentColor.opacity(0.1),
                                       isInstagram: .constant(false),
                                       action: {
                                        impact(style: .soft)
                                        onPresent$.send()
                    })
                    Spacer()
                    SettingsSocialCell(image: "socials-more",
                                       text: "more",
                                       textColor: Color.white,
                                       backgroundColor: Color.white.opacity(0.1),
                                       isInstagram: .constant(false),
                                       action: { self.showingShare = true })
                        .sheet(isPresented: $showingShare) {
                            ShareSheet(activityItems: ["let's record a mini podcast. tap the link to accept my invite to be added to my guest list on sup 👇 \(self.inviteLink ?? "")"])
                    }
                    Spacer().frame(width: 15)
                }
                Spacer()
            }
            .padding(.top, 12)
              .padding(.bottom, isIPhoneX ? 65 : 50)
              .frame(width: screenWidth, height: cardHeight)
              .background(
                BackgroundBlurView(style: .systemUltraThinMaterialDark)
                    .frame(width: screenWidth, height: cardHeight)
                    .cornerRadius(radius: isIPhoneX ? 30 : 18, corners: [.topLeft, .topRight])
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

            MessageComposeView(
                body: "let's record a mini podcast. tap the link to accept my invite to be added to my guest list on sup 👇 \(self.inviteLink ?? "")",
                onPresent$: onPresent$
            ).frame(width: 0, height: 0)
        }
        .frame(width: screenWidth, height: screenHeight)
        .transition(.move(edge: .bottom))
        .animation(.spring())
    }
}

extension InviteGuestCard {
    private func presentSnapchat() {
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postInviteToSnapchat(url: "\(self.inviteLink ?? "")", vc: vc)
    }
}

struct InviteGuestSocial: View {
    var image: String
    var text: String
    var textColor: Color = Color.white
    var bgColor: Color = Color.white.opacity(0.8)
    @Binding var isSnapchat: Bool
    @Binding var isColor: Bool
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            HStack (spacing: 15) {
                ZStack {
                    Circle()
                        .frame(width: 50, height: 50)
                        .foregroundColor(isColor ? bgColor.opacity(0.4) : bgColor.opacity(0.1))
                    Image(image)
                        .renderingMode(isSnapchat ? .original : .template)
                        .foregroundColor(isSnapchat ? Color.clear : Color.white )
                }

                Text(text)
                    .modifier(TextModifier(size: 20, font: Font.textaAltHeavy, color: bgColor))
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(width: screenWidth - 30, height: 72)
            .background(
                RoundedRectangle(cornerRadius: 27)
                    .frame(width: screenWidth - 30, height: 72)
                    .foregroundColor(bgColor.opacity(0.1))
            )
        }
        .buttonStyle(ButtonBounceLight())
    }
}

