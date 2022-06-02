//
//  FirebaseCall.swift
//  sup
//
//  Created by Robert Malko on 4/19/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation
import Firebase

private let db = Firestore.firestore()

class FirebaseCall {
    var guests: [String]?
    var sessionId: String?
    var status: String?
    var username: String?
    var startTime: Double?
    var happyHour: Bool?
    var happyHourGuestId: String?

    init?(snapshot: DocumentSnapshot?) {
        guard let snapshot = snapshot else { return nil }
        guard let value = snapshot.data() else { return nil }

        if let guests = value["guests"] as? [String], guests.count > 0 {
            self.guests = guests
        }
        if let sessionId = value["avatarUrl"] as? String {
            self.sessionId = sessionId
        }
        if let status = value["status"] as? String {
            self.status = status
        }
        if let username = value["username"] as? String {
            self.username = username
        }
        if let startTime = value["startTime"] as? TimeInterval {
            self.startTime = startTime
        }
        if let happyHour = value["happyHour"] as? Bool {
            self.happyHour = happyHour
        }
        if let happyHourGuestId = value["happyHourGuestId"] as? String {
            self.happyHourGuestId = happyHourGuestId
        }
    }

    func guestUsers(callback: @escaping ([User]) -> Void) {
        guard let guests = self.guests else { return callback([]) }

        User.all(usernames: guests) { users in
            callback(users)
        }
    }

    static var callListener: ListenerRegistration?

    static func callJoinURL(sessionId: String) -> String {
        "https://listen.onsup.fyi/calls/\(sessionId)"
    }

    static func get(sessionId: String, callback: @escaping (FirebaseCall?) -> Void) {
        db.collection("calls").whereField("sessionId", isEqualTo: sessionId)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    if let document = querySnapshot!.documents.first {
                        if let call = FirebaseCall(snapshot: document) {
                            callback(call)
                        } else {
                            callback(nil)
                        }
                    } else {
                        callback(nil)
                    }
                }
            }
    }

    static func listenToCall(sessionId: String, onUpdate: ((String, Double) -> Void)? = nil) -> ListenerRegistration? {
        callListener?.remove()
        callListener = db.collection("calls")
            .whereField("sessionId", isEqualTo: sessionId)
            .addSnapshotListener { querySnapshot, err in
                guard let documents = querySnapshot?.documents else { return }
                if documents.count == 0 { return }
                let document = documents[0]
                Logger.log("listenToCall: %{private}@", log: .debug, type: .debug, document)
                let startTime: Double = document["startTime"] as? TimeInterval ?? 0
                let callStatus = document["status"] as? String ?? ""
                AppPublishers.callStatusUpdated$.send(callStatus)
                onUpdate?(callStatus, startTime)
            }

        return callListener
    }

    static func update(sessionId: String, data: [String : Any]) {
        var dataToMerge = data
        db.collection("calls")
            .whereField("sessionId", isEqualTo: sessionId)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.log("Error updating call: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if dataToMerge.keys.contains("guest") {
                            var guests: [String] = document.data()["guests"] as? [String] ?? []
                            let guestId = dataToMerge["guest"] as? String ?? ""
                            dataToMerge.removeValue(forKey: "guest")
                            if !guests.contains(guestId) {
                                guests.append(guestId)
                            }
                            dataToMerge["guests"] = guests
                            document.reference.setData(dataToMerge, merge: true)
                        } else {
                            document.reference.setData(dataToMerge, merge: true)
                        }
                    }
                }
        }
    }
}
