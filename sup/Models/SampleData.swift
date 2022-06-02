//
//  SampleData.swift
//  sup
//
//  Created by Justin Spraggins on 1/6/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

protocol ProfileCardable {
    var image: String { get }
    var largeImage: String { get }
    var name: String { get }
    var username: String { get }
    var subscribers: String { get }
    var subscribed: Bool { get }
}

struct SoundClips: Identifiable {
    var id = UUID()
    var image: String
    var title: String
    var duration: String
    var audio: URL
}

let SoundClipsData = [
    SoundClips(image: "", title: "", duration: "", audio: Bundle.main.url(forResource: "intro", withExtension: "m4a")!)
]
