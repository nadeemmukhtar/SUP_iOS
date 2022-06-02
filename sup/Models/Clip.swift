//
//  Clip.swift
//  sup
//
//  Created by Appcrates_Dev on 3/11/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Firebase
import Foundation

private let db = Firestore.firestore()

struct Clip: Identifiable {
    
    let ref: DocumentReference?
    let id: String
    let image: String
    let title: String
    let duration: String
    let audio: String
    
    static func all(callback: @escaping ([Clip]) -> Void) {
        db.collection("clips")
            .getDocuments() { (querySnapshot, err) in
                var clips = [Clip]()
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let clip = Clip(snapshot: document) {
                            clips.append(clip)
                        }
                    }
                }
                callback(clips)
            }
    }

    init(
        id: String,
        image: String,
        title: String,
        duration: String,
        audio: String
    ) {
        self.ref = nil
        self.id = id
        self.image = image
        self.title = title
        self.duration = duration
        self.audio = audio
    }
    
    init?(snapshot: QueryDocumentSnapshot) {
        let value = snapshot.data()
        guard
            let image = value["image"] as? String,
            let title = value["title"] as? String,
            let duration = value["duration"] as? String,
            let audio = value["audio"] as? String
            else {
                return nil
            }

        self.ref = nil
        self.id = snapshot.documentID
        self.image = image
        self.title = title
        self.duration = duration
        self.audio = audio
    }
}
