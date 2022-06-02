//
//  AppPublishers.swift
//  sup
//
//  Created by Robert Malko on 6/20/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Combine
import Foundation

struct AppPublishers {
    static let backgroundStatusChanged$ = PassthroughSubject<Bool, Never>()
    static let callStatusUpdated$ = PassthroughSubject<String, Never>()
    static let guestUser$ = PassthroughSubject<Void, Never>()
    static let happyHourHostStart$ = PassthroughSubject<(String, String), Never>()
    static let hostUser$ = PassthroughSubject<User?, Never>()
    static let micMute$ = PassthroughSubject<Bool, Never>()
    static let onCallEnd$ = PassthroughSubject<Void, Never>()
    static let publisherAudioLevelUpdated$ = PassthroughSubject<Float, Never>()
    static let publishFlowDone$ = PassthroughSubject<Void, Never>()
    static let recentGuests$ = PassthroughSubject<Guest, Never>()
    static let subscriberAudioLevelUpdated$ = PassthroughSubject<Float, Never>()
}
