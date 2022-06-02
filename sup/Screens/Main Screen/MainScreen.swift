//
//  MainScreen.swift
//  sup
//
//  Created by Justin Spraggins on 12/16/19.
//  Copyright © 2019 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import AVFoundation
import Combine
import FirebaseStorage
import OneSignal
import PaperTrailLumberjack
import SDWebImageSwiftUI

private var clipsDidChangeCancellable: AnyCancellable?
private var callLength: Double = 12 * 60
private var renders = 0

struct MainScreen: View {
    @ObservedObject var state: AppState
    @ObservedObject var newSupState: NewSupState
    @State var player: AVAudioPlayer?
    @State private var updatingCurrentRecording = false
    @State private var didRemoveClip = false
    @State private var showInviteLoader = false
    @State private var timerEnding = false
    @State private var timeEnded = false
    @State private var timer: Timer? = nil
    @State private var value: Double = callLength
    @State private var guestAvatars: [String] = []
    @State private var previewGuestUsers: [User] = []

    private func clipsDidChange(_ didRemoveClip: Bool) {
        self.didRemoveClip = didRemoveClip
    }

    private func onCallEnd(isCaller: Bool = true) {
        DDLogVerbose("call ended")
        DispatchQueue.main.async {
            if isCaller {
                self.resetTimer()
            } else {
                self.state.isConnect = false
                self.guestResetTimer()
            }
        }
    }

    private func guestHangUp() {
        DDLogVerbose("guest is hanging up")
        self.state.hideEndButton = true
        if let callUUID = AppDelegate.callUUID {
            AppDelegate.callManager.end(call: callUUID)
        }
        self.state.isConnect = false
        self.guestResetTimer()
        AppPublishers.callStatusUpdated$.send("guest_hang_up")
    }

    private func callerHangUp() {
        DDLogVerbose("ending call")
        self.state.hideMain = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.state.isConnect = false
            if AppDelegate.callSessionId != nil {
                AppListeners.happyHour?.remove()
                FirebaseCall.update(sessionId: AppDelegate.callSessionId!, data: ["status": "end"])
                FirebaseCall.get(sessionId: AppDelegate.callSessionId!) { call in
                    if let call = call {
                        call.guestUsers { guestUsers in
                            self.previewGuestUsers = guestUsers
                            var guestAvatars: [String] = []
                            for guest in guestUsers {
                                if let avatarUrl = guest.avatarUrl?.replacingOccurrences(of: "_636x636.png?", with: "_210x210.png?") {
                                    guestAvatars.append(avatarUrl)
                                }
                            }
                            self.guestAvatars = guestAvatars
                            self.state.showPublish = true
                        }
                    }
                }
                AppPublishers.callStatusUpdated$.send("end")
            }
        }
    }

    private func callTimerStarted() {
        if let _ = timer { self.resetTimer() }
        DDLogVerbose("call timer started")

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.value -= 1.0

            if !self.timerEnding && self.value <= 1*60 {
                self.timerEnding = true
            } else if self.value <= 0 {
                self.timeEnded = true
                //self.endCall()
                self.animateEndRecording()
                DispatchQueue.main.async {
                    self.resetTimer()
                    self.stopArchive()
                }
            }
        }
    }

    func animateEndRecording() {
        impact(style: .soft)
        self.state.animateIsRecording = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.state.animateAudioSaved = true
        }
    }

    private func resetTimer() {
        DDLogVerbose("resetting timer")
        self.timer?.invalidate()
        self.timer = nil
        self.value = callLength
    }

    private func guestCallTimerStarted(secondsSinceStart: Double) {
        if timer != nil { return }
        DDLogVerbose("guest call timer started")

        self.value = callLength - secondsSinceStart
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.value -= 1.0

            if !self.timerEnding && self.value <= 1*60 {
                self.timerEnding = true
                self.state.animateIsRecording = true
            } else if self.value <= 0 {
                self.timeEnded = true
                self.animateEndRecording()
                // self.guestEndCall()
            }
        }
    }

    private func guestResetTimer() {
        DDLogVerbose("guest call timer reset")
        self.timerEnding = false
        self.timer?.invalidate()
        self.timer = nil
        self.value = callLength
    }

    private func saveCallStartTime() {
        if !AppDelegate.isCaller { return }
        DDLogVerbose("saving call start time")

        SupAPI.time() { response in
            switch response {
            case .success(let response):
                let dataToMerge = ["startTime": response.time]
                if let sessionId = AppDelegate.callSessionId {
                    FirebaseCall.update(
                        sessionId: sessionId,
                        data: dataToMerge
                    )
                }
            case .failure(let error):
                Logger.log("SupAPI.time failure: %{public}@", log: .debug, type: .debug, error.localizedDescription)
            }
        }
    }

    private func startRecording() {
        DDLogVerbose("start recording")
        if AppDelegate.callSessionId != nil {
            FirebaseCall.update(sessionId: AppDelegate.callSessionId!, data: ["status": "recording-started"])
            self.callTimerStarted()
            DispatchQueue.global(qos: .background).async {
                self.saveCallStartTime()
            }
        }
    }

    private func stopArchive() {
        DDLogVerbose("stop archiving")
        if AppDelegate.callSessionId != nil {
            FirebaseCall.update(sessionId: AppDelegate.callSessionId!, data: ["status": "recording-stopped"])
            if let callArchiveId = self.state.callArchiveId {
                DDLogVerbose("callArchiveId=\(callArchiveId)")
                SupAPI.stopArchive(archiveId: callArchiveId) { response in
                    switch response {
                    case .success(_):
                        let baseURL = "https://sup-archives.s3.us-east-2.amazonaws.com/46602742"
                        let url = "\(baseURL)/\(callArchiveId)/archive.mp4"
                        if AppDelegate.isCaller {
                            self.state.audioRecorder.checkFileExists(withLink: url, includeLastPath: true) { audioUrl in
                                self.state.audioRecorder.removeLastClipWithoutIntro()
                                self.state.audioRecorder.createCallClip(
                                    filename: audioUrl,
                                    image: self.state.selectedUser?.avatarUrl,
                                    userId: self.state.currentUser?.uid ?? ""
                                )
                            }
                        } else {
                            DDLogError("stop archiving is not caller")
                        }
                    case .failure(let error):
                        // TODO: do something with UI
                        Logger.log("SupAPI.stopArchive failure: %{public}@", log: .debug, type: .error, error.localizedDescription)
                        DDLogError("SupAPI.stopArchive failure: error=\(error.localizedDescription)")
                    }
                }
            }
        } else {
            DDLogError("stop archiving error: callSessionId is nil")
        }
    }
    
    private func getGuest(usernames: [String]) {
        User.all(usernames: usernames) { users in
            self.state.guestUsers = users
        }
    }

    private func getRecentGuests() {
        guard let userID = self.state.currentUser?.uid else { return }
        Guest.get(userID: userID) { guest in
            self.state.guest = guest

            let usernames = guest?.users.map({ $0["username"] ?? "" }) ?? []
            if usernames.isNotEmpty { self.getGuest(usernames: usernames) }
        }
    }

    private func getRecentGuests(guest: Guest) {
        self.state.guest = guest

        let usernames = guest.users.map({ $0["username"] ?? "" })
        if usernames.isNotEmpty { self.getGuest(usernames: usernames) }
    }

    private func updateCoins(guest: Guest) {
        guard var coins = self.state.currentUser?.coins else { return }

        if guest.users.count > self.state.guest?.users.count ?? 0 {
            coins = coins + 30

            if guest.users.count == 5 {
                coins = coins + 1500
            }
        }

        self.state.add(coins: coins) { _ in }
    }

    private func showCallEndedCard() {
        DDLogVerbose("showing call ended card")
        self.state.showCallEnded = true
    }

    private func topicCoverPhoto() -> WebImage? {
        if state.selectedPrompt != nil {
            return WebImage(url: URL(string: state.selectedPrompt!.image))
        }
        return nil
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

    func resetSelectedUsers() {
        var users: [User] = []
        for user in self.state.guestUsers {
            let suser = user
            suser.isSelected = false
            users.append(suser)
        }
        self.state.guestUsers = users
    }

    private var showBottomButtons: Bool {
        self.state.showQuestions && !self.state.isConnecting && !self.state.liveMatching && !self.state.isConnectHappyHour
    }

    var body: some View {
        Logger.log("MainScreen.body", log: .viewCycle, type: .info)
        if debugViewRenders {
            renders += 1
            print("MainScreen#body renders=\(renders)")
        }

        /// Listen to clipsDidChange to be noticed when clips are added or
        /// removed.
        if clipsDidChangeCancellable == nil {
            clipsDidChangeCancellable = state.audioRecorder.clipsDidChange.sink { didRemoveClip in
                self.clipsDidChange(didRemoveClip)
            }
        }

        /// Use didRemoveClip and updatingCurrentRecording as temporary
        /// switches to update the state properly for CurrentRecordingView.
        if didRemoveClip {
            DispatchQueue.main.async {
                self.didRemoveClip = false
            }
        }
        if updatingCurrentRecording {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.updatingCurrentRecording = false
            }
        }

        return ZStack {
            BackgroundColorView(color: colorCache().opacity(0.1))

            ZStack {
                StartCall(state: state)
                EmojiCallView(state: state)
                    .offset(y: state.moveMainUp ? -screenHeight/2 + (isIPhoneX ? 80 : 70) : 0)
                    .animation(Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0).speed(1))
            }

            CallScreen(
                      state: state,
                      showLoader: $showInviteLoader,
                      tapClose: {},
                      onCallEnd: {}
                  )

            if self.state.isConnect {
                CallNavigation(
                    state: state,
                    timeEnding: $timerEnding,
                    timeEnded: $timeEnded,
                    value: $value,
                    callerHangUp: { self.callerHangUp() },
                    callerStartedRecording: { self.startRecording() },
                    stopArchive: { self.stopArchive() }
                )
            }

            if self.showBottomButtons {
                QuestionsScreen(state: state)
            }

            if self.state.hideMain {
                BackgroundColorView(color: Color.backgroundColor)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3))
            }

            if self.state.showPublish {
                PublishScreen(
                    state: state,
                    newSupState: newSupState,
                    guestAvatars: self.guestAvatars,
                    previewGuestUsers: self.previewGuestUsers,
                    imageView: state.coverPhoto,
                    topicCoverPhoto: self.topicCoverPhoto()
                )
                    .opacity(state.hidePublish ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3))
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onReceive(AppPublishers.onCallEnd$) {
            self.onCallEnd(isCaller: true)
        }
        .onReceive(self.state.receiverOnCallEnd$) {
            DDLogVerbose("onReceive - receiverOnCallEnd$")
            self.onCallEnd(isCaller: false)
        }
        .onReceive(self.state.startGuestTimer$) { secondsSinceStart in
            DDLogVerbose("onReceive - startGuestTimer$ secondsSinceStart=\(secondsSinceStart)")
            self.guestCallTimerStarted(secondsSinceStart: secondsSinceStart)
        }
        .onReceive(self.state.startGuestCounter$) {}
        .onReceive(self.state.userDidLoad$.eraseToAnyPublisher(), perform: { _ in
            self.addBitmojiColors()
        })
        .onReceive(AppPublishers.recentGuests$) { guest in
            self.getRecentGuests(guest: guest)
            self.updateCoins(guest: guest)
        }
        .onAppear {
            self.getRecentGuests()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.state.animateNavBar = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    self.state.animateNavDot = true
                    self.state.animateStartButton = true
                }
            }

            Info.listener { info in
                if let version = UIApplication.appVersion {
                    if version != info.version {
                        Logger.log("An update available: %{public}@", log: .debug, type: .debug, info.version)
                    }
                }
            }
            
            self.state.fetchSelfie { selfie in
                self.state.bitmojiSelfie = selfie
            }
        }
    }

    func addBitmojiColors() {
        if let currentUser = self.state.currentUser {
            if isDefault(
                color: currentUser.color,
                pcolor: currentUser.pcolor,
                scolor: currentUser.scolor
                ) {
                DispatchQueue.global(qos: .background).async {
                    if
                        let avatarUrl = currentUser.avatarUrl,
                        let avatarArt = URL(string: avatarUrl),
                        let avatarPhoto = try? Data(contentsOf: avatarArt),
                        let avatar = UIImage(data: avatarPhoto)
                    {
                        avatar.getColors { colors in
                            let color = colors?.background.hexString() ?? "#36383B"
                            let pcolor = colors?.primary.hexString() ?? "#FFFFFF"
                            let scolor = colors?.secondary.hexString() ?? "#FFFFFF"
                            
                            let data = [
                                "color": color,
                                "pcolor": pcolor,
                                "scolor": scolor
                            ]
                            
                            User.update(userID: currentUser.uid, data: data) { _ in
                                let user = currentUser
                                user.color = color
                                user.pcolor = pcolor
                                user.scolor = scolor
                                self.state.currentUser = user
                            }
                        }
                    }
                }
            }
        }
    }
    
    func isDefault(color: String, pcolor: String, scolor: String) -> Bool {
        return color == "#36383B" && pcolor == "#FFFFFF" && scolor == "#FFFFFF"
    }
}
