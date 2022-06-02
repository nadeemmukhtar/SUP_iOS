//
//  Info.swift
//  sup
//
//  Created by Appcrates_Dev on 5/1/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Firebase
import Foundation

private let db = Firestore.firestore()

struct Info: Identifiable {
    
    let ref: DocumentReference?
    let id: String
    let version: String
    
    static var infoListener: ListenerRegistration?
    
    static func listener(
        callback: @escaping (Info) -> Void
    ) {
        infoListener?.remove()
        infoListener = db.collection("info")
            .addSnapshotListener { (querySnapshot, err) in
                if let document = querySnapshot!.documents.first {
                    if let info = Info(snapshot: document) {
                        callback(info)
                    }
                }
        }
    }
    
    init(
        id: String,
        version: String
    ) {
        self.ref = nil
        self.id = id
        self.version = version
    }
    
    init?(snapshot: QueryDocumentSnapshot) {
        let value = snapshot.data()
        guard
            let version = value["version"] as? String
            else {
                return nil
            }

        self.ref = nil
        self.id = snapshot.documentID
        self.version = version
    }
}
