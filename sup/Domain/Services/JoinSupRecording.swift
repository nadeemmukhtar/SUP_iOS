//
//  JoinSupRecording.swift
//  sup
//
//  Created by Robert Malko on 6/22/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation
import PaperTrailLumberjack

class JoinSupRecording {
    let callToken: String?
    let fromCallKit: Bool
    let sessionId: String
    var user: User?

    private var timerStarted: Bool = false

    init(sessionId: String, user: User?, callToken: String? = nil, fromCallKit: Bool = true) {
        self.callToken = callToken
        self.fromCallKit = fromCallKit
        self.sessionId = sessionId
        self.user = user
    }

    func call() -> Bool {
        if fromCallKit {
            joinFromCallkit()
            return true
        } else {
            return joinCall()
        }
    }

    private func joinFromCallkit() {
        DDLogVerbose("joinFromCallkit sessionId=\(sessionId)")

        if user?.username?.isEmpty != false {
            DDLogError("Can not join call: username=\(user?.username ?? "") sessionId=\(sessionId)")
            return
        }

        AppDelegate.isCaller = false
        timerStarted = false
        Logger.log("joinFromCallkit: %{public}@", log: .debug, type: .debug, sessionId)
        DDLogVerbose("join-call sessionId=\(sessionId)")

        FirebaseCall.get(sessionId: sessionId) { call in
            if let call = call, let hostUserName = call.username {
                if call.status == "canceled" || call.status == "end" {
                    return self.callHasEnded()
                } else {
                    User.get(username: hostUserName) { user in
                        AppPublishers.hostUser$.send(user)
                        DispatchQueue.main.async {
                            AppDelegate.appState?.happyHourLogo = false
                            AppDelegate.appState?.liveMatching = false
                            AppDelegate.appState!.isConnecting = true
                        }
                        self.listenToCall(call: call)
                        self.connectToCall(call: call)
                    }
                }
            }
        }
    }

    private func joinCall() -> Bool {
        if user?.username?.isEmpty != false {
            DDLogError("Can not join call: username=\(user?.username ?? "") sessionId=\(sessionId)")
            return false
        }

        AppDelegate.isCaller = false
        timerStarted = false
        Logger.log("joinCall: %{public}@", log: .debug, type: .debug, sessionId)
        DDLogVerbose("join-call sessionId=\(sessionId)")

        FirebaseCall.get(sessionId: sessionId) { call in
            if let call = call {
                let guests = call.guests ?? []
                let guest = self.user?.username ?? "unknown"

                DDLogVerbose("join-call guests=\(guests) guest=\(guest)")

                if self.alreadyGuested(call: call) {
                    AppDelegate.appState!.callNotAllowed$.send()
                    return
                }

                if guests.count >= 2 {
                    AppDelegate.appState!.callNotAllowed$.send()
                    return
                }

                if call.status == "canceled" || call.status == "end" {
                    return self.callHasEnded()
                }
                if call.status == "answer" || call.status == "recording-started" || call.status == "recording-stopped" {
                    return self.addAdditionalGuestCall(call: call)
                }
                if call.status == nil {
                    return self.startGuestCall(call: call)
                }
            }
        }

        return true
    }

    public func callHasEnded() {
        AppListeners.happyHour?.remove()
        if let callUUID = AppDelegate.callUUID {
            AppDelegate.callManager.end(call: callUUID)
        }
        if AppDelegate.appState != nil {
            DDLogVerbose("join-call callHasEnded sessionId=\(sessionId)")
            AppDelegate.appState!.callNotActive$.send()
        }
    }

    private func addAdditionalGuestCall(call: FirebaseCall) {
        if AppDelegate.isCaller { return }

        DDLogVerbose("join-call addAdditionalGuestCall sessionId=\(sessionId)")
        AppDelegate.callSessionId = sessionId
        self.listenToCall(call: call)
        self.connectToCall(call: call)
    }

    private func startGuestCall(call: FirebaseCall) {
        if AppDelegate.isCaller { return }

        DDLogVerbose("join-call startGuestCall sessionId=\(sessionId)")
        AppDelegate.callSessionId = sessionId
        self.listenToCall(call: call)
        self.connectToCall(call: call)
    }

    private func startGuestTimer(startTime: Double) {
        if AppDelegate.isCaller || self.timerStarted { return }

        if startTime > 0 {
            SupAPI.time() { response in
                switch response {
                case .success(let response):
                    var diff = (response.time - startTime) / 1000
                    if diff <= 0 {
                        diff = 0
                    }
                    DispatchQueue.main.async {
                        DDLogVerbose("join-call startGuestTimer sessionId=\(self.sessionId) diff=\(diff)")
                        self.timerStarted = true
                        AppDelegate.appState!.startGuestTimer$.send(diff)
                    }
                case .failure(let error):
                    Logger.log("SupAPI.time failure: %{public}@", log: .debug, type: .debug, error.localizedDescription)
                }
            }
        }
    }

    func listenToCall(call: FirebaseCall) {
        AppDelegate.callListener?.remove()
        AppDelegate.callListener = FirebaseCall.listenToCall(sessionId: sessionId) { (callStatus, startTime) in
            if AppDelegate.callSessionId != self.sessionId { return }
            Logger.log("call status changed: %{public}@", log: .debug, type: .info, callStatus)

            if AppDelegate.appState != nil {
                AppPublishers.callStatusUpdated$.send(callStatus)
                DDLogVerbose("join-call listenToCall sessionId=\(self.sessionId) callStatus=\(callStatus) timerStarted=\(self.timerStarted) startTime=\(startTime)")
                if callStatus == "recording-started" {
                    if !self.timerStarted {
                        self.startGuestTimer(startTime: startTime)
                    }
                }
                if callStatus == "canceled" || callStatus == "end" {
                    self.timerStarted = false
                    AppListeners.happyHour?.remove()
                    DispatchQueue.main.async {
                        AppDelegate.appState!.isCalling = false
                        AppDelegate.appState!.receiverOnCallEnd$.send()
                        if let callUUID = AppDelegate.callUUID {
                            AppDelegate.callManager.end(call: callUUID)
                        }
                        AppDelegate.callManager.removeAllCalls()
                    }
                }
            }
        }
    }

    private func connectToCall(call: FirebaseCall) {
        if AppDelegate.appState != nil {
            DDLogVerbose("join-call connectToCall call.guests=\(call.guests ?? [])")
            DDLogVerbose("join-call connectToCall sessionId=\(sessionId)")

            AppDelegate.appState!.callBaseURL = FirebaseCall.callJoinURL(sessionId: AppDelegate.callSessionId!)
            AppDelegate.appState?.animateToCall()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.checkPermissions() {
                    if let callToken = self.callToken {
                        self.updateCall(token: callToken, call: call)
                    } else {
                        self.generateToken() { callToken in
                            if let callToken = callToken {
                                self.updateCall(token: callToken, call: call)
                            } else {
                                // TODO: Error state here?
                            }
                        }
                    }
                }
            }
        }
    }

    private func checkPermissions(callback: @escaping () -> Void) {
        AppDelegate.appState!.micPermissions { allowed in
            if allowed {
                callback()
            } else {
                DispatchQueue.main.async {
                    self.promptForAnswer()
                }
            }
        }
    }

    private func generateToken(callback: @escaping (String?) -> Void) {
        SupAPI.generateToken(sessionId: AppDelegate.callSessionId!) { response in
            switch response {
            case .success(let response):
                callback(response.token)
            case .failure(let error):
                // TODO: do something with UI
                Logger.log("SupAPI.generateToken failure: %{public}@", log: .debug, type: .error, error.localizedDescription)
                callback(nil)
            }
        }
    }

    private func updateCall(token: String, call: FirebaseCall) {
        var dataToMerge: [String : String] = [:]
        if call.status == nil {
            dataToMerge["status"] = "answer"
        }
        if let guest = self.user?.username {
            dataToMerge["guest"] = guest
        }
        FirebaseCall.update(
            sessionId: self.sessionId,
            data: dataToMerge
        )
        DispatchQueue.main.async {
            AppDelegate.appState!.callInitiated$.send(SupAPI.Call(
                sessionId: self.sessionId,
                token: token,
                answered: true
            ))
            AppDelegate.appState!.hostname = call.username

            DispatchQueue.global(qos: .background).async {
                /// Host Avatar
                User.get(username: call.username ?? "") { user in
                    if let user = user {
                        DispatchQueue.main.async {
                            AppDelegate.appState?.hostAvatar = user.avatarUrl ?? ""
                        }
                    }
                }

                /// Guest Avatars
                call.guestUsers { users in
                    var guestAvatars: [String] = [AppDelegate.appState?.currentUser?.avatarUrl ?? ""]
                    for user in users {
                        guestAvatars.append(user.avatarUrl ?? "")
                    }
                    DispatchQueue.main.async {
                        AppDelegate.appState?.guestAvatars = guestAvatars
                    }
                }
            }
        }
    }

    private func promptForAnswer() {
        let ac = UIAlertController(title: "Alert", message: "In order to start or join a call we need access to your microphone and camera. Please allow permissions in your iPhone settings and try again", preferredStyle: .alert)

        let openAction = UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let bundleId = Bundle.main.bundleIdentifier,
                let url = URL(string: "\(UIApplication.openSettingsURLString)&path=LOCATION/\(bundleId)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        ac.addAction(openAction)
        ac.addAction(cancelAction)

        let rootvc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        if let vc = rootvc {
            vc.present(ac, animated: true)
        }
    }

    private func alreadyGuested(call: FirebaseCall) -> Bool {
        let guests = call.guests ?? []
        if let guest = user?.username {
            return guests.contains(guest)
        }

        return false
    }
}
