//
//  CoinsCard.swift
//  sup
//
//  Created by Justin Spraggins on 6/28/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct CoinsCard: View {
    @ObservedObject var state: AppState
    @State var claimTodayCoins = false
    @State var cardState = CGSize.zero
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    var onClose: (() -> Void)? = nil
    let cardHeight: CGFloat = screenHeight - (isIPhoneX ? 40 : 20)

    var inviteLink: String? {
        state.currentUser?.inviteURL
    }

    func coins() -> String {
        return formatCoins(value: self.state.currentUser?.coins.toString ?? "100")
    }

    func formatCoins(value: String) -> String {
        let num = Double(value)!
        let thousandNum = num/1000
        let millionNum = num/1000000
        let billionNum = num/1000000000
        if num >= 1000 && num < 1000000{
            if(floor(thousandNum) == thousandNum){
                return("\(Int(thousandNum))k")
            }
            return("\(self.roundToPlaces(value: thousandNum, places: 1))k")
        }
        if num > 1000000 && num < 1000000000{
            if(floor(millionNum) == millionNum){
                return("\(Int(thousandNum))k")
            }
            return ("\(self.roundToPlaces(value: millionNum, places: 1))M")
        }
            if num > 1000000000{
                if(floor(billionNum) == billionNum){
                    return("\(Int(thousandNum))k")
                }
                return ("\(self.roundToPlaces(value: billionNum, places: 1))B")
            }
        else{
            if(floor(num) == num){
                return ("\(Int(num))")
            }
            return ("\(num)")
        }

    }

    func roundToPlaces(value:Double, places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(value * divisor) / divisor
    }

    var body: some View {
        VStack {
            Spacer()
            VStack (spacing: 20) {
                ZStack {
                    Capsule().frame(width: 30, height: 8)
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .onTapGesture {
                    self.contentOffset = CGPoint(x: 0, y: 0)
                    self.onClose?()
                }

                ScrollableView(self.$contentOffset, animationDuration: 0.5, action: { _ in }) {
                    VStack(spacing: 20) {
                        Text("you have \(self.coins()) coins")
                            .modifier(TextModifier(size: 18, font: Font.textaAltBlack, color: Color.white.opacity(0.6)))
                        Group {
                            MarketPlaceCell(shareGuestPass: {
                                SupAnalytics.coinsMarketGuestPass()
                                self.presentSnapchat()
                            })

                            LoginCoinCell(state: self.state, claimTodayCoins: self.$claimTodayCoins,
                                          tapClaim: {
                                            guard var coins = self.state.currentUser?.coins else { return }
                                            coins = coins + 50
                                            self.state.add(coins: coins) { _ in
                                                self.claimTodayCoins = true
                                                SupUserDefaults.lastAccessDate = Date()
                                            }
                            })
                            Spacer().frame(height: 25)
                            GuestPassCoinCell(state: self.state, onAction: {
                                SupAnalytics.coinsFiveGuestPass()
                                self.presentSnapchat()
                            })
                        }

                        Text("more ways to get coins")
                            .modifier(TextModifier(size: 21, font: Font.textaAltBlack))
                            .frame(height: 34)
                            .multilineTextAlignment(.center)
                            .padding(.top, 35)
                        VStack (spacing: 18){
                            EarnCoinCell(state: self.state, title: "record a new sup", amount: "25 coins", showButton: .constant(false))
                            EarnCoinCell(state: self.state, title: "friend accepts your guest pass",
                                         amount: "30 coins",
                                         showButton: .constant(true),
                                         onAction: {
                                            SupAnalytics.coinsShareGuestPass()
                                            self.presentSnapchat()
                            })
                            EarnCoinCell(state: self.state, title: "share a sup to TikTok", amount: "10 coins", showButton: .constant(false))
                            EarnCoinCell(state: self.state, title: "share a sup to Instagram stories", amount: "5 coins", showButton: .constant(false))
                        }


                        Spacer().frame(height: 10)

                        TextButton(
                                      title: "close",
                                      color: Color.white.opacity(0.1),
                                      textColor: Color.white,
                                      width: 104,
                                      height: 46,
                                      action: {
                                        impact(style: .soft)
                                        self.onClose?()
                                        self.contentOffset = CGPoint(x: 0, y: 0)
                        })

                        Spacer().frame(height: isIPhoneX ? 30 : 20)
                    }
                }
            }
            .padding(.top, 20)
            .frame(width: screenWidth, height: cardHeight)
            .background(
                BackgroundBlurView(style: .prominent)
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
        }
        .frame(width: screenWidth, height: screenHeight)
        .transition(.move(edge: .bottom))
        .animation(.spring())
        .onAppear {
            if let lastAccessDate = SupUserDefaults.lastAccessDate {
                if Calendar.current.isDateInToday(lastAccessDate) {
                    self.claimTodayCoins = true
                }
            }
        }
    }
}

struct MarketPlaceCell: View {
    @State var showAlert = false
    var shareGuestPass: (() -> Void)? = nil

    var body: some View {
        VStack {
            Button(action: {
                impact(style: .soft)
                self.showAlert = true
            }) {
                HStack (spacing: 0) {
                    Image("marketplace-icon")
                        .renderingMode(.original)
                        .padding(.top, 8)

                    Text("sup market")
                        .modifier(TextModifier(size: 20, color: Color.redColor))
                        .padding(.bottom, 1)
                        .padding(.leading, -10)
                    Spacer()
                    Image("call-arrow")
                        .renderingMode(.template)
                        .foregroundColor(Color.redColor.opacity(0.4))

                }
                .padding(.leading, 12)
                .padding(.trailing, 30)
                .frame(width: screenWidth - 30, height: 78)
                .background(
                    Color.redColor.opacity(0.15)
                        .frame(width: screenWidth - 30, height: 78)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                )
            }
            .buttonStyle(ButtonBounceLight())
            .alert(isPresented: self.$showAlert) {
                Alert(title: Text("Market closed"),
                      message: Text("You need more coins to open the sup market. Post your guest pass to your Snapchat stories to get more sup coins."),
                      primaryButton: .default(Text("OK")) {
                              self.shareGuestPass?()
                      }, secondaryButton: .cancel(Text("Later")))
            }

            HStack {
                Text("get more coins to open sup market")
                    .modifier(TextModifier(size: 16, font: Font.textaBold, color: Color.primaryTextColor.opacity(0.6)))
                    .padding(.leading, 10)

                Spacer()
            }
            .frame(width: screenWidth - 30)

        }
    }
}

struct LoginCoinCell: View {
    @ObservedObject var state: AppState
    @Binding var claimTodayCoins: Bool
    var tapClaim: (() -> Void)? = nil

    var body: some View {
        VStack (spacing: 5) {
            HStack (spacing: 20) {
                VStack (alignment: .leading, spacing: 4) {

                    Text("daily giveaway")
                        .modifier(TextModifier(size: 24, font: Font.ttNormsBold, color: Color.primaryTextColor))
                    Text("login to sup every day and get 50 coins")
                        .modifier(TextModifier(size: 17, color: Color.primaryTextColor.opacity(0.6)))
                    .frame(height: 34)
                }
                Spacer()

                WebImage(url: URL(string: "\(self.state.bitmojiSelfie!)/goals_level"))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)

            }

            Spacer()

            Button(action: {
                impact(style: .soft)
                self.tapClaim?()
            }) {
                HStack (spacing: 16) {
                    Image("sup-coin")
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 26, height: 26)

                    Text(claimTodayCoins ? "claimed today!" : "claim 50 coins")
                        .modifier(TextModifier(size: 20, color: claimTodayCoins ? Color.secondaryTextColor : Color(#colorLiteral(red: 0.9921568627, green: 0.8078431373, blue: 0.2039215686, alpha: 1))))
                    .animation(nil)
                }
                .frame(width: screenWidth - 70, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .foregroundColor(claimTodayCoins ? Color.white.opacity(0.1) : Color(#colorLiteral(red: 0.9921568627, green: 0.8078431373, blue: 0.2039215686, alpha: 1)).opacity(0.1))
                        .frame(height: 56)
                        .cornerRadius(25))
            }
            .buttonStyle(ButtonBounceLight())
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 25)
        .frame(width: screenWidth - 30, height: 194)
        .background(
            Color.white.opacity(0.1)
                .frame(width: screenWidth - 30, height: 194)
                .clipShape(RoundedRectangle(cornerRadius: 23))
        )
    }
}

struct GuestPassCoinCell: View {
    @ObservedObject var state: AppState
    var onAction: (() -> Void)? = nil

    var body: some View {
        VStack (spacing: 5) {
            HStack (spacing: 8) {
                Text("1500 coins")
                    .modifier(TextModifier(size: 15, color: Color.white))

                Image("sup-coin")
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 24, height: 24)
            }
            .frame(width: 128, height: 38)
             .background(BackgroundBlurView(style: .systemUltraThinMaterialLight).frame(width: 128, height: 38).cornerRadius(14))
             .padding(.top, -32)

            HStack (spacing: 13) {
                CoinGuestPass(state: self.state)

                VStack (spacing: 5) {
                    HStack {
                        Text("\(self.state.guest?.users.count ?? 0) of 5")
                            .modifier(TextModifier(size: 28, font: Font.ttNormsBold, color: Color.primaryTextColor))
                        Spacer()
                    }
                    HStack {
                        Text("get 5 friends to accept your guest pass")
                            .modifier(TextModifier(size: 17, color: Color.primaryTextColor.opacity(0.6)))
                            .frame(height: 34)
                        Spacer()
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(width: screenWidth - 20)
            .padding(.top, 5)

            InviteGuestSocial(image: "share-snapchat",
                              text: "snap guest pass",
                              textColor: Color.backgroundColor,
                              bgColor: Color.snapchatYellow,
                              isSnapchat: .constant(true),
                              isColor: .constant(false),
                              action: {
                                impact(style: .soft)
                                self.onAction?()

            }).scaleEffect(0.9)
        }
        .background(
            Color.white.opacity(0.1)
                .frame(width: screenWidth - 30, height: 258)
                .clipShape(RoundedRectangle(cornerRadius: 23))
        )
    }
}

struct EarnCoinCell: View {
    @ObservedObject var state: AppState
    let title: String
    let amount: String
    @Binding var showButton: Bool
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Image("sup-coin")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
            Spacer().frame(width: 15)

            VStack (alignment: .leading, spacing: 0) {
                Text(title)
                    .modifier(TextModifier(size: 19, font: Font.textaBold, color: Color.primaryTextColor))
                    .lineSpacing(0)

                Text(amount)
                    .modifier(TextModifier(size: 17, font: Font.textaAltBlack, color: Color.primaryTextColor.opacity(0.6)))
            }

            Spacer()
            if self.showButton {
                Button(action: {
                    impact(style: .medium)
                    self.onAction?()
                }) {
                    VStack (spacing: -3) {
                        if self.state.bitmojiSelfie != nil {
                            WebImage(url: URL(string: "\(self.state.bitmojiSelfie!)/profile_sayhi"))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                        }
                        Text("share")
                        .modifier(TextModifier(size: 18, color: Color.backgroundColor))
                        .padding(.bottom, 1)
                        .background(Color.yellowAccentColor.frame(width: 78, height: 36).cornerRadius(17))
                       }
                }
                .frame(width: 78, height: 36)
            .buttonStyle(ButtonBounce())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 2)
        .frame(width: screenWidth)
    }
}

struct CoinGuestPass: View {
    @ObservedObject var state: AppState

    var body: some View {
        ZStack {
            Image("coins-guestPass")
            VStack (spacing: 0) {
                ProfileAvatar(state: state,
                              currentUser: .constant(true),
                              tapAction: { },
                              size: 40)

                Spacer().frame(height: 15)

                Text("\(self.state.currentUser?.username ?? "my")")
                    .modifier(TextModifier(size: 10, font: Font.textaAltBlack, color: Color.backgroundColor))
                    .frame(width: 110)
                    .truncationMode(.tail)
                    .lineLimit(0)
            }.padding(.top, 40)
        }
        .scaleEffect(0.9)
    }
}


extension CoinsCard {
    private func presentSnapchat() {
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postInviteToSnapchat(url: "\(self.inviteLink ?? "")", vc: vc)
    }
}
