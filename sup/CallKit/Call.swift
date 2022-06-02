//
//  Call.swift
//  sup
//
//  Created by Robert Malko on 6/21/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation

enum CallState {
    case connecting
    case active
    case held
    case ended
}

enum ConnectedState {
    case pending
    case complete
}

class Call {
    let uuid: UUID
    let outgoing: Bool
    let handle: String

    var state: CallState = .ended {
        didSet {
            stateChanged?()
        }
    }

    var connectedState: ConnectedState = .pending {
        didSet {
            connectedStateChanged?()
        }
    }

    var stateChanged: (() -> Void)?
    var connectedStateChanged: (() -> Void)?

    init(uuid: UUID, outgoing: Bool = false, handle: String) {
        self.uuid = uuid
        self.outgoing = outgoing
        self.handle = handle
    }

    func answer() {
        state = .active
    }

    func end() {
        state = .ended
    }
}
