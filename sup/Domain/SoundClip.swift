//
//  SoundClip.swift
//  sup
//
//  Created by Robert Malko on 1/28/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation

struct SoundClip: Identifiable {
    let id = UUID()
    let type: SoundClipType
    let fileURL: URL?
    let image: String?
    var duration: Float
    var recording: Bool?

    enum SoundClipType {
        case intro
        case recording
        case call
        case stock
        case library
        case backgroundMusic
        case soundEffect
    }
}

extension SoundClip: Equatable {
    static func == (lhs: SoundClip, rhs: SoundClip) -> Bool {
        return lhs.fileURL == rhs.fileURL
    }
}
