//
//  EmojiCallView.swift
//  sup
//
//  Created by Justin Spraggins on 7/7/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SDWebImageSwiftUI
import SwiftUI

struct EmojiCallView: View {
    @ObservedObject var state: AppState
    @State var users = [User]()
    @State var selectedUser = false
    @State var publisherAudio: Float = 0.0
    @State var subscriberAudio: Float = 0.0
    @State var animateLogo = false
    @State var shake = false
    @State var shakeMatching = false

    private var showMainLogo: Bool {
        !self.state.hideLogoButton &&
            !self.state.isConnect &&
            !self.state.isConnecting &&
            !self.state.browseQuestions &&
            !self.state.liveMatching &&
            !self.state.isConnectHappyHour
    }

    private func closeOutgoing() {
        if AppDelegate.callSessionId != nil {
            FirebaseCall.update(
                sessionId: AppDelegate.callSessionId!,
                data: ["status": "canceled"]
            )
        } else {
            // You hung up before a callSessionId was created
            // We should probably only show the hang up button after this
            // is set
        }
        impact(style: .soft)
        self.state.audioPlayer.stopRingTone()
        self.resetSelectedUsers()
        AppPublishers.guestUser$.send()
        self.state.guestSelected = false
        self.state.hideNav = false
        self.state.hideLogoButton = false
        self.state.showQuestions = true
    }

    func addSelectedUsers() {
        var selectedUsers: [User] = []
        for user in self.state.guestUsers {
            if user.isSelected {
                selectedUsers.append(user)
            }
        }
        users = selectedUsers

        if !users.isEmpty {
            selectedUser = true
        } else {
            selectedUser = false
        }
    }

    func resetSelectedUsers() {
        var users: [User] = []
        for user in self.state.guestUsers {
            let suser = user
            suser.isSelected = false
            users.append(suser)
        }
        self.state.guestUsers = users
    }

    func colorCache() -> Color {
        let defaults = UserDefaults.standard
        if let color = defaults.string(forKey: "color") {
            return Color(color.color())
        } else {
            if let currentUser = self.state.currentUser {
                defaults.set(currentUser.color, forKey: "color")
            }
            return state.color(user: self.state.currentUser)
        }
    }

    private func showCoinCard() {
        impact(style: .soft)
        self.state.showCoinsCard = true
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
        ZStack {
            VStack (spacing: 0) {
                ZStack {
                    Rectangle()
                        .frame(width: screenWidth, height: screenHeight/2)
                        .foregroundColor(colorCache().opacity(0.4))

                    if self.state.isConnect {
                        Circle()
                            .foregroundColor(Color.white.opacity(0.1))
                            .frame(width: 130, height: 130)
                            .scaleEffect(1 + CGFloat(publisherAudio)/2)
                            .animation(.spring())
                            .background(
                                Circle()
                                    .foregroundColor(Color.white.opacity(0.1))
                                    .frame(width: 130, height: 130)
                                    .opacity(publisherAudio == 0 ? 0 : 1)
                                    .animation(.easeInOut(duration: 0.3))
                                    .scaleEffect(1 + CGFloat(publisherAudio)*1.5)
                                    .animation(Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0).speed(0.9))
                        )
                    }

                    ProfileAvatar(state: state,
                    currentUser: .constant(true),
                    tapAction: { },
                    size: 100)
                }
                .frame(width: screenWidth, height: screenHeight/2)

                ZStack {
                    Spacer().frame(width: screenWidth, height: screenHeight/2)

                    if self.selectedUser {
                        ZStack {
                            Rectangle()
                                .frame(width: screenWidth, height: screenHeight/2)
                                .foregroundColor(
                                    state.color(user: self.users[0]).opacity(0.3)
                            )
                            Circle()
                                .foregroundColor(Color.white.opacity(0.1))
                                .frame(width: 130, height: 130)
                                .opacity(state.isConnect ? 1 : 0)
                                .animation(.easeInOut(duration: 0.3))
                                .scaleEffect(1 + CGFloat(subscriberAudio)/2)
                                .animation(.spring())
                                .background(
                                    Circle()
                                        .foregroundColor(Color.white.opacity(0.1))
                                        .frame(width: 130, height: 130)
                                        .opacity(subscriberAudio == 0 ? 0 : 1)
                                        .animation(.easeInOut(duration: 0.3))
                                        .scaleEffect(1 + CGFloat(subscriberAudio)*1.5)
                                        .animation(Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0).speed(0.9))
                            )
                            WebImage(url: URL(string: self.users[0].avatarUrl ?? ""))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                        }
                        .frame(width: screenWidth, height: screenHeight/2)
                    }
                }
                .frame(width: screenWidth, height: screenHeight/2)
            }

            if self.state.guestSelected {
                VStack {
                    Button(action: {
                        self.closeOutgoing()
                    }) {
                        ZStack {
                            Color.white.opacity(0.3)
                                .frame(width: 168, height: 70)
                                .cornerRadius(24)
                            RoundedRectangle(cornerRadius: 22)
                                .frame(width: 158, height: 60)
                                .foregroundColor(Color.redDark.opacity(0.8))

                            HStack (spacing: 12) {
                                Image("nav-phone")
                                    .renderingMode(.template)
                                    .foregroundColor(Color.redColor)
                                Text("calling...")
                                    .modifier(TextModifier(size: 21, font: Font.textaAltBlack, color: Color.redColor))
                                    .padding(.bottom, 4)
                            }
                        }
                    }
                    .buttonStyle(ButtonBounce())
                    .frame(width: 168, height: 70)
                    .rotationEffect(Angle(degrees:  self.shake ? 5 : 0))
                    .animation(Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true).speed(0.5))
                    .onAppear() {
                        impact(style: .rigid)
                        self.shake.toggle()
                    }
                }
                .transition(AnyTransition.scale.combined(with: .opacity))
            }

            if self.state.isConnecting {
                VStack {
                    Button(action: {
                    }) {
                        ZStack {
                            BackgroundBlurView(style: .systemUltraThinMaterialLight)
                                .frame(width: 188, height: 70)
                                .cornerRadius(24)
                            RoundedRectangle(cornerRadius: 22)
                                .frame(width: 178, height: 60)
                                .foregroundColor(Color.black.opacity(0.2))
                            
                            Text("connecting...")
                                .modifier(TextModifier(size: 21, font: Font.textaAltBlack, color: Color.white))
                                .padding(.bottom, 4)
                        }
                    }
                    .disabled(true)
                    .frame(width: 168, height: 70)
                }
                .transition(AnyTransition.scale.combined(with: .opacity))
            }

            if self.state.liveMatching && !self.state.browseQuestions {
                VStack {
                    Button(action: {
                        HappyHour.removeFromQueue(userID: self.state.currentUser?.uid)
                        DispatchQueue.main.async {
                            self.state.liveMatching = false
                            self.state.happyHourLogo = false
                            self.state.isConnectHappyHour = false
                        }
                    }) {
                        ZStack {
                            BackgroundBlurView(style: .systemUltraThinMaterialLight)
                                .frame(width: 188, height: 70)
                                .cornerRadius(24)
                            RoundedRectangle(cornerRadius: 22)
                                .frame(width: 178, height: 60)
                                .foregroundColor(Color.black.opacity(0.2))

                            HStack (spacing: 12) {
                                Image("dice-emoji-large")
                                    .renderingMode(.original)
                                Text("matching...")
                                    .modifier(TextModifier(size: 21, font: Font.textaAltBlack, color: Color.white))
                                    .padding(.bottom, 4)
                            }
                        }
                    }
                    .buttonStyle(ButtonBounce())
                    .frame(width: 188, height: 70)
                    .rotationEffect(Angle(degrees:  self.shakeMatching ? 5 : 0))
                    .animation(Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true).speed(0.5))
                    .onAppear() {
                        impact(style: .rigid)
                        self.shakeMatching.toggle()
                    }
                }
                .transition(AnyTransition.scale.combined(with: .opacity))
            }

            if showMainLogo {
                VStack {
                    Button(action: { self.showCoinCard() }) {
                        ZStack {
                            BackgroundBlurView(style: .prominent)
                                .frame(width: 152, height: 70)
                                .cornerRadius(24)
                            RoundedRectangle(cornerRadius: 22)
                                .background(Color.white.opacity(0.05).cornerRadius(22))
                                .frame(width: 142, height: 60)
                                .foregroundColor(colorCache().opacity(0.3))

                            Image("main-logo")
                                .renderingMode(.original)
                                .padding(.top, 4)
                        }
                    }
                    .buttonStyle(ButtonBounce())
                    .frame(width: 152, height: 70)
                }
                .transition(AnyTransition.scale.combined(with: .opacity))
            }
        }
        .frame(width: screenWidth, height: screenHeight)
        .onAppear {
            DispatchQueue.main.async {
                if self.state.showOutgoing {
                    self.addSelectedUsers()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.resetSelectedUsers()
                    }
                }
            }
        }
        .onReceive(AppPublishers.guestUser$.eraseToAnyPublisher()) { _ in
            self.addSelectedUsers()
        }
        .onReceive(AppPublishers.callStatusUpdated$) { callStatus in
            if callStatus == "canceled" || callStatus == "end" {
                self.selectedUser = false
            }
        }
        .onReceive(AppPublishers.publishFlowDone$) {
            self.selectedUser = false
        }
        .onReceive(AppPublishers.hostUser$) { hostUser in
            if let hostUser = hostUser {
                self.users = [hostUser]
                self.selectedUser = true
            }
        }
        .onReceive(AppPublishers.publisherAudioLevelUpdated$.eraseToAnyPublisher()) { audioLevel in
            self.publisherAudio = audioLevel
        }
        .onReceive(AppPublishers.subscriberAudioLevelUpdated$.eraseToAnyPublisher()) { audioLevel in
            self.subscriberAudio = audioLevel
        }
    }
}
