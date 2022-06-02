//
//  Stack.swift
//  sup
//
//  Created by Robert Malko on 6/15/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Firebase
import Foundation

private let db = Firestore.firestore()

struct Stack: Identifiable {
    let ref: DocumentReference?
    let id: String
    let active: Bool
    let creatorAvatarUrl: String
    let creatorUsername: String
    let items: [String]
    let name: String

    static func all(callback: @escaping ([Stack]) -> Void) {
        db.collection("stacks")
            .whereField("active", isEqualTo: true)
            .getDocuments() { (querySnapshot, err) in
                var stacks = [Stack]()
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let stack = Stack(snapshot: document) {
                            stacks.append(stack)
                        }
                    }
                }
                callback(stacks)
        }
    }

    init?(snapshot: QueryDocumentSnapshot) {
        let value = snapshot.data()
        let active = value["active"] as? Bool ?? false
        let creatorAvatarUrl = value["creatorAvatarUrl"] as? String ?? ""
        let creatorUsername = value["creatorUsername"] as? String ?? ""
        let items = value["items"] as? [String] ?? []
        let name = value["name"] as? String ?? ""

        if creatorAvatarUrl.isEmpty || creatorUsername.isEmpty || name.isEmpty {
            return nil
        }

        self.ref = nil
        self.id = snapshot.documentID
        self.active = active
        self.creatorAvatarUrl = creatorAvatarUrl
        self.creatorUsername = creatorUsername
        self.items = items
        self.name = name
    }

    func toAnyObject() -> Any {
        return [
            "active": active,
            "creatorAvatarUrl": creatorAvatarUrl,
            "creatorUsername": creatorUsername,
            "items": items,
            "name": name,
        ]
    }
}
