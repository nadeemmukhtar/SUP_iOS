//
//  AppDelegate.swift
//  sup
//
//  Created by Justin Spraggins on 12/16/19.
//  Copyright © 2019 Episode 8, Inc. All rights reserved.
//

import UIKit
import Firebase
import SCSDKLoginKit
import OneSignal
import PushKit
import TikTokOpenSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var providerDelegate: ProviderDelegate!
    let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
    static let callManager = CallManager()
    static var callListener: ListenerRegistration?
    static var callSessionId: String?
    static var callToken: String?
    static var callStatus: String?
    static var currentUserId: String?
    static var dynamicLinks = [DynamicLink]()
    static var isCaller = false
    static var inviteLinkUUID: String?
    static var needsToStartHappyHourListener = false

    // Set this to true to show a temporary menu item on the main screen
    // this is useful for testing code without having to use the device
    // to make a call
    let isDebugging = false

    class var shared: AppDelegate {
      return UIApplication.shared.delegate as! AppDelegate
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Logger.setupPapertrail(userId: nil)
        FirebaseApp.configure()
        voipRegistration()
        oneSignalIntegration(launchOptions: launchOptions)
        self.providerDelegate = ProviderDelegate(callManager: AppDelegate.callManager)

        TikTokOpenSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        return true
    }

    // MARK: Call Kit
    func displayIncomingCall(
        uuid: UUID,
        handle: String,
        isHappyHour: Bool = false,
        completion: ((Error?) -> Void)?
    ) {
        providerDelegate.reportIncomingCall(
            uuid: uuid,
            handle: handle,
            isHappyHour: isHappyHour,
            completion: completion
        )
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate: OSSubscriptionObserver {
    static var oneSignalPlayerId: String?

    func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges!) {
        if !stateChanges.from.subscribed && stateChanges.to.subscribed {
            Logger.log("Subscribed for OneSignal push notifications!", log: .debug, type: .debug)
        }

        // The player id is inside stateChanges. But be careful, this value can be nil if the user has not granted you permission to send notifications.
        if let playerId = stateChanges.to.userId {
            Logger.log("Current OneSignal playerId: %{private}@", log: .debug, type: .debug, playerId)
            AppDelegate.oneSignalPlayerId = playerId
            if let currentUser = AppDelegate.appState?.currentUser {
                if playerId != currentUser.oneSignalPlayerId {
                    User.update(userID: currentUser.uid, data: [
                        "oneSignalPlayerId": playerId
                    ])
                }
            }
        }
    }

    private func oneSignalIntegration(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: oneSignalVOIPAppId,
                                        handleNotificationAction: nil,
                                        settings: onesignalInitSettings)
        OneSignal.add(self as OSSubscriptionObserver)
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
        AppDelegate.oneSignalPlayerId = OneSignal.getPermissionSubscriptionState().subscriptionStatus.userId
    }
}

extension AppDelegate: PKPushRegistryDelegate {
    static var pushKitToken: String?
    static var callUUID: UUID?

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        Logger.log("device token: %{private}@", log: .debug, type: .debug, pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined())
        let deviceToken = pushCredentials.token.hexString
        AppDelegate.pushKitToken = deviceToken
        if let currentUser = AppDelegate.appState?.currentUser {
            if deviceToken != currentUser.pushKitToken {
                User.update(userID: currentUser.uid, data: [
                    "pushKitToken": deviceToken
                ])
            }
        }
        NotificationService.sendPushKitTokenToOneSignal(token: deviceToken)
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        guard type == .voIP else { return }

        if let _ = payload.dictionaryPayload["happyHour"] as? Bool {
            let handle = "sup Happy Hour"
            let uuid = UUID()
            self.displayIncomingCall(
                uuid: uuid,
                handle: handle,
                isHappyHour: true,
                completion: { err in }
            )
        } else {
            guard
                let handle = payload.dictionaryPayload["from"] as? String,
                let sessionId = payload.dictionaryPayload["sessionId"] as? String,
                let token = payload.dictionaryPayload["token"] as? String
                else {
                    AppDelegate.callSessionId = nil
                    AppDelegate.callToken = nil
                    return
            }

            AppDelegate.callSessionId = sessionId
            AppDelegate.callToken = token

            /* TODO: Is this needed?
            FirebaseCall.get(sessionId: sessionId) { call in
                let joinSupRecording = JoinSupRecording(
                    sessionId: sessionId,
                    user: nil,
                    callToken: token
                )

                if let call = call {
                    if call.status == "canceled" || call.status == "end" {
                        joinSupRecording.callHasEnded()
                    } else {
                        joinSupRecording.listenToCall(call: call)
                    }
                }
            }
            */

            Logger.log("pushRegistry:didReceiveIncomingPushWith", log: .debug, type: .debug)
            self.displayIncomingCall(uuid: UUID(), handle: handle, completion: { err in })
        }
    }

    private func voipRegistration() {
        self.pushRegistry.delegate = self
        self.pushRegistry.desiredPushTypes = [.voIP]
    }
}
