//
//  SceneDelegate.swift
//  sup
//
//  Created by Justin Spraggins on 12/16/19.
//  Copyright © 2019 Episode 8, Inc. All rights reserved.
//

import Branch
import Combine
import Firebase
import OpenTok
import PaperTrailLumberjack
import SCSDKLoginKit
import SwiftUI
import TikTokOpenSDK
import UIKit

extension AppDelegate {
    static var appState: AppState?
    static var newSupState : NewSupState?
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    /// Private state
    private var appState: AppState = AppState()
    private var newSupState: NewSupState = NewSupState()
    private var _onCallInitiated: AnyCancellable?
    private var _callStatusUpdated: AnyCancellable?
    private var _onMicMute: AnyCancellable?
    private var session: OTSession?
    private var publisher: OTPublisher?
    private var subscriber: OTSubscriber?
    private var openTokSession: SupAPI.Call?
    private var streamId: String?

    /// API key
    private var kApiKey = "46602742"

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Initialize AppState
        AppDelegate.appState = appState

        // setup listeners
        self._onCallInitiated = appState.callInitiated$.sink(receiveValue: { openTokSession in
            self.connectToAnOpenTokSession(openTokSession: openTokSession)
        })

        self._callStatusUpdated = AppPublishers.callStatusUpdated$.sink(receiveValue: { status in
            AppDelegate.callStatus = status
            if status == "end" || status == "canceled" || status == "guest_hang_up" {
                AppListeners.happyHour?.remove()
                self.disconnectAnOpenTokSession()
            }
        })

        self._onMicMute = AppPublishers.micMute$.sink(receiveValue: { isMute in
            let publishAudio = !isMute
            DDLogVerbose("micMute$ isMute=\(isMute) publishAudio=\(publishAudio)")
            self.publisher?.publishAudio = publishAudio
        })

        // Create the SwiftUI view that provides the window contents.
        let contentView = NavigationScreen(state: appState, newSupState: newSupState)

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = HostingController(rootView: contentView)
            appState.rootController = window.rootViewController
            self.window = window
            window.makeKeyAndVisible()
        }

        Logger.log(
            "willConnectTo handleURLContext urlContexts=%{public}@",
            log: .debug,
            type: .info,
            connectionOptions.urlContexts
        )

        // if app is not running, this scene method gets called, check urlContext
        // see https://apple.co/2VhcAij
        DDLogVerbose("handleURLContext urlContexts=\(connectionOptions.urlContexts)")
        handleURLContext(urlContext: connectionOptions.urlContexts.first)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // BranchScene.shared().scene(scene, continue: userActivity)

        if let incomingURL = userActivity.webpageURL {
            DynamicLinks.dynamicLinks().handleUniversalLink(incomingURL) { (dynamicLink, error) in
                guard error == nil else {
                    print("Error with incoming url: \(error!)")
                    return
                }

                if let dynamicLink = dynamicLink {
                    guard let url = dynamicLink.url else {
                        return
                    }
                    guard let currentUser = AppDelegate.appState?.currentUser, currentUser.username != nil, !currentUser.username!.isEmpty else {
                        let index = AppDelegate.dynamicLinks.firstIndex { dl -> Bool in
                            dl.url == url
                        }
                        if index == nil {
                            AppDelegate.dynamicLinks.append(dynamicLink)
                        }
                        return
                    }

                    User.fromDynamicLink(dynamicLink, currentUserId: AppDelegate.currentUserId)
                }
            }
        }
    }

    // when your app opens a URL while running or suspended in memory
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        Logger.log(
            "openURLContexts handleURLContext urlContexts=%{public}@",
            log: .debug,
            type: .info,
            URLContexts
        )

        // BranchScene.shared().scene(scene, openURLContexts: URLContexts)
        DDLogVerbose("handleURLContext urlContexts=\(URLContexts)")
        handleURLContext(urlContext: URLContexts.first)
    }

    private func connectToAnOpenTokSession(openTokSession: SupAPI.Call) {
        Logger.log("connectToAnOpenTokSession", log: .debug, type: .debug)
        DDLogVerbose("connectToAnOpenTokSession sessionId=\(openTokSession.sessionId)")
        self.openTokSession = openTokSession
        session = OTSession(apiKey: kApiKey, sessionId: openTokSession.sessionId, delegate: self)
        var error: OTError?
        session?.connect(withToken: openTokSession.token, error: &error)
        if error != nil {
            DDLogError("OpenTok - connectToAnOpenTokSession - error\(error!.localizedDescription)")
            Logger.log("OpenTok - connectToAnOpenTokSession error: %{public}@", log: .debug, type: .error, error!.localizedDescription)
        }
    }

    private func disconnectAnOpenTokSession() {
        if self.openTokSession == nil { return }

        Logger.log("disconnectAnOpenTokSession", log: .debug, type: .debug)
        DDLogVerbose("disconnectAnOpenTokSession session=\(session)")
        var error: OTError?
        session?.disconnect(&error)
        self.openTokSession = nil
        if !AppDelegate.isCaller {
            AppDelegate.callListener?.remove()
        }
        if error != nil {
            DDLogError("OpenTok - disconnectAnOpenTokSession - error=\(error!.localizedDescription)")
            Logger.log("OpenTok - disconnectAnOpenTokSession error: %{public}@", log: .debug, type: .error, error!.localizedDescription)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.

        AppPublishers.backgroundStatusChanged$.send(true)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).

        AppPublishers.backgroundStatusChanged$.send(false)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    private func handleURLContext(urlContext: UIOpenURLContext?) {
        guard let urlContext = urlContext else { return }

        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: urlContext.url) {
            guard let url = dynamicLink.url else {
                return
            }
            guard let currentUser = AppDelegate.appState?.currentUser, currentUser.username != nil, !currentUser.username!.isEmpty else {
                let index = AppDelegate.dynamicLinks.firstIndex { dl -> Bool in
                    dl.url == url
                }
                if index == nil {
                    AppDelegate.dynamicLinks.append(dynamicLink)
                }
                return
            }

            User.fromDynamicLink(dynamicLink, currentUserId: AppDelegate.currentUserId)
            return
        }

        if SCSDKLoginClient.application(
            UIApplication.shared,
            open: urlContext.url,
            options: nil
        ) {
          return
        }

        if TikTokOpenSDKApplicationDelegate.sharedInstance().application(
            UIApplication.shared,
            open: urlContext.url,
            sourceApplication: urlContext.options.sourceApplication as? String,
            annotation: urlContext.options.annotation as Any
        ) {
            return
        }
    }
}

// MARK: - OTSessionDelegate callbacks
extension SceneDelegate: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        Logger.log("OpenTok - sessionDidConnect", log: .debug, type: .debug)
        DDLogVerbose("OpenTok - sessionDidConnect session=\(session.sessionId) status=\(session.sessionConnectionStatus)")

        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        settings.videoTrack = false
        guard let publisher = OTPublisher(delegate: self, settings: settings) else {
            DDLogError("OpenTok - sessionDidConnect - error: No publisher")
            return
        }

        // video content mode
        publisher.audioLevelDelegate = self
        self.publisher = publisher
        
        var error: OTError?
        session.publish(self.publisher!, error: &error)
        guard error == nil else {
            DDLogError("OpenTok - sessionDidConnect - error=\(error!.localizedDescription)")
            Logger.log("OpenTok - sessionDidConnect error: %{public}@", log: .debug, type: .error, error!.localizedDescription)
            return
        }

        let id = appState.currentUser?.uid ?? UUID().uuidString
        appState.openTokSession$.send(.sessionDidConnect)
    }

    func sessionDidDisconnect(_ session: OTSession) {
        Logger.log("OpenTok - sessionDidDisconnect", log: .debug, type: .debug)
        DDLogError("OpenTok - sessionDidDisconnect session=\(session.sessionId) status=\(session.sessionConnectionStatus)")
        AppDelegate.callSessionId = nil
        AppDelegate.callToken = nil
        appState.openTokSession$.send(.sessionDidDisconnect)
    }

    func session(_ session: OTSession, didFailWithError error: OTError) {
        DDLogError("OpenTok - session:didFailWithError - error=\(error.localizedDescription)")
        Logger.log("OpenTok - session:didFailWithError: %{public}@", log: .debug, type: .error, error.localizedDescription)
    }

    func session(_ session: OTSession, streamCreated stream: OTStream) {
        Logger.log("OpenTok - session:streamCreated:", log: .debug, type: .debug)
        DDLogVerbose("OpenTok - session:streamCreated: session=\(session.sessionId) status=\(session.sessionConnectionStatus) stream=\(stream)")

        subscriber = OTSubscriber(stream: stream, delegate: self)

        guard let subscriber = subscriber else {
            DDLogError("OpenTok - session:streamCreated - error: No subscriber")
            Logger.log("OpenTok - session:streamCreated: no subscriber", log: .debug, type: .error)
            return
        }

        subscriber.audioLevelDelegate = self
        // subscriber.videoRender = CustomVideoRenderer()

        if let streamId = subscriber.stream?.streamId {
            self.streamId = streamId
        }

        var error: OTError?
        session.subscribe(subscriber, error: &error)
        guard error == nil else {
            DDLogError("OpenTok - session:streamCreated - error=\(error!.localizedDescription)")
            Logger.log("OpenTok - session:streamCreated: error: %{public}@", log: .debug, type: .error, error!.localizedDescription)
            return
        }

        appState.openTokSession$.send(.streamCreated)
    }

    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        Logger.log("OpenTok - session:streamDestroyed:", log: .debug, type: .debug)
        DDLogVerbose("OpenTok - session:streamDestroyed:")
        self.streamId = nil
        appState.openTokSession$.send(.streamDestroyed)
    }
}

// MARK: - OTPublisherDelegate callbacks
extension SceneDelegate: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        DDLogError("OpenTok - publisher:didFailWithError - error=\(error.localizedDescription)")
        Logger.log("OpenTok - publisher:didFailWithError: %{public}@", log: .debug, type: .error, error.localizedDescription)
    }
}

extension SceneDelegate: OTPublisherKitDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        DDLogVerbose("OpenTok - publisher:streamCreated:")
        Logger.log("OpenTok - publisher:streamCreated:", log: .debug, type: .debug)
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        DDLogVerbose("OpenTok - publisher:streamDestroyed:")
        Logger.log("OpenTok - publisher:streamDestroyed:", log: .debug, type: .debug)
    }
}

extension SceneDelegate: OTPublisherKitAudioLevelDelegate {
    func publisher(_ publisher: OTPublisherKit, audioLevelUpdated audioLevel: Float) {
        AppPublishers.publisherAudioLevelUpdated$.send(audioLevel)
    }
}

extension SceneDelegate: OTSubscriberKitAudioLevelDelegate {
    func subscriber(_ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float) {
        AppPublishers.subscriberAudioLevelUpdated$.send(audioLevel)
    }
}

// MARK: - OTSubscriberDelegate callbacks
extension SceneDelegate: OTSubscriberDelegate {
    public func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        Logger.log("OpenTok - subscriberDidConnect", log: .debug, type: .debug)
        DDLogVerbose("OpenTok - subscriberDidConnect subscriber=\(subscriber)")
        appState.openTokSession$.send(.subscriberDidConnect)
    }

    public func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        DDLogError("OpenTok - subscriber:didFailWithError - error=\(error.localizedDescription)")
        Logger.log("The subscriber failed to connect to the stream.", log: .debug, type: .error)
    }
}
