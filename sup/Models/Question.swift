//
//  Question.swift
//  sup
//
//  Created by Appcrates_Dev on 6/26/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Firebase
import Foundation

private let db = Firestore.firestore()

struct Question: Identifiable {
    
    let ref: DocumentReference?
    let id: String
    let title: String
    let isFeatured: Bool
    
    static var questionListener: ListenerRegistration?
    
    static func listener(callback: @escaping (Question) -> Void) {
        questionListener?.remove()
        questionListener = db.collection("questions").whereField("isFeatured", isEqualTo: true)
            .addSnapshotListener { (querySnapshot, err) in
                if let document = querySnapshot!.documents.first {
                    if let question = Question(snapshot: document) {
                        callback(question)
                    }
                }
        }
    }
    
    static func all(callback: @escaping ([Question]) -> Void) {
        db.collection("questions")
            .whereField("isFeatured", isEqualTo: true)
            .order(by: "order")
            .getDocuments() { (querySnapshot, err) in
                var questions = [Question]()
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let question = Question(snapshot: document) {
                            questions.append(question)
                        }
                    }
                }
                callback(questions)
            }
    }

    init(
        id: String,
        title: String,
        isFeatured: Bool
    ) {
        self.ref = nil
        self.id = id
        self.title = title
        self.isFeatured = isFeatured
    }
    
    init?(snapshot: QueryDocumentSnapshot) {
        let value = snapshot.data()
        guard
            let title = value["title"] as? String,
            let isFeatured = value["isFeatured"] as? Bool
            else {
                return nil
            }

        self.ref = nil
        self.id = snapshot.documentID
        self.title = title
        self.isFeatured = isFeatured
    }
}
