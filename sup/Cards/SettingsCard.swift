//
//  SettingsCard.swift
//  sup
//
//  Created by Justin Spraggins on 2/6/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import MessageUI
import Combine

private let onPresent$ = PassthroughSubject<Void, Never>()

struct SettingsCard: View {
    @ObservedObject var state: AppState
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    @State var cardState = CGSize.zero
    @State var bitmojiAlert = false
    @State var logoutActionSheet = false
    @State var twitterSelected = false
    @State var legalActionSheet = false
    var changeAvatar: (() -> Void)? = nil
    var refreshBitmoji: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil
    var onComplete: () -> Void
    var showInroCard: (() -> Void)? = nil
    @State var isFeaturedAllowed = true
    let cardHeight: CGFloat = screenHeight - (isIPhoneX ? 120 : 20)

    let baseColor: Color = Color.cardBackground
    let cellColor: Color = Color.cardCellBackground
    let pColor: Color = Color.white
    let sColor: Color = Color.secondary

    func rateUs() {
        let url = URL(string: "https://apps.apple.com/us/app/id1502204715?action=write-review")!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func openTerms() {
        let url = URL(string: "http://www.onsup.fyi/terms/")!
        UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
    }
    
    func openPrivacy() {
        let url = URL(string: "http://www.onsup.fyi/privacy/")!
        UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
    }
    
    func openSnapchat() {
        let snapchatURLString = "snapchat://add/onsup"
        
        let url = URL(string: snapchatURLString)!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func openInstagram() {
        let instURL: NSURL = NSURL(string: "instagram://user?username=onsupfyi")!
        let instWB: NSURL = NSURL(string: "https://instagram.com/onsupfyi/")!

        if UIApplication.shared.canOpenURL(instURL as URL) {
            UIApplication.shared.open(instURL as URL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(instWB as URL, options: [:], completionHandler: nil)
        }
    }

    func openTwitter() {
        let screenName =  "onsupfyi"
        let appURL = NSURL(string: "twitter://user?screen_name=\(screenName)")!
        let webURL = NSURL(string: "https://twitter.com/\(screenName)")!

        let application = UIApplication.shared

        if application.canOpenURL(appURL as URL) {
             application.open(appURL as URL)
        } else {
             application.open(webURL as URL)
        }
    }

    func openYouTube() {
        let YoutubeUser =  "Your Username"
        let appURL = NSURL(string: "youtube://www.youtube.com/user/\(YoutubeUser)")!
        let webURL = NSURL(string: "https://www.youtube.com/user/\(YoutubeUser)")!
        let application = UIApplication.shared

        if application.canOpenURL(appURL as URL) {
            application.open(appURL as URL)
        } else {
            // if Youtube app is not installed, open URL inside Safari
            application.open(webURL as URL)
        }
    }

    func openTikTok() {
        let url = URL(string: "https://www.tiktok.com/@onsupfyi")!
        UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
    }

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                VStack (spacing: 10) {
                    Capsule().frame(width: 30, height: 8)
                        .foregroundColor(sColor.opacity(0.6))
                        .onTapGesture { self.onClose?() }

                    Spacer().frame(height: 20)
                    Group {
                        HStack (spacing: 20) {
                            Button(action: {
                                impact(style: .soft)
                                self.refreshBitmoji?()
                                self.bitmojiAlert = true
                            }) {
                                HStack {
                                    ProfileAvatar(state: self.state,
                                                  currentUser: .constant(true),
                                                  tapAction: { self.refreshBitmoji?() })
                                        .padding(.bottom, 1)
                                }
                                .frame(width: 72, height: 72)
                                .background(Color.white.opacity(0.1).clipShape(Circle()))
                            }
                            .buttonStyle(ButtonBounceLight())
                            .alert(isPresented: self.$bitmojiAlert) {
                                Alert(
                                    title: Text("Bitmoji Updated"),
                                    message: Text("Your bitmoji is up to date from Snapchat."),
                                    dismissButton: .default(Text("👍👌"))
                                )
                            }

                            Text("refresh bitmoji")
                                .modifier(TextModifier(size: 20, color: pColor))
                                .padding(.bottom, 2)
                            Spacer()
                        }
                        .frame(width: screenWidth - 40)
                    }

                    HStack (spacing: 15) {
                        Text("allow my sups to be featured by the editorial team")
                            .modifier(TextModifier(size: 18, font: Font.textaBold, color: pColor))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(0)
                            .frame(height: 40)

                        Spacer()
                        Button(action: {
                            impact(style: .soft)
                            self.isFeaturedAllowed.toggle()
                            guard let userID = self.state.currentUser?.uid else { return }
                            SupUserDefaults.saveFeature(userID: userID, allowed: self.isFeaturedAllowed)
                        }) {
                            ZStack {
                                Rectangle()
                                    .frame(width: 64, height: 40)
                                    .foregroundColor(Color.white.opacity(0.4))
                                    .animation(.easeInOut(duration: 0.3))
                                    .cornerRadius(20)
                                Circle()
                                    .frame(width: 26, height: 26)
                                    .foregroundColor(self.isFeaturedAllowed ? Color.yellowAccentColor : Color.greyButton)
                                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    .offset(x: self.isFeaturedAllowed ? 12 : -12)
                                    .animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0))
                            }
                        }
                        .buttonStyle(ButtonBounce())
                    }
                    .frame(width: screenWidth - 40)
                    .padding(.top, 10)

                    Group {
                        Spacer().frame(height: 15)
                        HStack {
                            Text("follow us")
                                .modifier(TextModifier(size: 22, font: Font.ttNormsBold))
                            Spacer()
                        }
                        .frame(width: screenWidth - 40)
                        .padding(.bottom, 5)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack  {
                                 Spacer().frame(width: 15)
                                 SettingsSocialCell(image: "socials-tiktok",
                                                    text: "tiktok",
                                                    textColor: Color(#colorLiteral(red: 0, green: 0.9490196078, blue: 0.9176470588, alpha: 1)),
                                                    backgroundColor: Color(#colorLiteral(red: 0, green: 0.9490196078, blue: 0.9176470588, alpha: 0.15)),
                                                    isInstagram: .constant(false),
                                                    action: { self.openTikTok() })
                                 SettingsSocialCell(image: "socials-instagram",
                                                    text: "instagram",
                                                    textColor: Color(#colorLiteral(red: 0.8980392157, green: 0, blue: 0.2470588235, alpha: 1)),
                                                    backgroundColor: Color.clear,
                                                    isInstagram: .constant(true),
                                                    action: { self.openInstagram() })
                                SettingsSocialCell(image: "socials-snapchat",
                                                   text: "snapchat",
                                                   textColor: Color.snapchatYellow,
                                                   backgroundColor: Color.snapchatYellow.opacity(0.15),
                                                   isInstagram: .constant(false),
                                                   action: { self.openSnapchat() })

                                 SettingsSocialCell(image: "socials-twitter",
                                                    text: "twitter",
                                                    textColor: Color(#colorLiteral(red: 0.2196078431, green: 0.631372549, blue: 0.9529411765, alpha: 1)),
                                                    backgroundColor: Color(#colorLiteral(red: 0.2196078431, green: 0.631372549, blue: 0.9529411765, alpha: 0.15)),
                                                    isInstagram: .constant(false),
                                                    action: { self.openTwitter() })

                                 Spacer().frame(width: 15)
                             }
                        }

                        Spacer().frame(height: 10)
                        Button(action: {
                            impact(style: .soft)
                            onPresent$.send()
                        }) {
                            HStack (spacing: 12) {
                                Image("socials-iMessage")
                                    .renderingMode(.original)
                                 Text("need help or have feedback?")
                                    .modifier(TextModifier(color: Color.greenAccentColor))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .frame(width: screenWidth - 30, height: 72)
                            .background(Color.greenAccentColor.opacity(0.15).clipShape(RoundedRectangle(cornerRadius: 28)))
                        }
                        .buttonStyle(ButtonBounceLight())

                        Spacer().frame(height: 6)

                        HStack {
                            Spacer()

                            Button(action: {
                                impact(style: .soft)
                                self.legalActionSheet = true
                            }) {
                                Text("legal")
                                    .font(Font.custom(Font.textaAltBlack, size: 17))
                                    .foregroundColor(Color.white.opacity(0.6))
                                    .frame(width: 80)
                            }
                            .actionSheet(isPresented: $legalActionSheet) {
                                ActionSheet(title: Text(""),
                                            message: Text("legal stuff"),
                                            buttons: [
                                                .default(Text("Terms of User")) {
                                                    self.openTerms()
                                                },
                                                .default(Text("Privacy Policy")) {
                                                    self.openPrivacy()
                                                },
                                                .cancel()
                                ])
                            }
                            Spacer()
                            Text("logout")
                                .modifier(TextModifier(color: Color.white.opacity(0.6)))
                                .onTapGesture {
                                    self.logoutActionSheet = true
                            }
                            .padding(.top, 3)
                            .actionSheet(isPresented: $logoutActionSheet) {
                                ActionSheet(title: Text(""),
                                            message: Text("Are you sure you want to logout?"),
                                            buttons: [
                                                .destructive(Text("Logout")) {
                                                    self.onComplete()
                                                    self.state.audioPlayer.stopPlayback()
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                        self.state.moveToProfile = false
                                                        self.state.moveToHome = true
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                                            AuthService.logout() {
                                                                self.state.onboardingStage = .AppleLogin
                                                                self.state.isOnboarding = true
                                                                self.state.currentUser = nil
                                                            }
                                                        }
                                                    }
                                                },
                                                .cancel()
                                ])
                            }

                            Spacer()
                            Text("v\(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)")
                            .font(Font.custom(Font.textaAltBlack, size: 17))
                            .foregroundColor(Color.white.opacity(0.6))
                            .frame(width: 80)
                            .onTapGesture(count: 2) { self.state.isAdmin.toggle() }
                            Spacer()

                        }
                        .padding(.horizontal, 20)

                        Spacer()
                        TextButton(
                            title: "close",
                            color: Color.white.opacity(0.1),
                            textColor: Color.white,
                            width: 114,
                            height: 46,
                            action: { self.self.onClose?()  })
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, isIPhoneX ? 45 : 30)
                .frame(width: screenWidth, height: cardHeight)
                .background(
                    BackgroundBlurView(style: .prominent)
                        .frame(width: screenWidth, height: cardHeight)
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

            .onAppear {
                guard let userID = self.state.currentUser?.uid else { return }
                let featuredAllowed = SupUserDefaults.featureAllowed(userID: userID)
                self.isFeaturedAllowed = featuredAllowed
            }
            
            MessageComposeView(
                     body: "",
                     number: "4243240442",
                     onPresent$: onPresent$
                 ).frame(width: 0, height: 0)
        }
        .transition(.move(edge: .bottom))
        .animation(.spring())
    }
}

struct SettingsCard_Previews: PreviewProvider {
    static var previews: some View {
        SettingsCard(state: AppState(), onComplete:{})
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

struct SettingsHeader: View {
    let text: String
    var topPadding: CGFloat = 20

    var body: some View {
        Button(action: {}) {
            HStack {
                Text(text)
                    .modifier(TextModifier(size: 20, color: Color.secondaryTextColor.opacity(0.7)))
                    .padding(.leading, 15)
                    .animation(nil)
                Spacer()
            }
        }
        .buttonStyle(ButtonBounceNone())
        .frame(width: screenWidth - 30)
        .padding(.top, topPadding)
        .padding(.bottom, 5)
    }
}

struct SettingsSocialCell: View {
    let image: String
    let text: String
    let textColor: Color
    let backgroundColor: Color
    @Binding var isInstagram: Bool
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action?()
        }) {
            VStack (spacing: 12) {
                Image(image)
                    .renderingMode(.original)
                VStack {
                    Text(text)
                        .modifier(TextModifier(color: textColor))
                }
            }
            .frame(width: 110, height: 114)
            .background(
                ZStack {
                    if self.isInstagram {
                        LinearGradient(gradient: Gradient(colors: [ Color(#colorLiteral(red: 0.8980392157, green: 0, blue: 0.2470588235, alpha: 1)), Color(#colorLiteral(red: 0.3294117647, green: 0.003921568627, blue: 0.7568627451, alpha: 1))]),
                                       startPoint: .leading,
                                       endPoint: .trailing
                        ).opacity(0.3)
                    } else {
                        self.backgroundColor
                    }
                }
            ).clipShape(RoundedRectangle(cornerRadius: 21))
        }
        .buttonStyle(ButtonBounceLight())
    }
}

//HStack (spacing: 15) {
//    Text("terms")
//        .modifier(TextModifier(size: 17, color: sColor.opacity(0.8)))
//        .onTapGesture {
//            self.openTerms()
//    }
//    Circle()
//        .frame(width: 8, height: 8)
//        .foregroundColor(sColor.opacity(0.6))
//        .padding(.top, 2)
//
//    Text("privacy")
//        .modifier(TextModifier(size: 17, color: sColor.opacity(0.8)))
//        .onTapGesture {
//            self.openPrivacy()
//    }
//}

//SettingsSocialCell(image: "socials-youtube",
//                   text: "youtube",
//                   backgroundColor: Color(#colorLiteral(red: 0.3058823529, green: 0.07843137255, blue: 0.0862745098, alpha: 1)),
//                   isInstagram: .constant(false),
//                   action: { self.openTwitter() })
