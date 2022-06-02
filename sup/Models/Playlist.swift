//
//  Playlist.swift
//  sup
//
//  Created by Appcrates_Dev on 3/9/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Firebase
import Foundation

private let db = Firestore.firestore()

struct Playlist: Identifiable {
    
    let ref: DocumentReference?
    let id: String
    let userID: String
    let sup: Sup
    
    static func all(userID: String, callback: @escaping ([Playlist]) -> Void) {
        db.collection("playlist")
            .whereField("userID", isEqualTo: userID)
            .getDocuments() { (querySnapshot, err) in
                var playlists = [Playlist]()
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let playlist = Playlist(snapshot: document) {
                            playlists.append(playlist)
                        }
                    }
                }
                callback(playlists)
            }
    }
    
    static func get(sup: Sup, callback: @escaping (Bool) -> Void) {
        db.collection("playlist")
            .whereField("userID", isEqualTo: sup.userID)
            .whereField("description", isEqualTo: sup.description)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    if let document = querySnapshot!.documents.first {
                        document.reference.delete { err in
                            if let err = err {
                                Logger.log("Error deleting document: %{public}@", log: .debug, type: .error, err.localizedDescription)
                            } else {
                                callback(true)
                            }
                        }
                    }
                }
            }
    }
    
    static func create(
        userID: String,
        sup: Sup,
        callback: @escaping (Playlist) -> Void
    ) {
        let id = UUID()
        
        let data:[String: Any] = [
            "userID": userID,
            "username": sup.username,
            "description": sup.description,
            "url": sup.url.absoluteString,
            "coverArtUrl": sup.coverArtUrl.absoluteString,
            "avatarUrl": sup.avatarUrl.absoluteString,
            "size": sup.size,
            "duration": sup.duration,
            "channel": sup.channel ?? "",
            "created": sup.created
        ]
        
        db.collection("playlist").document(id.uuidString).setData(data) { err in
            if let err = err {
                Logger.log("Error writing document: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                let playlist = Playlist(
                    id: id.uuidString,
                    userID: userID,
                    sup: sup
                )
                callback(playlist)
            }
        }
    }

    init(
        id: String,
        userID: String,
        sup: Sup
    ) {
        self.ref = nil
        self.id = id
        self.userID = userID
        self.sup = sup
    }
    
    init?(snapshot: QueryDocumentSnapshot) {
        let value = snapshot.data()
        guard
            let userID = value["userID"] as? String,
            let sup = Sup(snapshot: snapshot)
            else {
                return nil
            }

        self.ref = nil
        self.id = snapshot.documentID
        self.userID = userID
        self.sup = sup
    }
}
