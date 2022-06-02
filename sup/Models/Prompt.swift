//
//  Prompt.swift
//  sup
//
//  Created by Robert Malko on 2/13/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation
import Firebase

private let db = Firestore.firestore()

struct Prompt: Identifiable {
    let ref: DocumentReference?
    let category: String
    let count: String
    let image: String
    let text: String
    let color: String
    let pcolor: String
    let id: String

    static func all(callback: @escaping ([Prompt]) -> Void) {
        db.collection("prompts").getDocuments() { (querySnapshot, err) in
            var prompts = [Prompt]()
            if let err = err {
                Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                for document in querySnapshot!.documents {
                    if let prompt = Prompt(snapshot: document) {
                        prompts.append(prompt)
                    }
                }
            }
            callback(prompts)
        }
    }

    init?(snapshot: QueryDocumentSnapshot) {
        let value = snapshot.data()
        let category = value["category"] as? String ?? ""
        let count = value["count"] as? String ?? ""
        let image = value["image"] as? String ?? ""
        let text = value["text"] as? String ?? ""
        let color = value["color"] as? String ?? ""
        let pcolor = value["pcolor"] as? String ?? ""

        if image.isEmpty && text.isEmpty {
            return nil
        }

        self.ref = nil
        self.id = snapshot.documentID
        self.category = category
        self.count = count
        self.image = image
        self.text = text
        self.color = color
        self.pcolor = pcolor
    }

    func toAnyObject() -> Any {
        return [
            "category": category,
            "count": count,
            "image": image,
            "text": text,
            "color": color,
            "pcolor": pcolor
        ]
    }
}
