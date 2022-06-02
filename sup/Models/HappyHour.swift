//
//  HappyHour.swift
//  sup
//
//  Created by Robert Malko on 7/24/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Firebase
import FirebaseFunctions
import Foundation

private let db = Firestore.firestore()
private let functions = Functions.functions()
private var previousCallSessionId: String?
private var previousCallToken: String?

struct HappyHour: Identifiable {
    let ref: DocumentReference?
    let id: String
    let callSessionId: String?
    let callToken: String?
    let isHost: Bool

    static var listener: ListenerRegistration?

    static func addToQueue(userID: String?) {
        functions.httpsCallable("addToHappyHourQueue").call(["userID": userID]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let message = error.localizedDescription
                    print("error message=\(message)")
                } else {
                    print("error", error)
                }
            }

            print("addToHappyHourQueue result", result?.data)
        }
    }

    static func create(userID: String) {
        let data: [String: String] = [:]

        db
            .collection("happyHour")
            .document(userID)
            .setData(data, merge: true) { err in
                if let err = err {
                    print("error creating happy hour document", err)
                } else {
                    self.listener(userID: userID) { happyHour in
                        if let happyHour = happyHour {
                            self.connectTo(happyHour: happyHour)
                        }
                    }
                }
            }
    }

    static func listener(
        userID: String,
        callback: @escaping (HappyHour?) -> Void
    ) {
        listener?.remove()
        AppListeners.happyHour?.remove()

        listener = db.collection("happyHour")
            .document(userID)
            .addSnapshotListener { (document, err) in
                if let document = document, document.exists {
                    if let doc = HappyHour(snapshot: document) {
                        if previousCallSessionId != doc.callSessionId &&
                            previousCallToken != doc.callToken &&
                            doc.callSessionId != nil &&
                            doc.callToken != nil {
                            callback(doc)
                        }
                        previousCallSessionId = doc.callSessionId
                        previousCallToken = doc.callToken
                    } else {
                        callback(nil)
                    }
                } else {
                    callback(nil)
                }
        }

        AppListeners.happyHour = listener
    }

    static func removeFromQueue(userID: String?) {
        functions.httpsCallable("removeFromHappyHourQueue").call(["userID": userID]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let message = error.localizedDescription
                    print("error message=\(message)")
                } else {
                    print("error", error)
                }
            }

            print("removeFromHappyHourQueue result", result?.data)
        }
    }

    private static func connectTo(happyHour: HappyHour) {
        print("happy hour document updated", happyHour)
        guard let callSessionId = happyHour.callSessionId else { return }
        guard let callToken = happyHour.callToken else { return }

        if happyHour.isHost {
            AppPublishers.happyHourHostStart$.send((callSessionId, callToken))
            FirebaseCall.get(sessionId: callSessionId) { call in
                guard let guestId = call?.happyHourGuestId else { return }
                User.get(userID: guestId) { user in
                    guard let user = user else { return }
                    DispatchQueue.main.async {
                        AppDelegate.appState?.happyHourLogo = false
                        AppDelegate.appState?.liveMatching = false
                        AppDelegate.appState!.isConnecting = true
                    }
                    AppPublishers.hostUser$.send(user)
                }
            }
            return
        }

        let user = AppDelegate.appState?.currentUser

        AppDelegate.callSessionId = callSessionId
        AppDelegate.callToken = callToken

        let _ = JoinSupRecording(
            sessionId: callSessionId,
            user: user,
            callToken: callToken
        ).call()
    }

    init?(snapshot: DocumentSnapshot) {
        let data = snapshot.data()

        self.ref = nil
        self.id = snapshot.documentID
        self.callSessionId = data?["callSessionId"] as? String
        self.callToken = data?["callToken"] as? String
        self.isHost = (data?["isHost"] as? Bool) ?? false
    }
}
