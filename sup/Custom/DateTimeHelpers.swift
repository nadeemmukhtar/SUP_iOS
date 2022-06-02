//
//  DateTimeHelpers.swift
//  sup
//
//  Created by Robert Malko on 2/22/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation

private let basicDateFormatter = DateFormatter()
private let dateFormatter = DateComponentsFormatter()

struct DateTimeHelpers {
    static func date(from: Date) -> String {
        basicDateFormatter.dateFormat = "MMMM dd"
        
        return basicDateFormatter.string(from: from)
    }

    static func playbackTime(time: Double) -> String {
        dateFormatter.allowedUnits = [.minute, .second]
        dateFormatter.unitsStyle = .positional
        dateFormatter.zeroFormattingBehavior = .pad

        return dateFormatter.string(from: TimeInterval(time.rounded()))!
    }
}
