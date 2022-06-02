//
//  Friend.swift
//  sup
//
//  Created by Appcrates_Dev on 3/19/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Firebase
import Foundation

private let db = Firestore.firestore()

struct Friend: Identifiable {
    
    let ref: DocumentReference?
    let id: String
    let username: String
    let friendnames: [String]
    
    static func get(username: String, callback: @escaping (Friend?) -> Void) {
        let emptyFriend = Friend(id: UUID().uuidString, username: username, friendnames: [])

        db.collection("friends").whereField("username", isEqualTo: username)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    if let document = querySnapshot!.documents.first {
                        if let friend = Friend(snapshot: document) {
                            callback(friend)
                        } else {
                            callback(emptyFriend)
                        }
                    } else {
                        callback(emptyFriend)
                    }
                }
            }
    }
    
    static func create(
        username: String,
        friendnames: [String],
        callback: @escaping (Friend) -> Void
    ) {
        var data:[String: Any] = [
            "username": username,
            "friendnames": friendnames
        ]
        
        db.collection("friends").whereField("username", isEqualTo: username)
        .getDocuments() { (querySnapshot, err) in
            if let err = err {
                Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                if let document = querySnapshot!.documents.first {
                    if let friend = Friend(snapshot: document) {
                        data["friendnames"] = friendnames + friend.friendnames
                        
                        self.update(document: document,
                                    data: data,
                                    username: username,
                                    friendnames: friendnames,
                                    callback: callback)
                    }
                } else {
                    self.add(data: data,
                             username: username,
                             friendnames: friendnames,
                             callback: callback)
                }
            }
        }
    }
    
    static func delete(
        username: String,
        friendnames: [String],
        callback: @escaping (Friend) -> Void
    ) {
        var data:[String: Any] = [
            "username": username,
            "friendnames": friendnames
        ]
        
        db.collection("friends").whereField("username", isEqualTo: username)
        .getDocuments() { (querySnapshot, err) in
            if let err = err {
                Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                if let document = querySnapshot!.documents.first {
                    if let friend = Friend(snapshot: document) {
                        if let friendname = friendnames.first {
                            var friendnames = friend.friendnames
                            friendnames.removeAll(where: { $0 == friendname })
                            
                            data["friendnames"] = friendnames
                            
                            self.update(document: document,
                                        data: data,
                                        username: username,
                                        friendnames: friendnames,
                                        callback: callback)
                        }
                    }
                }
            }
        }
    }
    
    private static func update(
        document: QueryDocumentSnapshot,
        data: [String: Any],
        username: String,
        friendnames: [String],
        callback: @escaping (Friend) -> Void
    ) {
        let id = UUID()
        
        document.reference.updateData(data) { err in
            if let err = err {
                Logger.log("Error updating document: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                let friend = Friend(
                    id: id.uuidString,
                    username: username,
                    friendnames: friendnames
                )
                callback(friend)
            }
        }
    }
    
    private static func add(
        data: [String: Any],
        username: String,
        friendnames: [String],
        callback: @escaping (Friend) -> Void
    ) {
        let id = UUID()
        
        db.collection("friends").document(id.uuidString).setData(data) { err in
            if let err = err {
                Logger.log("Error writing document: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                let friend = Friend(
                    id: id.uuidString,
                    username: username,
                    friendnames: friendnames
                )
                callback(friend)
            }
        }
    }

    init(
        id: String,
        username: String,
        friendnames: [String]
    ) {
        self.ref = nil
        self.id = id
        self.username = username
        self.friendnames = friendnames
    }
    
    init?(snapshot: QueryDocumentSnapshot) {
        let value = snapshot.data()
        guard
            let username = value["username"] as? String,
            let friendnames = value["friendnames"] as? [String]
            else {
                return nil
            }

        self.ref = nil
        self.id = snapshot.documentID
        self.username = username
        self.friendnames = friendnames
    }
}
