//
//  Sup.swift
//  sup
//
//  Created by Robert Malko on 2/14/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation
import Firebase

private let db = Firestore.firestore()
private let storageRef = Storage.storage().reference()
private let bgImageRef = storageRef.child("images/sup_listen_banners")

struct Sup: Identifiable {
    let ref: DocumentReference?
    let id: String
    let userID: String
    let username: String
    let description: String
    let url: URL
    var coverArtUrl: URL
    var avatarUrl: URL
    let size: Int64
    let duration: Double
    let channel: String?
    let color: String
    let pcolor: String
    let scolor: String
    let created: Date
    let guests: [String]
    var guestAvatars: [String]
    var tags: [[String: String]]
    let isPrivate: Bool
    var listenBannerImageUrl: URL?
    
    static var supListener: ListenerRegistration?
    
    static func listener(username: String, callback: @escaping (Sup) -> Void) {
        supListener?.remove()
        supListener = db.collection("sups")
            .whereField("guests", arrayContains: username)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "created", descending: true)
            .addSnapshotListener { (querySnapshot, err) in
                if let document = querySnapshot!.documents.first {
                    if let sup = Sup(snapshot: document) {
                        callback(sup)
                    }
                }
        }
    }

    static func featured(callback: @escaping ([Sup]) -> Void) {
        db.collection("sups")
            .whereField("featured", isEqualTo: true)
            .whereField("canFeature", isEqualTo: true)
            .order(by: "order")
            .getDocuments() { (querySnapshot, err) in
                var sups = [Sup]()
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let sup = Sup(snapshot: document) {
                            sups.append(sup)
                        } else {
                            Logger.log("Error creating Sup from snapshot: %{private}@", log: .debug, type: .error, document)
                        }
                    }
                }
                callback(sups)
            }
    }

    static func latest(callback: @escaping ([Sup]) -> Void) {
        db.collection("sups")
            .whereField("canFeature", isEqualTo: true)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "created", descending: true)
            .limit(to: 25)
            .getDocuments() { (querySnapshot, err) in
                var sups = [Sup]()
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let sup = Sup(snapshot: document) {
                            sups.append(sup)
                        } else {
                            Logger.log("Error creating Sup from snapshot: %{private}@", log: .debug, type: .error, document)
                        }
                    }
                }
                callback(sups)
            }
    }
    
    static func all(userID: String, username: String, callback: @escaping ([Sup]) -> Void) {
        var sups = [Sup]()
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        db.collection("sups")
            .whereField("userID", isEqualTo: userID)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "created", descending: true)
            .limit(to: 25)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let sup = Sup(snapshot: document) {
                            sups.append(sup)
                        }
                    }
                }
                dispatchGroup.leave()
            }

        dispatchGroup.enter()
        db.collection("sups")
            .whereField("guests", arrayContains: username)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "created", descending: true)
            .limit(to: 25)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let sup = Sup(snapshot: document) {
                            sups.append(sup)
                        }
                    }
                }
                dispatchGroup.leave()
            }

        dispatchGroup.notify(queue: DispatchQueue.main) {
            sups = sups.sorted(by: { $0.created > $1.created })
            sups = Array(sups.prefix(25))
            callback(sups)
        }
    }
    
    static func allPublic(userID: String, username: String, callback: @escaping ([Sup]) -> Void) {
        var sups = [Sup]()
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        db.collection("sups")
            .whereField("userID", isEqualTo: userID)
            .whereField("isPrivate", isEqualTo: false)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "created", descending: true)
            .limit(to: 25)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let sup = Sup(snapshot: document) {
                            sups.append(sup)
                        }
                    }
                }
                dispatchGroup.leave()
            }

        dispatchGroup.enter()
        db.collection("sups")
            .whereField("guests", arrayContains: username)
            .whereField("isPrivate", isEqualTo: false)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "created", descending: true)
            .limit(to: 25)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let sup = Sup(snapshot: document) {
                            sups.append(sup)
                        }
                    }
                }
                dispatchGroup.leave()
            }

        dispatchGroup.notify(queue: DispatchQueue.main) {
            sups = sups.sorted(by: { $0.created > $1.created })
            sups = Array(sups.prefix(25))
            callback(sups)
        }
    }
    
    static func all(supIDs: [String], callback: @escaping ([Sup]) -> Void) {
        db.collection("sups")
            .limit(to: 25)
            .getDocuments() { (querySnapshot, err) in
                var sups = [Sup]()
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if supIDs.contains(document.documentID) {
                            if let sup = Sup(snapshot: document) {
                                sups.append(sup)
                            }
                        }
                        
                    }
                }
                callback(sups)
            }
    }
    
    static func all(usernames: [String], callback: @escaping ([Sup]) -> Void) {
        let truncatedUsernames = Array(usernames.prefix(10))
        db.collection("sups")
            .whereField("username", in: truncatedUsernames)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "created", descending: true)
            .limit(to: 25)
            .getDocuments() { (querySnapshot, err) in
                var sups = [Sup]()
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let sup = Sup(snapshot: document) {
                            sups.append(sup)
                        }
                    }
                }
                callback(sups)
            }
    }
    
    static func allPublic(usernames: [String], callback: @escaping ([Sup]) -> Void) {
        var sups = [Sup]()
        var count = 0
        
        for username in usernames {
            db.collection("sups")
            .whereField("username", isEqualTo: username)
            .whereField("isPrivate", isEqualTo: false)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "created", descending: true)
            .limit(to: 1)
            .getDocuments() { (querySnapshot, err) in
                count += 1
                
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let sup = Sup(snapshot: document) {
                            sups.append(sup)
                        }
                    }
                }
                
                if usernames.count == count {
                    callback(sups)
                }
            }
        }
    }
    
//    static func allPublic(usernames: [String], callback: @escaping ([Sup]) -> Void) {
//        let truncatedUsernames = Array(usernames.prefix(10))
//        db.collection("sups")
//            .whereField("username", in: truncatedUsernames)
//            .whereField("isPrivate", isEqualTo: false)
//            .whereField("isDeleted", isEqualTo: false)
//            .order(by: "created", descending: true)
//            .limit(to: 25)
//            .getDocuments() { (querySnapshot, err) in
//                var sups = [Sup]()
//                if let err = err {
//                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
//                } else {
//                    for document in querySnapshot!.documents {
//                        if let sup = Sup(snapshot: document) {
//                            sups.append(sup)
//                        }
//                    }
//                }
//                callback(sups)
//            }
//    }
    
    static func allToUpdateNewField(callback: @escaping () -> Void) {
        db.collection("sups")
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        let value = document.data()
                        if value["isPrivate"] == nil {
                            /// Add default value
                            let data:[String: Any] = [
                                "isPrivate": false
                            ]
                            document.reference.updateData(data)
                        }
                    }
                    callback()
                }
            }
    }
    
    static func update(
        sup: Sup,
        callback: @escaping (Sup) -> Void
    ) {
        let data: [String: Any] = [
            "isDeleted": true
        ]

        db.collection("sups").whereField("url", isEqualTo: sup.url.absoluteString)
        .getDocuments() { (querySnapshot, err) in
            if let err = err {
                Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                if let document = querySnapshot!.documents.first {
                    document.reference.updateData(data) { err in
                        if let err = err {
                            Logger.log("Error updating document: %{public}@", log: .debug, type: .error, err.localizedDescription)
                        } else {
                            callback(sup)
                        }
                    }
                }
            }
        }
    }

    static func removeGuest(
        sup: Sup,
        username: String,
        callback: @escaping (Sup) -> Void
    ) {
        var data:[String: Any] = [:]
        
        db.collection("sups").whereField("url", isEqualTo: sup.url.absoluteString)
        .getDocuments() { (querySnapshot, err) in
            if let err = err {
                Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                if let document = querySnapshot!.documents.first {
                    if let sup = Sup(snapshot: document) {
                        var guests = sup.guests
                        guests.removeAll(where: { $0 == username })
                        
                        data["guests"] = guests
                        
                        document.reference.updateData(data) { err in
                            if let err = err {
                                Logger.log("Error updating document: %{public}@", log: .debug, type: .error, err.localizedDescription)
                            } else {
                                callback(sup)
                            }
                        }
                    }
                }
            }
        }
    }

    static func create(
        userID: String,
        username: String,
        description: String,
        url: URL,
        coverArtUrl: URL,
        avatarUrl: URL,
        size: Int64,
        duration: Double,
        channel: String?,
        color: String,
        pcolor: String,
        scolor: String,
        created: Date,
        canFeature: Bool,
        guests: [String],
        guestAvatars: [String],
        tags: [[String: String]],
        isPrivate: Bool,
        callback: @escaping (Sup) -> Void
    ) {
        let id = UUID()
        db.collection("sups").document(id.uuidString).setData([
            "userID": userID,
            "username": username,
            "description": description,
            "url": url.absoluteString,
            "coverArtUrl": coverArtUrl.absoluteString,
            "avatarUrl": avatarUrl.absoluteString,
            "size": size,
            "duration": duration,
            "channel": channel ?? "",
            "color": color,
            "pcolor": pcolor,
            "scolor": scolor,
            "created": created,
            "canFeature": canFeature,
            "guests": guests,
            "guestAvatars": guestAvatars,
            "tags": tags,
            "isPrivate": isPrivate,
            "isDeleted": false
        ]) { err in
            if let err = err {
                Logger.log("Error writing document: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                let sup = Sup(
                    id: id.uuidString,
                    description: description,
                    userID: userID,
                    username: username,
                    url: url,
                    coverArtUrl: coverArtUrl,
                    avatarUrl: avatarUrl,
                    size: size,
                    duration: duration,
                    channel: channel,
                    color: color,
                    pcolor: pcolor,
                    scolor: scolor,
                    created: created,
                    guests: guests,
                    guestAvatars: guestAvatars,
                    tags: tags,
                    isPrivate: isPrivate
                )
                callback(sup)
            }
        }
    }

    init(
        id: String,
        description: String,
        userID: String,
        username: String,
        url: URL,
        coverArtUrl: URL,
        avatarUrl: URL,
        size: Int64,
        duration: Double,
        channel: String?,
        color: String,
        pcolor: String,
        scolor: String,
        created: Date,
        guests: [String],
        guestAvatars: [String],
        tags: [[String: String]],
        isPrivate: Bool
    ) {
        self.ref = nil
        self.id = id
        self.description = description
        self.userID = userID
        self.username = username
        self.url = url
        self.coverArtUrl = coverArtUrl
        self.avatarUrl = avatarUrl
        self.size = size
        self.duration = duration
        self.channel = channel
        self.color = color
        self.pcolor = pcolor
        self.scolor = scolor
        self.created = created
        self.guests = guests
        self.guestAvatars = guestAvatars
        self.tags = tags
        self.isPrivate = isPrivate
    }

    init?(snapshot: QueryDocumentSnapshot) {
        let value = snapshot.data()
        guard
            let avatarUrl = value["avatarUrl"] as? String,
            let channel = value["channel"] as? String,
            let coverArtUrl = value["coverArtUrl"] as? String,
            let description = value["description"] as? String,
            let duration = value["duration"] as? Double,
            let size = value["size"] as? Int64,
            let url = value["url"] as? String,
            let userID = value["userID"] as? String,
            let username = value["username"] as? String,
            let created = value["created"] as? Timestamp
            else {
                return nil
            }

        self.ref = nil
        self.id = snapshot.documentID
        self.avatarUrl = URL(string: avatarUrl)!
        self.channel = channel
        self.coverArtUrl = URL(string: coverArtUrl)!
        self.description = description
        self.duration = duration
        self.size = size
        self.url = URL(string: url)!
        self.userID = userID
        self.username = username
        self.created = created.dateValue()
        self.guests = value["guests"] as? [String] ?? []
        self.guestAvatars = value["guestAvatars"] as? [String] ?? []
        self.tags = value["tags"] as? [[String: String]] ?? []
        self.color = value["color"] as? String ?? "#36383B"
        self.pcolor = value["pcolor"] as? String ?? "#FFFFFF"
        self.scolor = value["scolor"] as? String ?? "#FFFFFF"
        self.isPrivate = value["isPrivate"] as? Bool ?? false
        self.listenBannerImageUrl = value["listenBannerImageUrl"] as? URL
    }
    
    func uploadListenImage(
        sup: Sup,
        coverImage: UIImage?,
        callback: @escaping (Sup) -> Void)
    {
        let uuid = UUID().uuidString
        let bgRef = bgImageRef.child("\(uuid).png")
        
        DispatchQueue.main.async {
            let listenImage = ListenBannerImage(sup: sup, coverImage: coverImage).asImage()
            DispatchQueue.global(qos: .background).async {
                if let listenData = listenImage.pngData() {
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/png"
                    let _ = bgRef.putData(listenData, metadata: metadata) { metadata, error in
                        bgRef.downloadURL { (url, error) in
                            if let url = url {
                                let data = ["listenBannerImageUrl": url.absoluteString]
                                db.collection("sups").document(sup.id).setData(data, merge: true) { err in
                                    if let err = err {
                                        Logger.log("Error updating image: %{public}@", log: .debug, type: .error, err.localizedDescription)
                                    } else {
                                        var sup = sup
                                        sup.listenBannerImageUrl = url
                                        callback(sup)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension Sup: Hashable {
    static func == (lhs:Sup, rhs:Sup) -> Bool {
        return lhs.id == rhs.id
    }
}
