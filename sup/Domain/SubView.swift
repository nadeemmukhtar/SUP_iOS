//
//  SubView.swift
//  sup
//
//  Created by Robert Malko on 5/17/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import UIKit

struct SubView: Hashable {
    let id: String
    var isLoading: Bool

    init(
        id: String,
        isLoading: Bool
    ) {
        self.id = id
        self.isLoading = isLoading
    }

    static func == (lhs:SubView, rhs:SubView) -> Bool {
        return lhs.id == rhs.id && lhs.isLoading == rhs.isLoading
    }
}
