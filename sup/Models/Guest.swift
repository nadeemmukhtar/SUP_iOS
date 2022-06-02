//
//  Guest.swift
//  sup
//
//  Created by Appcrates_Dev on 6/4/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Firebase
import Foundation

private let db = Firestore.firestore()

struct Guest: Identifiable {
    
    let ref: DocumentReference?
    let id: String
    let userID: String
    var users: [[String:String]]

    static var listener: ListenerRegistration?
    static var guestListener: ListenerRegistration?
    
    static func listener(userID: String, callback: @escaping (Guest) -> Void) {
        guestListener?.remove()
        guestListener = db.collection("recentGuests").whereField("userID", isEqualTo: userID)
            .addSnapshotListener { (querySnapshot, err) in
                if let document = querySnapshot!.documents.first {
                    if let guest = Guest(snapshot: document) {
                        callback(guest)
                    }
                }
        }
    }

    static func get(userID: String, callback: @escaping (Guest?) -> Void) {
        let emptyGuest = Guest(id: UUID().uuidString, userID: userID, users: [])

        db.collection("recentGuests").whereField("userID", isEqualTo: userID)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    if let document = querySnapshot!.documents.first {
                        if let guest = Guest(snapshot: document) {
                            callback(guest)
                        } else {
                            callback(emptyGuest)
                        }
                    } else {
                        callback(emptyGuest)
                    }
                }
            }
    }
    
    static func all(userID: String, callback: @escaping (Guest?) -> Void) {
        db.collection("recentGuests").whereField("userID", isEqualTo: userID)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    if let document = querySnapshot!.documents.first {
                        if let guest = Guest(snapshot: document) {
                            callback(guest)
                        }
                    }
                    callback(nil)
                }
            }
    }
    
    static func create(
        userID: String,
        users: [[String:String]],
        callback: @escaping (Guest) -> Void
    ) {
        var data:[String: Any] = [
            "userID": userID,
            "users": users
        ]
        
        db.collection("recentGuests").whereField("userID", isEqualTo: userID)
        .getDocuments() { (querySnapshot, err) in
            if let err = err {
                Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                if let document = querySnapshot!.documents.first {
                    if let guest = Guest(snapshot: document) {
                        let userIds = users.map { $0["userID"] }
                        let filteredUsers = guest.users.filter { user in
                            return !userIds.contains(user["userID"])
                        }
                        data["users"] = users + filteredUsers
                        
                        self.update(document: document,
                                    data: data,
                                    userID: userID,
                                    users: users,
                                    callback: callback)
                    }
                } else {
                    self.add(data: data,
                             userID: userID,
                             users: users,
                             callback: callback)
                }
            }
        }
    }
    
    static func delete(
        userID: String,
        users: [[String:String]],
        callback: @escaping (Guest) -> Void
    ) {
        var data:[String: Any] = [
            "userID": userID,
            "users": users
        ]
        
        db.collection("recentGuests").whereField("userID", isEqualTo: userID)
        .getDocuments() { (querySnapshot, err) in
            if let err = err {
                Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                if let document = querySnapshot!.documents.first {
                    if let guest = Guest(snapshot: document) {
                        if let user = users.first {
                            var users = guest.users
                            users.removeAll(where: { $0["userID"] == user["userID"] })
                            
                            data["users"] = users
                            
                            self.update(document: document,
                                        data: data,
                                        userID: userID,
                                        users: users,
                                        callback: callback)
                        }
                    }
                }
            }
        }
    }

    static func listen(userID: String) {
        listener?.remove()
        AppListeners.recentGuests?.remove()

        listener = db.collection("recentGuests").whereField("userID", isEqualTo: userID)
            .addSnapshotListener { querySnapshot, err in
                if err != nil { return }
                guard let documents = querySnapshot?.documents else { return }
                if documents.count == 0 { return }

                let document = documents[0]
                Logger.log("Guest.listen: %{private}@", log: .debug, type: .debug, document)
                if let guest = Guest(snapshot: document) {
                    DispatchQueue.main.async {
                        AppPublishers.recentGuests$.send(guest)
                    }
                }
            }

       AppListeners.recentGuests = listener
    }

    private static func update(
        document: QueryDocumentSnapshot,
        data: [String: Any],
        userID: String,
        users: [[String:String]],
        callback: @escaping (Guest) -> Void
    ) {
        let id = UUID()
        
        document.reference.updateData(data) { err in
            if let err = err {
                Logger.log("Error updating document: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                let guest = Guest(
                    id: id.uuidString,
                    userID: userID,
                    users: data["users"] as! [[String : String]]
                )
                callback(guest)
            }
        }
    }
    
    private static func add(
        data: [String: Any],
        userID: String,
        users: [[String:String]],
        callback: @escaping (Guest) -> Void
    ) {
        let id = UUID()
        
        db.collection("recentGuests").document(id.uuidString).setData(data) { err in
            if let err = err {
                Logger.log("Error writing document: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                let guest = Guest(
                    id: id.uuidString,
                    userID: userID,
                    users: users
                )
                callback(guest)
            }
        }
    }

    init(
        id: String,
        userID: String,
        users: [[String:String]]
    ) {
        self.ref = nil
        self.id = id
        self.userID = userID
        self.users = users
    }

    init?(snapshot: QueryDocumentSnapshot) {
        let value = snapshot.data()
        guard
            let userID = value["userID"] as? String,
            let users = value["users"] as? [[String:String]]
            else {
                return nil
            }

        self.ref = nil
        self.id = snapshot.documentID
        self.userID = userID
        self.users = users
    }
}
