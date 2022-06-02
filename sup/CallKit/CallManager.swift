//
//  CallManager.swift
//  sup
//
//  Created by Robert Malko on 6/21/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import CallKit
import Foundation
import PaperTrailLumberjack

class CallManager {
    var callsChangedHandler: (() -> Void)?
    private let callController = CXCallController()

    private(set) var calls: [Call] = []

    func callWithUUID(uuid: UUID) -> Call? {
        guard let index = calls.firstIndex(where: { $0.uuid == uuid }) else {
            return nil
        }
        return calls[index]
    }

    func add(call: Call) {
        calls.append(call)
        call.stateChanged = { [weak self] in
            guard let self = self else { return }
            self.callsChangedHandler?()
        }
        callsChangedHandler?()
    }

    func remove(call: Call) {
        guard let index = calls.firstIndex(where: { $0 === call }) else { return }
        calls.remove(at: index)
        callsChangedHandler?()
    }

    func removeAllCalls() {
        calls.removeAll()
        callsChangedHandler?()
        AppDelegate.callUUID = nil
    }

    func end(call: UUID) {
        DDLogVerbose("CallKit end call=\(call)")
        let endCallAction = CXEndCallAction(call: call)
        let transaction = CXTransaction(action: endCallAction)

        requestTransaction(transaction)
    }

    private func requestTransaction(_ transaction: CXTransaction) {
        callController.request(transaction) { error in
            if let error = error {
                Logger.log("Error requesting transaction: %{public}@", log: .debug, type: .error, error.localizedDescription)
            }
        }
    }

    func setHeld(call: Call, onHold: Bool) {
        let setHeldCallAction = CXSetHeldCallAction(call: call.uuid, onHold: onHold)

        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)

        requestTransaction(transaction)
    }

    func startCall(handle: String, videoEnabled: Bool) -> UUID {
        let handle = CXHandle(type: .generic, value: handle)
        let uuid = UUID()

        let startCallAction = CXStartCallAction(call: uuid, handle: handle)
        startCallAction.isVideo = videoEnabled

        let transaction = CXTransaction(action: startCallAction)

        requestTransaction(transaction)

        return uuid
    }
}
