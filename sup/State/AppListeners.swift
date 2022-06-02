//
//  AppListeners.swift
//  sup
//
//  Created by Robert Malko on 6/20/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Firebase
import Foundation

class AppListeners {
    static var happyHour: ListenerRegistration?
    static var recentGuests: ListenerRegistration?

    static func call(userID: String) {
        Guest.listen(userID: userID)
        if AppDelegate.needsToStartHappyHourListener {
            HappyHour.create(userID: userID)
            if AppDelegate.appState != nil {
                // TODO: set any state vars here for happy hour
                AppDelegate.appState?.liveMatching = true
                AppDelegate.appState?.happyHourLogo = true
                AppDelegate.appState?.isConnectHappyHour = true
                AppDelegate.appState?.animateToCall()
            }
            HappyHour.addToQueue(userID: userID)
            AppDelegate.needsToStartHappyHourListener = false
        }
    }
}
