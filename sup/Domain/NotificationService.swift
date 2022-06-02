//
//  NotificationService.swift
//  sup
//
//  Created by Robert Malko on 3/31/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation
import UIKit

struct NotificationService {
    static func createNotification(pushKitToken: String, extraData: [String: Any]) {
        let data: [String : Any?] = [
            "app_id": oneSignalVOIPAppId,
            "include_ios_tokens": [pushKitToken],
            "contents": ["en": "English Message"],
            "apns_push_type_override": "voip",
            "data": extraData
        ]

        // POST request
        do {
            let url = URL(string: "https://onesignal.com/api/v1/notifications")!
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // check for fundamental networking error
                guard let data = data, error == nil else {
                    Logger.log("createNotification network error: %{public}@", log: .debug, type: .error, error!.localizedDescription)
                    return
                }

                let responseString = String(data: data, encoding: .utf8)
                Logger.log("createNotification: %{private}@", log: .debug, type: .debug, responseString ?? "notification created")
            }
            task.resume()
        } catch let error {
            Logger.log("NotificationService.createNotification error: %{public}@", log: .debug, type: .error, error.localizedDescription)
        }
    }

    static func sendPushKitTokenToOneSignal(token: String) {
        // https://documentation.onesignal.com/docs/voip-notifications
        let timezone = TimeZone.current.secondsFromGMT()
        let versionNumber = Bundle.main.infoDictionary!["CFBundleShortVersionString"]
        let osVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.modelName

        let data = [
            "app_id": oneSignalVOIPAppId,
            "identifier": token,
            "language": "en",
            "timezone": timezone,
            "game_version": versionNumber,
            "device_os": osVersion,
            "device_type": 0,
            "device_model": deviceModel
        ]

        // POST request
        do {
            let url = URL(string: "https://onesignal.com/api/v1/players")!
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // check for fundamental networking error
                guard let data = data, error == nil else {
                    Logger.log("sendPushKitTokenToOneSignal network error: %{public}@", log: .debug, type: .error, error!.localizedDescription)
                    return
                }

                let responseString = String(data: data, encoding: .utf8)
                Logger.log("sendPushKitTokenToOneSignal: %{private}@", log: .debug, type: .debug, responseString ?? "things went ok when sending OneSignal our voip token")
            }
            task.resume()
        } catch let error {
            Logger.log("NotificationService.sendPushKitTokenToOneSignal error: %{public}@", log: .debug, type: .error, error.localizedDescription)
        }
    }
}
