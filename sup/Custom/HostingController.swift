//
//  HostingController.swift
//  sup
//
//  Created by Justin Spraggins on 12/16/19.
//  Copyright © 2019 Episode 8, Inc. All rights reserved.
//

import UIKit
import SwiftUI
import Firebase
import MediaPlayer
import PaperTrailLumberjack

class HostingController: UIHostingController<NavigationScreen> {

    private var state: AppState {
        return rootView.state
    }

    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?

    override func viewWillAppear(_ animated: Bool) {
        DDLogVerbose("viewWillAppear")
        super.viewWillAppear(animated)
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener({ (auth, oUser) in
            if auth.currentUser == nil {
                self.state.isOnboarding = true
                Logger.setupPapertrail(userId: nil)
            } else {
                if let user = auth.currentUser {
                    AppListeners.call(userID: user.uid)
                    User.get(userID: user.uid) { currentUser in
                        AppDelegate.currentUserId = user.uid
                        if currentUser == nil {
                            Logger.setupPapertrail(userId: user.uid)
                            DDLogVerbose("User logged in")
                            let uuid = UUID().uuidString
                            let _user = User(
                                uid: user.uid,
                                displayName: user.displayName,
                                email: user.email,
                                oneSignalPlayerId: AppDelegate.oneSignalPlayerId,
                                dynamicLinkUUID: uuid
                            )

                            var data = [String: Any]()
                            data["lastLoginAt"] = Date()

                            if AppDelegate.oneSignalPlayerId != nil {
                                if _user.oneSignalPlayerId != AppDelegate.oneSignalPlayerId! {
                                    _user.oneSignalPlayerId = AppDelegate.oneSignalPlayerId!
                                    data["oneSignalPlayerId"] = AppDelegate.oneSignalPlayerId!
                                }
                            }
                            if let pushKitToken = AppDelegate.pushKitToken {
                                if _user.pushKitToken != pushKitToken {
                                    _user.pushKitToken = pushKitToken
                                    data["pushKitToken"] = pushKitToken
                                }
                            }

                            self.state.uploadInviteImage() {
                                User.update(userID: _user.uid, data: data)
                                DispatchQueue.main.async {
                                    self.state.currentUser = _user
                                    self.state.userDidLoad$.send()
                                }
                            }
                        } else {
                            Logger.setupPapertrail(userId: user.uid, username: currentUser?.username)
                            DDLogVerbose("User logged in")

                            var data = [String: Any]()
                            data["lastLoginAt"] = Date()

                            if AppDelegate.oneSignalPlayerId != nil {
                                if currentUser?.oneSignalPlayerId != AppDelegate.oneSignalPlayerId! {
                                    currentUser?.oneSignalPlayerId = AppDelegate.oneSignalPlayerId!
                                    data["oneSignalPlayerId"] = AppDelegate.oneSignalPlayerId!
                                }
                            }
                            if let pushKitToken = AppDelegate.pushKitToken {
                                if currentUser?.pushKitToken != pushKitToken {
                                    currentUser?.pushKitToken = pushKitToken
                                    data["pushKitToken"] = pushKitToken
                                }
                            }

                            if currentUser?.needsLinkGeneration() ?? false {
                                self.state.uploadInviteImage(data: data) {
                                    User.update(userID: user.uid, data: data)
                                    DispatchQueue.main.async {
                                        self.state.currentUser = currentUser
                                        self.state.userDidLoad$.send()
                                    }
                                }
                            } else {
                                User.update(userID: user.uid, data: data)
                                DispatchQueue.main.async {
                                    self.state.currentUser = currentUser
                                    self.state.userDidLoad$.send()
                                }
                            }

                            self.state.authSetMissingUsername(user: currentUser)
                        }
                    }
                }
            }
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(authStateDidChangeListenerHandle!)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

//    override var prefersStatusBarHidden: Bool {
//        return false
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.setupNowPlaying()
    }
    
    func commandCenterSetup() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()

        setupNowPlaying()

        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.state.audioPlayer.audioPlayer?.pause()
            return .success
        }

        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.state.audioPlayer.audioPlayer?.play()
            return .success
        }
    }

    func setupNowPlaying() {
        // Define Now Playing Info
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

        let title = "TV NAME"
        let album = "TV DESCRIPTION"
        let image = UIImage(named: "ICON") ?? UIImage()
        let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {  (_) -> UIImage in
            return image
        })

        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 1.0)
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
}
