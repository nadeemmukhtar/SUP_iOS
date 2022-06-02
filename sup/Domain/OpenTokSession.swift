//
//  OpenTokSession.swift
//  sup
//
//  Created by Robert Malko on 4/2/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation

enum OpenTokEvent: CustomStringConvertible {
    case subscriberDidConnect
    case streamDestroyed
    case streamCreated
    case sessionDidDisconnect
    case sessionDidConnect
    case archiveStarted(String)

    var description: String {
        get {
            switch self {
            case .subscriberDidConnect:
                return "subscriberDidConnect"
            case .streamDestroyed:
                return "streamDestroyed"
            case .streamCreated:
                return "streamCreated"
            case .sessionDidDisconnect:
                return "sessionDidDisconnect"
            case .sessionDidConnect:
                return "sessionDidConnect"
            case .archiveStarted(_):
                return "archiveStarted"
            }
        }
    }
}

struct OpenTokSession {
    let sessionId: String
    let token: String
}
