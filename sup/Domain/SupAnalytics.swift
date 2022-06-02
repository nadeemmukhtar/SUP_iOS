//
//  SupAnalytics.swift
//  sup
//
//  Created by Robert Malko on 6/9/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation
import FirebaseAnalytics

private let add_friend = "added_friend"
private let seconds_played = "seconds_played"
private let start_podcast = "start_podcast"
private let sup_played = "sup_played"
private let sup_published = "sup_published"

///Sup Shares
private let sup_share_instagram = "sup_share_instagram"
private let sup_share_tiktok = "sup_share_tiktok"
private let sup_share_twitter = "sup_share_twitter"

///Guest Pass Shares
private let alert_okay_guestPass = "alert_okay_guestPass"
private let alert_later_guestPass = "alert_later_guestPass"
private let coins_market_guestPass = "coins_market_guestPass"
private let coins_five_guestPass = "coins_five_guestPass"
private let coins_share_guestPass = "coins_share_guestPass"

struct SupAnalytics {
    static func addFriend() {
        Analytics.logEvent(add_friend, parameters: nil)
    }

    static func playSup(sup: Sup) {
        Analytics.logEvent(sup_played, parameters: [
            "sup": sup.id,
            "userId": sup.userID,
            "username": sup.username
        ])
    }

    static func publishSup() {
        Analytics.logEvent(sup_published, parameters: nil)
    }

    static func secondsPlayed(seconds: Int, sup: Sup?) {
        guard seconds > 0 else { return }

        var params: [String: Any] = [
            "seconds": seconds
        ]

        if let sup = sup {
            params["sup"] = sup.id
            params["userId"] = sup.userID
            params["username"] = sup.username
        }

        Analytics.logEvent(seconds_played, parameters: params)
    }

    static func shareTiktok() {
        Analytics.logEvent(sup_share_tiktok, parameters: nil)
    }

    static func shareTwitter() {
        Analytics.logEvent(sup_share_twitter, parameters: nil)
    }

    static func startPodcast() {
        Analytics.logEvent(start_podcast, parameters: nil)
    }

    static func alertOkayGuestPass() {
           Analytics.logEvent(alert_okay_guestPass, parameters: nil)
       }

    static func alertLaterGuestPass() {
        Analytics.logEvent(alert_later_guestPass, parameters: nil)
    }

    static func coinsMarketGuestPass() {
        Analytics.logEvent(coins_market_guestPass, parameters: nil)
    }

    static func coinsFiveGuestPass() {
        Analytics.logEvent(coins_five_guestPass, parameters: nil)
    }

    static func coinsShareGuestPass() {
        Analytics.logEvent(coins_share_guestPass, parameters: nil)
    }
}
