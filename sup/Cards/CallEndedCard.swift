//
//  CallEndedCard.swift
//  sup
//
//  Created by Justin Spraggins on 4/30/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import OneSignal

struct CallEndedCard: View {
    @ObservedObject var state: AppState
    var hostname = ""
    var hostAvatar = ""
    var guestAvatars:[String] = []
    var onClose: (() -> Void)? = nil
    @State var cardState = CGSize.zero

    let cardHeight: CGFloat = 450
    let bottomPadding: CGFloat = 66

    let baseColor: Color = Color.cardBackground
    let cellColor: Color = Color.cardCellBackground
    let pColor: Color = Color.white

    func allowPush() {
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            SupUserDefaults.timesNotificationShown = SupUserDefaults.timesNotificationShown + 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                      self.onClose?()
                  }
        })
    }

    var body: some View {
        VStack {
            Spacer()
            VStack (spacing: 8) {
                Capsule().frame(width: 30, height: 8)
                    .foregroundColor(Color.white.opacity(0.6))
                    .onTapGesture { self.onClose?() }

                Spacer()
                HStack(spacing: -14) {
                    WebImage(url: URL(string: hostAvatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 58, height: 58)
                        .clipShape(Circle())
                    ForEach(self.guestAvatars, id: \.self) { value in
                            WebImage(url: URL(string: value))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 58, height: 58)
                                .clipShape(Circle())
                        }
                }

                Text("\(hostname) ended recording")
                    .modifier(TextModifier(size: 25, font: Font.ttNormsBold))
                    .lineSpacing(0)
                    .multilineTextAlignment(.center)
                .frame(width: screenWidth - 70)
                    .padding(.top, 10)

                Text("we’ll notify you when the sup is ready to replay")
                    .modifier(TextModifier(size: 19, color: Color.primaryTextColor.opacity(0.6)))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(width: screenWidth - 70, height: 40)
                    .padding(.top, 10)

                Spacer()

                ZStack {
                    if SupUserDefaults.timesNotificationShown == 0 {
                        VStack (spacing: 10) {
                            Button(action: {
                                self.allowPush()
                                guard var coins = self.state.currentUser?.coins else { return }
                                coins = coins + 100
                                self.state.add(coins: coins) { _ in }
                            }){
                                ZStack {
                                    RoundedRectangle(cornerRadius: 28)
                                        .frame(width: 286, height: 62)
                                        .foregroundColor(Color.yellowAccentColor.opacity(0.1))

                                    HStack (spacing: 15) {
                                        Image("profile-bell")
                                            .renderingMode(.original)
                                            .padding(.bottom, 2)
                                        Text("enable notifications")
                                            .modifier(TextModifier(size: 20, color: Color.yellowAccentColor))
                                            .padding(.bottom, 1)
                                    }

                                }
                            }
                            .buttonStyle(ButtonBounce())

                            HStack {
                                Text("to collect 100")
                                    .modifier(TextModifier(size: 17, color: Color.secondaryTextColor))

                                Image("sup-coin")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 18, height: 18)
                            }
                            .padding(.top, 5)
                        }
                    }
                }
            }
             .padding(.horizontal, 20)
             .padding(.top, 12)
             .padding(.bottom, bottomPadding)
             .frame(width: screenWidth, height: cardHeight)
             .background(
                BackgroundBlurView(style: .systemUltraThinMaterialDark)
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
