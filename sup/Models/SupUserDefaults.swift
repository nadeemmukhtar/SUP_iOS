//
//  SupUserDefaults.swift
//  sup
//
//  Created by Robert Malko on 2/23/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation

private let defaults = UserDefaults.standard

struct SupUserDefaults {
    struct DefaultsKeys {
        static let audioIntro = "_audioIntro"
        static let avatarPhoto = "_avatarPhoto"
        static let bitmojiPhoto = "_bitmojiPhoto"
        static let coverPhoto = "_coverPhoto"
        static let coverPhotoHash = "_coverPhotoHash"
        static let featureAllowed = "_featureAllowed"
    }

    static func coverPhoto() -> Data? {
        defaults.data(forKey: DefaultsKeys.coverPhoto)
    }

    static func coverPhotoHash() -> String? {
        defaults.string(forKey: DefaultsKeys.coverPhotoHash)
    }

    static func saveCoverPhoto(photoData: Data?) {
        if let photoData = photoData {
            defaults.set(photoData.toHash(), forKey: DefaultsKeys.coverPhotoHash)
        }
        defaults.set(photoData, forKey: DefaultsKeys.coverPhoto)
    }

    static func saveCoverPhotoHash(photoData: Data) {
        defaults.set(photoData.toHash(), forKey: DefaultsKeys.coverPhotoHash)
    }

    static func avatarPhoto() -> Data? {
        defaults.data(forKey: DefaultsKeys.avatarPhoto)
    }

    static func saveAvatarPhoto(photoData: Data?) {
        defaults.set(photoData, forKey: DefaultsKeys.avatarPhoto)
    }

    static func bitmojiPhoto() -> Data? {
        defaults.data(forKey: DefaultsKeys.bitmojiPhoto)
    }

    static func saveBitmojiPhoto(photoData: Data?) {
        defaults.set(photoData, forKey: DefaultsKeys.bitmojiPhoto)
    }

    static func featureAllowed(userID: String) -> Bool {
        let key = userID + DefaultsKeys.featureAllowed
        if defaults.object(forKey: key) == nil {
            return true
        }

        return defaults.bool(forKey: key)
    }

    static func saveFeature(userID: String, allowed: Bool) {
        defaults.set(allowed, forKey: userID + DefaultsKeys.featureAllowed)
    }
    
    static func audioIntro(userID: String) -> URL? {
        defaults.url(forKey: userID + DefaultsKeys.audioIntro)
    }

    static func saveAudioIntro(userID: String, file: URL?) {
        defaults.set(file, forKey: userID + DefaultsKeys.audioIntro)
    }

    static let timesNotificationShownKey: String = "times notification shown"
    static var timesNotificationShown: Int {
        get {
            return defaults.integer(forKey: timesNotificationShownKey)
        }
        set(newValue) {
            defaults.set(newValue, forKey: timesNotificationShownKey)
        }
    }

    static let timesRateShownKey: String = "times rate shown"
    static var timesRateShown: Int {
        get {
            return defaults.integer(forKey: timesRateShownKey)
        }
        set(newValue) {
            defaults.set(newValue, forKey: timesRateShownKey)
        }
    }

    static let timesQuestionHintShownKey: String = "times question hint shown"
    static var timesQuestionHintShown: Int {
        get {
            return defaults.integer(forKey: timesQuestionHintShownKey)
        }
        set(newValue) {
            defaults.set(newValue, forKey: timesQuestionHintShownKey)
        }
    }

    static let timesSharePassShownKey: String = "times share Pass shown"
    static var timesSharePassHintShown: Int {
        get {
            return defaults.integer(forKey: timesSharePassShownKey)
        }
        set(newValue) {
            defaults.set(newValue, forKey: timesSharePassShownKey)
        }
    }

    static let timesStartHintShownKey: String = "times start hint shown"
    static var timesStartHintShown: Int {
        get {
            return defaults.integer(forKey: timesStartHintShownKey)
        }
        set(newValue) {
            defaults.set(newValue, forKey: timesStartHintShownKey)
        }
    }

    static let timesQuestionAlertShownKey: String = "times question tutorial shown"
    static var timesQuestionAlertShown: Int {
        get {
            return defaults.integer(forKey: timesQuestionAlertShownKey)
        }
        set(newValue) {
            defaults.set(newValue, forKey: timesQuestionAlertShownKey)
        }
    }

    static let timesNewQuestionShownKey: String = "times new question dot shown"
    static var timesNewQuestionShown: Int {
        get {
            return defaults.integer(forKey: timesNewQuestionShownKey)
        }
        set(newValue) {
            defaults.set(newValue, forKey: timesNewQuestionShownKey)
        }
    }
    
    static let lastAccessDateKey: String = "login to sup every day"
    static var lastAccessDate: Date? {
        get {
            return defaults.object(forKey: lastAccessDateKey) as? Date
        }
        set {
            guard let newValue = newValue else { return }
            guard let lastAccessDate = lastAccessDate else {
                defaults.set(newValue, forKey: lastAccessDateKey)
                return
            }
            if !Calendar.current.isDateInToday(lastAccessDate) {
                defaults.removeObject(forKey: lastAccessDateKey)
            }
            defaults.set(newValue, forKey: lastAccessDateKey)
        }
    }
}


