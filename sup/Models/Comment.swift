//
//  Comment.swift
//  sup
//
//  Created by Appcrates_Dev on 5/28/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Firebase
import Foundation

private let db = Firestore.firestore()

struct Comment: Identifiable {
    
    let ref: DocumentReference?
    let id: String
    let userID: String
    let username: String
    let avatarUrl: URL
    let supTitle: String
    let supUsername: String
    let audioFile: URL
    let type: String
    let expireAt: Date
    
    static var commentListener: ListenerRegistration?
    
    static func listener(supUsername: String, callback: @escaping (Comment) -> Void) {
        commentListener?.remove()
        commentListener = db.collection("comments").whereField("supUsername", isEqualTo: supUsername).addSnapshotListener { (querySnapshot, err) in
                if let document = querySnapshot!.documents.first {
                    if let comment = Comment(snapshot: document) {
                        callback(comment)
                    }
                }
        }
    }
    
    static func all(supUsername: String, callback: @escaping ([Comment]) -> Void) {
        db.collection("comments").whereField("supUsername", isEqualTo: supUsername)
        .whereField("expireAt", isGreaterThanOrEqualTo: Date())
            .getDocuments() { (querySnapshot, err) in
                var comments = [Comment]()
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let comment = Comment(snapshot: document) {
                            comments.append(comment)
                        }
                        
                    }
                }
                callback(comments)
            }
    }
    
    static func allAdded(username: String, callback: @escaping ([Comment]) -> Void) {
        db.collection("comments").whereField("username", isEqualTo: username)
            .getDocuments() { (querySnapshot, err) in
                var comments = [Comment]()
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let comment = Comment(snapshot: document) {
                            comments.append(comment)
                        }
                        
                    }
                }
                callback(comments)
            }
    }
    
    static func create(
        userID: String,
        username: String,
        avatarUrl: URL,
        supTitle: String,
        supUsername: String,
        audioFile: URL,
        type: String,
        expireAt: Date,
        callback: @escaping (Comment) -> Void
    ) {
        let id = UUID()
        db.collection("comments").document(id.uuidString).setData([
            "userID": userID,
            "username": username,
            "avatarUrl": avatarUrl.absoluteString,
            "supTitle": supTitle,
            "supUsername": supUsername,
            "audioFile": audioFile.absoluteString,
            "type": type,
            "expireAt": expireAt
        ]) { err in
            if let err = err {
                Logger.log("Error writing document: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                let comment = Comment(
                    id: id.uuidString,
                    userID: userID,
                    username: username,
                    avatarUrl: avatarUrl,
                    supTitle: supTitle,
                    supUsername: supUsername,
                    audioFile: audioFile,
                    type: type,
                    expireAt: expireAt
                )
                callback(comment)
            }
        }
    }

    init(
        id: String,
        userID: String,
        username: String,
        avatarUrl: URL,
        supTitle: String,
        supUsername: String,
        audioFile: URL,
        type: String,
        expireAt: Date
    ) {
        self.ref = nil
        self.id = id
        self.userID = userID
        self.username = username
        self.avatarUrl = avatarUrl
        self.supTitle = supTitle
        self.supUsername = supUsername
        self.audioFile = audioFile
        self.type = type
        self.expireAt = expireAt
    }

    init?(snapshot: QueryDocumentSnapshot) {
        let value = snapshot.data()
        guard
            let userID = value["userID"] as? String,
            let username = value["username"] as? String,
            let avatarUrl = value["avatarUrl"] as? String,
            let supTitle = value["supTitle"] as? String,
            let supUsername = value["supUsername"] as? String,
            let audioFile = value["audioFile"] as? String,
            let type = value["type"] as? String,
            let expireAt = value["expireAt"] as? Timestamp
            else {
                return nil
            }

        self.ref = nil
        self.id = snapshot.documentID
        self.userID = userID
        self.username = username
        self.avatarUrl = URL(string: avatarUrl)!
        self.supTitle = supTitle
        self.supUsername = supUsername
        self.audioFile = URL(string: audioFile)!
        self.type = type
        self.expireAt = expireAt.dateValue()
    }
}
