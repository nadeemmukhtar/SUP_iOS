//
//  Recording.swift
//  sayit
//
//  Created by Robert Malko on 12/19/19.
//  Copyright © 2019 Extra Visual. All rights reserved.
//

import Foundation

struct Recording {
    let fileURL: URL
    let createdAt: Date

    static func creationDate(for file: URL) -> Date {
        if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path) as [FileAttributeKey: Any],
            let creationDate = attributes[FileAttributeKey.creationDate] as? Date
        {
            return creationDate
        } else {
            return Date()
        }
    }
}
