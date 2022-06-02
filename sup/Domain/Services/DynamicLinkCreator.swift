//
//  DynamicLinkCreator.swift
//  sup
//
//  Created by Robert Malko on 6/19/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation
import Firebase

class DynamicLinkCreator {
    let uuid: String
    let user: User

    init(uuid: String, user: User) {
        self.uuid = uuid
        self.user = user
    }

    func call(callback: @escaping (String?) -> Void) {
        let link = URL(string: "https://listen.onsup.fyi/be-my-guest/\(uuid)")!
        guard let shareLink = DynamicLinkComponents(
            link: link,
            domainURIPrefix: "https://onsup.page.link"
        ) else {
            print("error getting share link")
            return callback(nil)
        }

        if let bundleID = Bundle.main.bundleIdentifier {
            shareLink.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleID)
            shareLink.iOSParameters?.appStoreID = "1502204715"
            shareLink.iOSParameters?.customScheme = "sup"
        }

//        guard let username = user.username else {
//            return callback(nil)
//        }
//        guard let avatarUrl = user.avatarUrl else {
//            return callback(nil)
//        }
        guard let inviteBannerImageUrl = user.inviteBannerImageUrl else {
            return callback(nil)
        }

        shareLink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        shareLink.socialMetaTagParameters?.title = "Tap OPEN to accept my guest pass"
        shareLink.socialMetaTagParameters?.descriptionText = "Once you're added to my guest list we can record sups."
        if let imageURL = URL(string: inviteBannerImageUrl) {
            shareLink.socialMetaTagParameters?.imageURL = imageURL
        }

        shareLink.shorten { (url, warnings, error) in
            if let error = error {
                print("Error shortening url", error)
                return callback(nil)
            }

            if let warnings = warnings {
                for warning in warnings {
                    print("Shortened url warning:", warning)
                }
            }

            guard let url = url else {
                return callback(nil)
            }

            if AppDelegate.inviteLinkUUID != nil {
                User.fromInviteLinkUUID(AppDelegate.inviteLinkUUID!, currentUserId: AppDelegate.currentUserId)
            }

            return callback(url.absoluteString)
        }
    }
}
