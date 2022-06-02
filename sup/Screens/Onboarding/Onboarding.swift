//
//  Onboarding.swift
//  sup
//
//  Created by Justin Spraggins on 2/1/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import FirebaseStorage
import AVFoundation
import PaperTrailLumberjack
import OneSignal

private let storageRef = Storage.storage().reference()
private let avatarImageRef = storageRef.child("images/avatars")

struct OnboardingCard: View {
    @ObservedObject var state: AppState
    @State private var signInDelegate: AuthServiceDelegate! = nil
    @State var initialAnimation = true
    @State var closeAvatar = false
    @State var showNotification = false
    @State var notification = "there was an error"
    @State var isLoading = false
    @State var showLoader = false
    @State var snapLoader = false
    @State var playingAudio = false
    @State var hideText = false
    @State var showUsernameAlert = false
    @State var usernameLoader = false
    @State var usernameInput = true
    @State private var isTyping = false
    @State var showKeyboard = false
    @State var animatePermissions = false
    @State var testOnboarding = false
    @State var pulsate = false
    @State var appleSignIn = false

    // For logging in as users in DEBUG mode
    @State private var loginAsUserShown = false
    @State private var loginAs: String = ""
    @State private var showAlertForMissingUsername = false

    let avatarHeight: CGFloat = 98
    let videoWidth: CGFloat = isIPhoneX ? screenWidth + 30 : screenWidth

    private func closeKeyboard() {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        keyWindow!.endEditing(true)
    }
    
    func playOnboardingAudio() {
        if self.playingAudio {
            self.state.audioPlayer.pausePlayback()
            self.playingAudio = false
        } else {
            self.playingAudio = true
            let path = Bundle.main.path(forResource: "onboarding-intro", ofType: "m4a")!
            self.state.audioPlayer.startPlayback(audio: URL(fileURLWithPath: path))
        }
    }
    
    func moveToLogin() {
        self.playingAudio = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.closeAvatar = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.state.onboardingStage = .AppleLogin
            }
        }
    }
    
    var loginStage: Bool {
        state.onboardingStage == .AppleLogin && !isLoading
    }
    
    var createProfile: Bool {
        state.onboardingStage == .ConnectSnapchat
    }
    
    var usernameStage: Bool {
        state.onboardingStage == .ClaimUsername
    }

    var notificationStage: Bool {
        state.onboardingStage == .PushNotifications
    }

    var permissionStage: Bool {
        self.state.onboardingStage == .PermissionSettings
    }

    private func onLogin(success: Bool, user: User?, isSnap: Bool = false) {
        if success {
            if user == nil || user?.username == nil || user?.username?.isEmpty == true {
                if isSnap {
                    self.state.onboardingStage = .ClaimUsername
                    self.showKeyboard = true
                } else {
                    self.state.onboardingStage = .ConnectSnapchat
                }
            } else {
                self.state.isOnboarding = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.state.onboardingStage = .AppleLogin
                }
            }
        }
        self.isLoading = false
    }

    private func updateInviteLink() {
        guard let currentUser = self.state.currentUser else {
            return
        }

        let uuid = currentUser.dynamicLinkUUID ?? UUID().uuidString
        if currentUser.inviteURL == nil {
            DynamicLinkCreator(uuid: uuid, user: currentUser).call() { inviteURL in
                if inviteURL != nil {
                    User.update(userID: currentUser.uid, data: [
                        "dynamicLinkUUID": uuid,
                        "inviteURL": inviteURL!
                    ])
                    currentUser.dynamicLinkUUID = uuid
                    currentUser.inviteURL = inviteURL!
                    self.state.currentUser = currentUser
                }
            }
        }
    }

    private func siginInWithApple() {
        DDLogVerbose("sign in with Apple pressed")
        impact(style: .soft)
        if self.testOnboarding {
            self.closeLoginCard()
            self.isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.isLoading = false
                self.state.onboardingStage = .ConnectSnapchat
            }
        } else {
            self.state.audioPlayer.playAppSound(resource: "ButtonPress1", of: "wav")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isLoading = true
                    self.closeLoginCard()
                }
                self.signInDelegate = AuthServiceDelegate() { success, user in
                    self.onLogin(success: success, user: user)
                }
                AuthService.startSignInWithAppleFlow(delegate: self.signInDelegate)
            }
        }
    }

    private func connectSnapchat(signIn: Bool = true) {
        DDLogVerbose("connect with Snap pressed")
        impact(style: .soft)
        if self.testOnboarding {
            self.isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.isLoading = false
                self.state.onboardingStage = .ClaimUsername
                self.showKeyboard = true
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isLoading = true
            }
            if signIn {
                AuthService.loginWithSnap(state: self.state) { hasError, currentUser in
                    self.onLogin(success: !hasError, user: currentUser, isSnap: true)
                }
            } else {
                self.state.getSnapchatInfo {
                    DispatchQueue.global(qos: .background).async {
                        let currentUser = self.state.currentUser
                        var data = [String: Any]()
                        if let name = self.state.snapchatDisplayName {
                            data["displayName"] = name
                            currentUser?.displayName = name
                        }
                        User.update(userID: self.state.currentUser?.uid, data: data)
                        DispatchQueue.main.async {
                            self.state.currentUser = currentUser
                            self.state.uploadImage()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.isLoading = false
                                self.state.onboardingStage = .ClaimUsername
                                self.showKeyboard = true
                            }
                        }
                    }
                }
            }
        }
    }

    private func imReady() {
        self.completeOnboarding()
        self.animatePermissions = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.state.isOnboarding = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.state.onboardingStage = .AppleLogin
            }
        }
    }

    private func completeOnboarding() {
        guard let currentUser = self.state.currentUser else {
            return
        }

        User.update(userID: currentUser.uid, data: [
            "completedOnboarding": true,
            "happyHour": true,
        ])

        currentUser.completedOnboarding = true
        self.state.currentUser = currentUser

        AppDelegate.dynamicLinks.forEach { dynamicLink in
            User.fromDynamicLink(dynamicLink, currentUserId: AppDelegate.currentUserId)
        }

        AppDelegate.dynamicLinks = []
    }

    func allowPush() {
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            self.state.onboardingStage = .PermissionSettings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.animatePermissions = true
            }
        })
    }

    private func showLoginCard() {
        impact(style: .soft)
        self.state.showLoginCard = true
    }

    private func closeLoginCard() {
        impact(style: .soft)
        self.state.showLoginCard = false
    }

    var body: some View {
        ZStack {
            BackgroundColorView(color: permissionStage ? Color.backgroundColor :
                loginStage ? Color(#colorLiteral(red: 0.8901960784, green: 0.8941176471, blue: 0.8980392157, alpha: 1)) : Color.lightBackground)
                .animation(.easeInOut(duration: 0.4))

            if loginStage {
                VStack (spacing: 0) {
                    Spacer().frame(height: isIPhoneX ? 25 : -10)
                    PlayerSigninView()
                        .frame(width: videoWidth, height: videoWidth * 1.777778)
                        .onTapGesture() {
                            #if DEBUG
                            self.loginAsUserShown = true
                            //                            self.testOnboarding = true
                            #endif
                    }
                    Spacer()
                }
                .frame(width: screenWidth, height: screenHeight)
            }

            VStack (spacing: 15) {
                ZStack {
                    Image(isIPhoneX ? "onboarding-guestPass-iPhoneX" : "onboarding-guestPass")
                        .shadow(color: Color.black.opacity(0.2), radius: 40, x: 0, y: 0)
                    if usernameStage || permissionStage || notificationStage {
                        Image(uiImage: self.state.avatarImage ?? self.state.defaultImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 78, height: 78)
                            .padding(.top, 272)
                    } else {
                        Image("sup-bitmoji")
                            .padding(.top, 268)
                            .blur(radius: loginStage ? 0 : 15)
                            .animation(.linear)
                    }
                }
                Spacer()
            }
            .frame(width: screenWidth, height: screenHeight)
            .opacity(loginStage ? 0 : 1)
            .animation(.easeInOut(duration: 0.3))
            .offset(y: loginStage ? (isIPhoneX ? -20 : -115) :
                createProfile ? (isIPhoneX ? -20 : -110) :
                usernameStage ? (isIPhoneX ? -180 : -250) :
                notificationStage ? (isIPhoneX ? -60 : -80) :
                permissionStage ? -screenHeight :
                (isIPhoneX ? -20 : -120))
                .animation(Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0))

            Group {
                if loginStage {
                    VStack {
                        Spacer()
                if self.appleSignIn {
                    Button(action: { self.siginInWithApple() }) {
                        ZStack {
                            Rectangle()
                                .foregroundColor(Color.black)
                                .frame(width: 260, height: 64, alignment: .center)
                                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 0)
                            HStack (spacing: 15) {
                                Image("onboarding-apple")
                                    .renderingMode(.original)
                                    .animation(nil)
                                Text("login with Apple")
                                    .modifier(TextModifier(size: 19, color: Color.white))
                            }
                            .padding(.horizontal, 25)
                            .frame(width: 260, height: 64)
                        }
                    }
                    .buttonStyle(ButtonBounce())
                    .opacity(!isLoading ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3))
                    .scaleEffect(!isLoading ? 1 : 0.9)
                    .animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0))

                } else {
                    Button(action: { self.connectSnapchat() }) {
                        ZStack {
                            Rectangle()
                                .foregroundColor(Color.snapchatYellow)
                                .frame(width: 260, height: 64, alignment: .center)
                                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 0)
                            HStack (spacing: 15) {
                                Image("onboarding-snapchat")
                                    .renderingMode(.original)
                                    .animation(nil)
                                Text("login with Snapchat")
                                    .modifier(TextModifier(size: 19, color: Color.black))
                            }
                            .padding(.horizontal, 25)
                            .frame(width: 260, height: 64)
                        }
                    }
                    .buttonStyle(ButtonBounce())
                    .scaleEffect(self.pulsate ? 1 : 1.05)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true).speed(1.5))
                    .onAppear() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            self.pulsate.toggle()
                        }
                    }
                    .opacity(!isLoading ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3))
                    .scaleEffect(!isLoading ? 1 : 0.9)
                    .animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0))

                        }

                        Spacer().frame(height: 20)
                        OnboardingLegal(showAppleSiginIn: { self.appleSignIn.toggle() })

                        Spacer().frame(height: isIPhoneX ? 50 : 35)
                    }
                    .frame(width: screenWidth, height: screenHeight)
                    .transition(AnyTransition.scale(scale: 0.9).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3))
                    .animation(.spring())
                }

                if isLoading {
                    VStack (spacing: 20) {
                        Spacer()
                        LoaderCircle(size: 30, innerSize: 24, isButton: true, tint: Color.backgroundColor)
                        Text("connecting snapchat...")
                            .modifier(TextModifier(size: 19, font: Font.textaAltHeavy, color: Color.backgroundColor))
                    }
                    .padding(.bottom, loginStage ? (isIPhoneX ? 110 : 90) : (isIPhoneX ? 100 : 70))
                    .frame(width: screenWidth, height: screenHeight)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3))
                }
            }

            if usernameStage {
                OnboardingTextCard(
                    state: state,
                    usernameInput: $usernameInput,
                    usernameLoader: $usernameLoader,
                    keyboardOpen: $showKeyboard,
                    isTyping: $isTyping,
                    usernamePressed: { username in
                        if self.testOnboarding {
                            self.closeKeyboard()
                            self.state.onboardingStage = .PushNotifications
                        } else {
                            self.usernameInput = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self.usernameLoader = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    if self.validate(username: username) {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            User.validate(username: username) { isExist in
                                                if !isExist {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                        self.closeKeyboard()
                                                        self.state.onboardingStage = .PushNotifications
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                            User.update(userID: self.state.currentUser?.uid, data: [
                                                                "username": username
                                                            ])
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                                self.usernameInput = true
                                                                self.usernameLoader = false
                                                            }
                                                            self.updateInviteLink()
                                                        }
                                                    }
                                                    let currentUser = self.state.currentUser
                                                    currentUser?.username = username
                                                    self.state.currentUser = currentUser
                                                    self.state.refreshGuestPassVideo()
                                                } else {
                                                    self.usernameInput = true
                                                    self.usernameLoader = false
                                                    self.show(note: "username exists")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                })
                    .alert(isPresented: self.$showUsernameAlert) {
                        Alert(title: Text("username invalid"),
                              message: Text("\nMust be 3 or more characters.\nMust be less than 15 characters.\nHave no special characters.\nHave no spaces.\nHave no uppercase characters."),
                              dismissButton: .default(Text("👍👌")) {
                                self.usernameInput = true
                                self.usernameLoader = false
                            }
                        )
                }
            }

            if notificationStage {
                VStack {
                    Spacer()
                    Text("we’ll notify you when a friend accepts your guest pass")
                        .modifier(TextModifier(size: 19, font: Font.textaAltHeavy, color: Color.backgroundColor))
                        .multilineTextAlignment(.center)
                        .frame(width: screenWidth - 60, height: 50)

                    Spacer().frame(height: 30)
                    VStack (spacing: 13) {
                        Button(action: {
                            self.allowPush()
                            guard var coins = self.state.currentUser?.coins else { return }
                            coins = coins + 100
                            self.state.add(coins: coins) { _ in }
                        }){
                            ZStack {
                                RoundedRectangle(cornerRadius: 28)
                                    .frame(width: 286, height: 62)
                                    .foregroundColor(Color.yellowAccentColor)
                                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 0)

                                HStack (spacing: 15) {
                                    Image("onboarding-bell")
                                        .renderingMode(.original)
                                        .padding(.bottom, 2)
                                    Text("enable notifications")
                                        .modifier(TextModifier(size: 20, color: Color.backgroundColor))
                                        .padding(.bottom, 1)
                                }
                            }
                        }
                        .buttonStyle(ButtonBounce())
                    }

                    Spacer().frame(height: isIPhoneX ? 80 : 50)
                }
            }

            if permissionStage {
                WelcomeCard(state: state, onOkay: { self.imReady() })
                    .opacity(animatePermissions ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3))
                    .offset(y: animatePermissions ? 0 : screenHeight)
                    .animation(Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0).speed(0.7))
            }

            if self.loginAsUserShown {
                VStack {
                    Text("Login as user")
                        .modifier(TextModifier(size: 16, font: Font.ttNormsBold))
                    HStack {
                        TextField("username...", text: $loginAs)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Button(action: {
                            User.get(username: self.loginAs) { currentUser in
                                guard let currentUser = currentUser else {
                                    self.showAlertForMissingUsername = true
                                    return
                                }

                                AppDelegate.currentUserId = currentUser.uid
                                self.state.currentUser = currentUser
                                self.state.isOnboarding = false
                                self.state.userDidLoad$.send()
                            }
                        }) {
                            Text("Login")
                                .modifier(TextModifier(size: 16, font: Font.ttNormsBold))
                        }
                        .alert(isPresented: self.$showAlertForMissingUsername) {
                            Alert(title: Text("Unknown user"), message: Text("\(self.loginAs) does not exist"), dismissButton: .default(Text("Ok")))
                        }
                    }.padding(30)
                }
                .frame(width: screenWidth, height: screenHeight)
                .background(Color.backgroundColor)
            }
        }
        .frame(width: screenWidth, height: screenHeight)
    }

    private func show(note: String) {
        self.notification = note
        self.showNotification = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showNotification = false
        }
    }
    
    private func validate(name: String) -> Bool {
        var valid = true
        var note = ""
        
        if name.isEmpty {
            valid = false
            note = "please enter name"
        }
        
        if !valid { show(note: note) }
        return valid
    }
    
    func validate(username: String) -> Bool {
        var valid = true
        var note = ""
        
        if username.isEmpty {
            valid = false
            note = "please enter username"
        } else if !isValid(username: username) {
            valid = false
            note = "please enter valid username"
        }
        
        if !valid { self.showUsernameAlert = true }
        return valid
    }
    
    func isValid(username: String) -> Bool {
        return username.range(of: "^[0-9a-z\\_]{3,15}$", options: .regularExpression) != nil
    }
}

struct OnboardingCard_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingCard(state: AppState())
    }
}

struct OnboardingLegal: View {
    @State private var fadeIn = false
    let showAppleSiginIn: () -> Void

    func openTerms() {
        let url = URL(string: "http://www.onsup.fyi/terms/")!
        UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
    }
    
    func openPrivacy() {
        let url = URL(string: "http://www.onsup.fyi/privacy/")!
        UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
    }
    
    
    var body: some View {
        HStack (spacing: 4) {
            Text("by signing up you agree to our")
                .modifier(TextModifier(size: 15, font: Font.textaAltBold, color: Color.secondaryTextColor))
                .onTapGesture (count: 2) {
                    self.showAppleSiginIn()
            }
            HStack (spacing: 4) {
                Text("terms")
                    .modifier(TextModifier(size: 15, font: Font.textaAltBlack, color: Color.secondaryTextColor))
                    .onTapGesture {
                        self.openTerms()
                }
                Text("and")
                    .modifier(TextModifier(size: 15, font: Font.textaAltBold, color: Color.secondaryTextColor))
                    .padding(.top, 1)
                Text("privacy")
                    .modifier(TextModifier(size: 15, font: Font.textaAltBlack, color: Color.secondaryTextColor))
                    .onTapGesture {
                        self.openPrivacy()
                }
            }
        }
    }
}
