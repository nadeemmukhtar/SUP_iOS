//
//  StartCall.swift
//  sup
//
//  Created by Justin Spraggins on 3/18/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import FirebaseAnalytics
import PaperTrailLumberjack
import SDWebImageSwiftUI
import SwiftUI
import MessageUI
import Combine

private let onPresent$ = PassthroughSubject<Void, Never>()

struct StartCall: View {
    @ObservedObject var state: AppState
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    @State var scale = true
    @State var pulsate = false
    @State var pulsateHappyHour = false
    @State var animateGuestSelected = false
    @State var showAlert = false
    @State var deleteActionSheet = false
    @State var showQuestionCard = false
    @State var animateQuestionCard = false
    @State var index = 0
    @State var refreshQuestions = false
    @State private var sharePassAlert = false
    @State var showingShare = false
    @State var cardState = CGSize.zero

    var inviteLink: String? {
        state.currentUser?.inviteURL
    }

    var hidePower: Bool {
        !state.animateStartButton
    }

    private func showOutgoing() {
        impact(style: .soft)
        let selectedGuests = self.state.guestUsers.filter { $0.isSelected }
        makeCall(to: selectedGuests)
        self.state.audioPlayer.playRingTone(resource: "outgoing-call", of: "m4a")
        self.state.showOutgoing = true
        self.state.guestSelected = true
        self.state.hideNav = true
        self.state.hideLogoButton = true
        self.state.showQuestions = false
    }

    private func closeGuestList() {
        impact(style: .soft)
        self.state.showGuestList = false
    }

    private func makeCall(to selectedGuests: [User]) {
        guard selectedGuests.count > 0 else { return }
        guard let username = state.currentUser?.username else { return }

        let to = selectedGuests.compactMap { (guest) in
            return guest.username
        }
        var json: [String: Any] = ["from": username, "to": to]
        #if DEBUG
        json["env"] = "sandbox"
        #endif

        SupAPI.callkit(json: json) { response in
            switch response {
            case .success(let response):
                DDLogVerbose("SupAPI.callkit success: response=\(response) json=\(json)")
                Logger.log("SupAPI.callkit success: sessionId=%{public}@", log: .debug, type: .debug, response.sessionId)
                self.initiateHostCall(response: response)
            case .failure(let error):
                Logger.log("SupAPI.callkit failure: %{public}@", log: .debug, type: .debug, error.localizedDescription)
                DDLogError("SupAPI.callkit failure: error=\(error.localizedDescription) json=\(json)")
            }
        }
    }

    private func initiateHostCall(response: SupAPI.Call) {
        DispatchQueue.main.async {
            self.state.callBaseURL = FirebaseCall.callJoinURL(sessionId: response.sessionId)
        }
        AppDelegate.isCaller = true
        AppDelegate.callSessionId = response.sessionId
        AppDelegate.callListener?.remove()
        AppDelegate.callListener = FirebaseCall.listenToCall(sessionId: response.sessionId) { (callStatus, startTime) in
            Logger.log("call status changed: %{public}@", log: .debug, type: .debug, callStatus)

            if callStatus == "answer" {
                SupAnalytics.startPodcast()
                self.state.callInitiated$.send(response)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    AppDelegate.appState!.callerLoadingCall = true
                }
            }
            if callStatus == "recording-started" && startTime > 0 {
                DispatchQueue.main.async {
                    self.onRecordingStarted()
                }
            }
            if callStatus == "end" {
                DispatchQueue.main.async {
                    AppPublishers.onCallEnd$.send()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        self.onRecordingEnded()
                    }
                }
            }
        }
    }

    private func onRecordingStarted() {
        if AppDelegate.isCaller && AppDelegate.callSessionId != nil {
            SupAPI.startArchive(sessionId: AppDelegate.callSessionId!) { response in
                switch response {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.state.callArchiveId = response.id
                    }
                case .failure(let error):
                    // TODO: do something with UI
                    Logger.log("SupAPI.startArchive failure: %{public}@", log: .debug, type: .error, error.localizedDescription)
                }
            }
        }
    }

    private func onRecordingEnded() {
        if let callArchiveId = self.state.callArchiveId {
            let baseURL = "https://sup-archives.s3.us-east-2.amazonaws.com/46602742"
            let url = "\(baseURL)/\(callArchiveId)/archive.mp4"
            if AppDelegate.isCaller {
                self.state.audioRecorder.checkFileExists(withLink: url, includeLastPath: true) { audioUrl in
                    DDLogVerbose("recording downloaded")
                    AppDelegate.isCaller = false
                    self.state.isCallArchived = true
                    AppDelegate.callListener?.remove()
                }
            }
        }
    }

    private func openRecentGuest() {
        impact(style: .soft)
        SupUserDefaults.timesRateShown = SupUserDefaults.timesRateShown + 1
        SupUserDefaults.timesStartHintShown = SupUserDefaults.timesStartHintShown + 1
        if SupUserDefaults.timesRateShown == 3 {
            self.showRateCard()
        } else {
            self.state.moveMainUp = true
            self.state.browseQuestions = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.state.showGuestList = true
                self.state.showQuestions = false
            }
        }
    }

    private func closeRecentGuest() {
        impact(style: .soft)
        self.state.showGuestList = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.state.moveMainUp = false
            self.state.showQuestions = true
        }
    }

    private func showRateCard() {
        impact(style: .soft)
        self.state.showRateCard = true
    }


    private var showInvite: Bool {
        !self.state.guestSelected &&
            !self.state.isConnect &&
            !self.state.moveMainUp &&
            !self.state.isConnecting &&
            !self.state.hideInvite &&
            !self.state.happyHourLogo &&
            !self.state.isConnectHappyHour &&
            !self.state.liveMatching
    }

    private var noGuests: Bool {
        self.state.guest != nil && self.state.guest!.users.isEmpty
    }
    
    var body: some View {
        ZStack {
            if self.state.happyHourLogo {
                VStack (spacing: 0) {
                    Spacer()
                    ZStack {
                        Image("happyHour-logo")
                            .scaleEffect(self.pulsateHappyHour ? 1 : 1.05)
                            .shadow(color: Color.black.opacity(0.2), radius: 40, x: 0, y: 0)
                            .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true).speed(1.5))
                            .onAppear() {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    self.pulsateHappyHour.toggle()
                                }
                        }
                    }
                    .frame(width: screenWidth, height: screenHeight/2)
                }
            }

            if self.showInvite {
                VStack (spacing: 0) {
                    Spacer()
                    ZStack {
                        VStack (spacing: 20) {
                            Button(action: { self.openRecentGuest() }) {
                                         ZStack {
                                             Circle()
                                                .frame(width: 100, height: 100)
                                                .foregroundColor(Color.white)
                                                 .opacity(self.scale ? 0 : 0.1)
                                                 .animation(.easeInOut(duration: 0.3))
                                                .scaleEffect(self.scale ? 0.8 : 1.4)
                                                 .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true).speed(0.6))
                                                 .onAppear() {
                                                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                                         self.scale.toggle()
                                                     }
                                             }
                                            BackgroundBlurView(style: .systemUltraThinMaterialDark)
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())

                                             Image("start-call")
                                                 .renderingMode(.template)
                                                .foregroundColor(.white)
                                         }
                                         .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 0)
                                         .scaleEffect(self.pulsate ? 1 : 1.05)
                                         .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true).speed(1.5))
                                         .onAppear() {
                                             DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                                 self.pulsate.toggle()
                                             }
                                         }
                                     }
                                     .buttonStyle(ButtonBounce())

                            if SupUserDefaults.timesStartHintShown <= 1  {
                                Text("tap to start a sup")
                                    .modifier(TextModifier(size: 20, font: Font.ttNormsBold, color: Color.white.opacity(0.4)))
                                    .frame(width: screenWidth)
                            }
                        }
                    }
                    .frame(width: screenWidth, height: screenHeight/2)
                }
                .frame(width: screenWidth, height: screenHeight)
                .transition(.opacity)
            }

            ZStack {
                VStack (spacing: 0) {
                    Spacer().frame(height: isIPhoneX ? 80 : 70)
                    ScrollableView(self.$contentOffset, animationDuration: 0.5, action: { _ in }) {
                        Spacer().frame(height: 60)

                        if self.noGuests {
                            Spacer().frame(height: isIPhoneX ? 30 : 20)
                            Text("no guests")
                                .modifier(TextModifier(size: 26,
                                                       font: Font.ttNormsBold,
                                                       color: Color.white))
                            Spacer().frame(height: 10)
                            HStack {
                                Spacer()
                                Text("record sups with friends that accept your\nguest pass invite.")
                                    .modifier(TextModifier(size: 18, font: Font.textaBold, color: Color.secondaryTextColor))
                                    .frame(width: screenWidth - 50)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(0)
                                    .padding(.bottom, 4)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            Spacer().frame(height: 25)
                        } else {
                            TitleHeader(text: "new guest")
                        }
                        VStack (spacing: 10) {
                              InviteGuestSocial(image: "share-snapchat",
                                                text: "snap guest pass",
                                                textColor: Color.backgroundColor,
                                                bgColor: Color.snapchatYellow,
                                                isSnapchat: .constant(true),
                                                isColor: .constant(true),
                                                action: {
                                                  impact(style: .soft)
                                                  self.presentSnapchat()
                              })

                            if self.noGuests {
                                InviteGuestSocial(image: "share-iMessage",
                                                  text: "iMessage",
                                                  textColor: Color.backgroundColor,
                                                  bgColor: Color.greenAccentColor,
                                                  isSnapchat: .constant(true),
                                                  isColor: .constant(true),
                                                  action: {
                                                    impact(style: .soft)
                                                    onPresent$.send()
                                })
                            }

                              InviteGuestSocial(image: "invite-more",
                                                text: "more options",
                                                isSnapchat: .constant(false),
                                                isColor: .constant(false),
                                                action: {
                                                  impact(style: .soft)
                                                  self.showingShare = true
                              })
                                .sheet(isPresented: self.$showingShare) {
                                      ShareSheet(activityItems: ["let's record a sup. tap the link to accept my invite to be added to my guest list 👇 \(self.inviteLink ?? "")"])
                              }
                          }
                        Spacer().frame(height: 25)
                        if !self.noGuests {
                            TitleHeader(text: "start a sup")
                            VStack (spacing: 10) {
                                ForEach(self.state.guestUsers) { user in
                                    StartCallRecents(user: user,
                                                     isSelected: user.isSelected,
                                                     action: {
                                                        self.state.micPermissions { allowed in
                                                            if allowed {
                                                                self.closeRecentGuest()
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                                                    self.update(
                                                                        username: user.username ?? "",
                                                                        isSelected: !user.isSelected
                                                                    )
                                                                    AppPublishers.guestUser$.send()

                                                                    if self.guestSelected() {
                                                                        self.showOutgoing()
                                                                    }
                                                                }

                                                            } else {
                                                                self.state.promptForPermissions()
                                                            }
                                                        }
                                    })
                                }
                            }
                            .frame(width: screenWidth)
                        }
                        Spacer()
                        Spacer().frame(height: isIPhoneX ? 100 : 80)
                    }
                }

                VStack {
                    Spacer()
                    Button(action: { self.closeRecentGuest() }) {
                        ZStack {
                            BackgroundBlurView(style: .prominent)
                                .frame(width: 74, height: 74)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 5)
                            Image("profile-close")
                                .renderingMode(.template)
                                .foregroundColor(Color.white)
                        }
                    }
                    .buttonStyle(ButtonBounce())
                    .padding(.bottom, isIPhoneX ? 45 : 22)
                }
            }
            .frame(width: screenWidth, height: screenHeight)
            .opacity(self.state.showGuestList ? 1 : 0)
            .animation(.easeInOut(duration: 0.4))
            .offset(y: self.state.showGuestList ? 0 : screenHeight)
            .animation(.spring())

            MessageComposeView(
                body: "let's record a sup. tap the link to accept my invite to be added to my guest list 👇 \(self.inviteLink ?? "")",
                onPresent$: onPresent$
            ).frame(width: 0, height: 0)
        }
        .frame(width: screenWidth, height: screenHeight)
        .alert(isPresented: self.$sharePassAlert) {
            Alert(title: Text("Wanna record sups with friends?"),
                  message: Text("Share your guest pass to your Snapchat story to earn 150 sup coins."),
                  primaryButton: .default(Text("Later"), action: {
                    SupAnalytics.alertLaterGuestPass()
                    SupUserDefaults.timesSharePassHintShown = SupUserDefaults.timesSharePassHintShown + 1
                  }),
                  secondaryButton: .default(Text("OK"),
                                            action: {
                                                SupAnalytics.alertOkayGuestPass()
                                                self.presentSnapchat()
                                                SupUserDefaults.timesSharePassHintShown = SupUserDefaults.timesSharePassHintShown + 1
                                                guard var coins = self.state.currentUser?.coins else { return }
                                                coins = coins + 150
                                                self.state.add(coins: coins) { _ in }
                  }))
        }
        .onReceive(AppPublishers.happyHourHostStart$) { (sessionId, token) in
            let call = SupAPI.Call(sessionId: sessionId, token: token, answered: true)
            self.initiateHostCall(response: call)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if SupUserDefaults.timesSharePassHintShown == 0 {
                    self.sharePassAlert = true
                }
            }
        }
    }
    
    func guestSelected() -> Bool {
        for user in self.state.guestUsers {
            if user.isSelected {
                return true
            }
        }
        return false
    }
    
    func update(username: String, isSelected: Bool) {
        let susers = self.state.guestUsers.filter({ $0.isSelected })
        if susers.count < 2 || !isSelected {
            var users: [User] = []
            for user in self.state.guestUsers {
                let suser = user
                if user.username == username {
                    suser.isSelected = isSelected
                }
                users.append(suser)
            }
            self.state.guestUsers = users
        } else {
            self.showAlert = true
        }
    }
            
    private func add(question: Question) {
        if !self.state.questions.contains(where: { $0.id == question.id }) {
            self.state.questions.insert(question, at: 0)
        }
    }
}

struct StartCallRecents: View {
    var user: User
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            HStack (spacing: 12) {
                ZStack {
                    WebImage(url: URL(string: user.avatarUrl ?? ""))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                }
                VStack (alignment: .leading, spacing: 0) {
//                    if user.displayName != nil {
//                        Text(user.displayName ?? "")
//                            .modifier(TextModifier(size: 20, font: Font.textaAltBold))
//                            .lineLimit(0)
//                            .truncationMode(.tail)
//                    }

                    Text(user.username ?? "")
                        .modifier(TextModifier(size: 20, color: Color.white))
                        .lineLimit(0)
                        .truncationMode(.tail)
                }
                .padding(.bottom, 2)
                Spacer()
                Image("cell-phone")
                    .renderingMode(.template)
                    .foregroundColor(Color.white.opacity(0.8))
            }
            .padding(.leading, 20)
            .padding(.trailing, 25)
            .frame(width: screenWidth - 30, height: 84)
            .background(Color.white.opacity(0.1).clipShape(RoundedRectangle(cornerRadius: 21)))
        }
        .buttonStyle(ButtonBounceLight())
    }
}

struct StartCallNew: View {
    var image: String
    var text: String
    @Binding var imagePadding: Bool
    var action: () -> Void

    var body: some View {
        VStack (spacing: 5){
            Button(action: {
                impact(style: .soft)
                self.action()
            }) {
                ZStack {
                    Color.cardCellBackground
                        .frame(width: 58, height: 58)
                        .clipShape(Circle())
                    Image(image)
                        .renderingMode(.template)
                        .foregroundColor(Color.white)
                        .padding(.leading, imagePadding ? 2 : 0)
                        .padding(.top, imagePadding ? 2 : 0)
                }
            }
            .buttonStyle(ButtonBounceLight())
        }
    }
}

struct TitleHeader: View {
    let text: String
    var body: some View {
        HStack {
            Text(text)
                .modifier(TextModifier(size: 20, font: Font.textaAltBold))
            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(height: 20)
    }
}

struct GuestPass: View {
    @ObservedObject var state: AppState

    var body: some View {
        ZStack {
            Image("guest-pass")
            VStack (spacing: 0) {
                ProfileAvatar(state: state,
                              currentUser: .constant(true),
                              tapAction: { },
                              size: 56)

                Spacer().frame(height: 29)

                Text("\(self.state.currentUser?.username ?? "my") podcast")
                    .modifier(TextModifier(size: 11, font: Font.textaAltBlack, color: Color.backgroundColor))
                    .frame(width: 110)
                    .truncationMode(.tail)
                    .lineLimit(0)
            }.padding(.top, 63)
        }
    }
}

extension StartCall {
    private func presentSnapchat() {
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postInviteToSnapchat(url: "\(self.inviteLink ?? "")", vc: vc)
    }
}

