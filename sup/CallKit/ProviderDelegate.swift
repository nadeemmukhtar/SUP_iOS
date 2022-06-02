//
//  ProviderDelegate.swift
//  sup
//
//  Created by Robert Malko on 6/21/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import AVFoundation
import CallKit
import PaperTrailLumberjack
import UIKit

class ProviderDelegate: NSObject {
    private let callManager: CallManager
    private var isHappyHour: Bool = false
    private let provider: CXProvider

    init(callManager: CallManager) {
        self.callManager = callManager
        provider = CXProvider(configuration: ProviderDelegate.providerConfiguration)

        super.init()

        provider.setDelegate(self, queue: nil)
    }

    static var providerConfiguration: CXProviderConfiguration = {
        let providerConfiguration = CXProviderConfiguration(localizedName: "sup")

        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]

        if let callkitIcon = UIImage(named: "callkit-icon") {
            providerConfiguration.iconTemplateImageData = callkitIcon.pngData()
        }

        return providerConfiguration
    }()

    func reportIncomingCall(
        uuid: UUID,
        handle: String,
        isHappyHour: Bool = false,
        completion: ((Error?) -> Void)?
    ) {
        AppDelegate.callUUID = uuid
        self.isHappyHour = isHappyHour
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.hasVideo = false

        // TODO: Hang up after 30 seconds

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.voiceChat, options: [.mixWithOthers, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                let call = Call(uuid: uuid, handle: handle)
                self.callManager.add(call: call)
            }

            completion?(error)
        }
    }
}

// MARK: - CXProviderDelegate
extension ProviderDelegate: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        Logger.log("ProviderDelegate providerDidReset", log: .debug, type: .debug)
        stopAudio()

        for call in callManager.calls {
            call.end()
        }

        callManager.removeAllCalls()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        Logger.log("ProviderDelegate provider:perform CXAnswerCallAction", log: .debug, type: .debug)

        let user = AppDelegate.appState?.currentUser

        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }

        if isHappyHour {
            if let userID = AppDelegate.currentUserId {
                HappyHour.create(userID: userID)

                if AppDelegate.appState != nil {
                    // TODO: set any state vars here for happy hour
                    AppDelegate.appState?.liveMatching = true
                    AppDelegate.appState?.happyHourLogo = true
                    AppDelegate.appState?.isConnectHappyHour = true
                    AppDelegate.appState?.animateToCall()
                }

                HappyHour.addToQueue(userID: user?.uid)
            } else {
                AppDelegate.needsToStartHappyHourListener = true
            }

            configureAudioSession()
            call.answer()
            action.fulfill()
        } else {
            DDLogVerbose("CallKit CXAnswerCallAction callSessionId=\(AppDelegate.callSessionId) callToken=\(AppDelegate.callToken) user=\(user)")
            if AppDelegate.isCaller {
                return
            }

            AppDelegate.isCaller = false

            if AppDelegate.appState != nil && AppDelegate.callSessionId != nil && AppDelegate.callToken != nil {
                let _ = JoinSupRecording(sessionId: AppDelegate.callSessionId!, user: user, callToken: AppDelegate.callToken!).call()
            } else {
                Logger.log("CXAnswerCallAction error: Can't get state off AppDelegate", log: .debug, type: .error)
            }

            configureAudioSession()
            call.answer()
            action.fulfill()
        }
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        Logger.log("ProviderDelegate provider:didActivate", log: .debug, type: .debug)
        startAudio()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        Logger.log("ProviderDelegate provider:perform CXEndCallAction", log: .debug, type: .debug)
        DDLogVerbose("CallKit CXEndCallAction call=\(callManager.callWithUUID(uuid: action.callUUID))")
        let call = callManager.callWithUUID(uuid: action.callUUID)

        if let call = call {
            call.end()
        }
        stopAudio()
        action.fulfill()

        if AppDelegate.callSessionId != nil && AppDelegate.isCaller {
            FirebaseCall.update(sessionId: AppDelegate.callSessionId!, data: ["status": "end"])
        } else {
            Logger.log("CXEndCallAction error: Can't find callSessionId", log: .debug, type: .error)
        }
        AppDelegate.callSessionId = nil
        AppDelegate.callToken = nil
        callManager.removeAllCalls()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        Logger.log("ProviderDelegate provider:perform CXSetHeldCallAction", log: .debug, type: .debug)
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }

        call.state = action.isOnHold ? .held : .active

        if call.state == .held {
            stopAudio()
        } else {
            startAudio()
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        Logger.log("ProviderDelegate provider:perform CXStartCallAction", log: .debug, type: .debug)
        DDLogVerbose("CallKit CXStartCallAction callSessionId=\(AppDelegate.callSessionId) callToken=\(AppDelegate.callToken)")
        AppDelegate.isCaller = true
        let call = Call(uuid: action.callUUID, outgoing: true, handle: action.handle.value)

        configureAudioSession()

        call.connectedStateChanged = { [weak self, weak call] in
            guard
                let self = self,
                let call = call
                else {
                    return
            }

            if call.connectedState == .pending {
                self.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
            } else if call.connectedState == .complete {
                self.provider.reportOutgoingCall(with: call.uuid, connectedAt: nil)
            }
        }

        call.connectedState = .pending
        action.fulfill()
        self.callManager.add(call: call)
    }
}
