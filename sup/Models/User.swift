//
//  User.swift
//  sup
//
//  Created by Robert Malko on 2/13/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Firebase
import OneSignal
import Foundation

private let db = Firestore.firestore()

private let storageRef = Storage.storage().reference()
private let usersRef = storageRef.child("users")
private let imageRef = storageRef.child("images/avatars")

class User: Identifiable {
    var uid: String
    var email: String?
    var completedOnboarding: Bool?
    var displayName: String?
    var username: String?
    var coins: Int
    var avatarUrl: String?
    var inviteBannerImageUrl: String?
    var numberOfListens: Int?
    var oneSignalPlayerId: String?
    var pushKitToken: String?
    var dynamicLinkUUID: String?
    var inviteURL: String?
    var latestSups: [String]?
    var playedSups: [String]?
    var latestComments: [String]?
    var playedComments: [String]?
    var color: String
    var pcolor: String
    var scolor: String
    var isSelected: Bool = false
    var lastLoginAt: Date?
    var happyHour: Bool?
    var currentSupCoverUrl: String?

    init(
        uid: String,
        displayName: String?,
        email: String?,
        coins: Int = 100,
        oneSignalPlayerId: String? = nil,
        dynamicLinkUUID: String? = nil,
        happyHour: Bool = true,
        color: String = "#36383B",
        pcolor: String = "#FFFFFF",
        scolor: String = "#FFFFFF"
    ) {
        self.uid = uid
        self.email = email
        self.coins = coins
        self.displayName = displayName
        self.oneSignalPlayerId = oneSignalPlayerId
        self.dynamicLinkUUID = dynamicLinkUUID
        self.happyHour = happyHour
        self.color = color
        self.pcolor = pcolor
        self.scolor = scolor
    }

    init?(snapshot: DocumentSnapshot?) {
        guard let snapshot = snapshot else { return nil }
        guard let value = snapshot.data() else { return nil }

        self.avatarUrl = value["avatarUrl"] as? String ?? nil
        self.completedOnboarding = value["completedOnboarding"] as? Bool ?? nil
        self.inviteBannerImageUrl = value["inviteBannerImageUrl"] as? String ?? nil
        self.displayName = value["displayName"] as? String ?? nil
        self.email = value["email"] as? String ?? nil
        self.oneSignalPlayerId = value["oneSignalPlayerId"] as? String ?? nil
        self.pushKitToken = value["pushKitToken"] as? String ?? nil
        self.dynamicLinkUUID = value["dynamicLinkUUID"] as? String ?? nil
        self.inviteURL = value["inviteURL"] as? String ?? nil
        self.uid = snapshot.documentID
        self.username = value["username"] as? String ?? nil
        self.coins = value["coins"] as? Int ?? 0
        self.latestSups = (value["latestSups"] != nil) ? value["latestSups"] as? [String] : []
        self.playedSups = (value["playedSups"] != nil) ? value["playedSups"] as? [String] : []
        self.latestComments = (value["latestComments"] != nil) ? value["latestComments"] as? [String] : []
        self.playedComments = (value["playedComments"] != nil) ? value["playedComments"] as? [String] : []
        self.color = value["color"] as? String ?? "#36383B"
        self.pcolor = value["pcolor"] as? String ?? "#FFFFFF"
        self.scolor = value["scolor"] as? String ?? "#FFFFFF"
        if let lastLoginAt = value["lastLoginAt"] as? Timestamp {
            self.lastLoginAt = lastLoginAt.dateValue()
        }
        if let happyHour = value["happyHour"] as? Bool {
            self.happyHour = happyHour
        }
        self.currentSupCoverUrl = value["currentSupCoverUrl"] as? String ?? nil
    }

    func needsLinkGeneration() -> Bool {
        return self.inviteBannerImageUrl == nil ||
            self.dynamicLinkUUID == nil ||
            self.inviteURL == nil
    }

    static func get(user: FirebaseAuth.User, callback: @escaping (User?) -> Void) {
        db.collection("users").document(user.uid)
            .getDocument() { (document, err) in
                if let _ = document?.data() {
                    if let user = User(snapshot: document) {
                        callback(user)
                    } else {
                        callback(nil)
                    }
                } else {
                    db.collection("users").document(user.uid).setData([
                        "email": user.email ?? "",
                        "displayName": user.displayName ?? "",
                        "username": "",
                        "avatarUrl": "",
                        "inviteBannerImageUrl": ""
                    ]) { err in
                        if let err = err {
                            Logger.log("Error writing document: %{public}@", log: .debug, type: .error, err.localizedDescription)
                        }
                    }
                    callback(nil)
                }
            }
    }

    static func get(userID: String, callback: @escaping (User?) -> Void) {
        db.collection("users").document(userID)
            .getDocument() { (document, err) in
                if let _ = document?.data() {
                    if let user = User(snapshot: document) {
                        callback(user)
                    } else {
                        callback(nil)
                    }
                } else {
                    callback(nil)
                }
            }
    }
    
    static func getListens(userID: String, callback: @escaping (Int?) -> Void) {
        db.collection("users").document(userID)
            .getDocument() { (document, err) in
                if let _ = document?.data() {
                    if let snapshot = document, let value = snapshot.data() {
                        if let numberOfListens = value["numberOfListens"] as? Int {
                            callback(numberOfListens)
                        } else {
                            callback(nil)
                        }
                    } else {
                        callback(nil)
                    }
                } else {
                    callback(nil)
                }
            }
    }
    
    static func get(username: String, callback: @escaping (User?) -> Void) {
        db.collection("users").whereField("username", isEqualTo: username)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    if let document = querySnapshot!.documents.first {
                        if let user = User(snapshot: document) {
                            callback(user)
                        } else {
                            callback(nil)
                        }
                    } else {
                        callback(nil)
                    }
                }
            }
    }
    
    static func all(usernames: [String], callback: @escaping ([User]) -> Void) {
        let usernames = usernames.filter {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).count > 0
        }
        let truncatedUsernames = Array(usernames.prefix(10))
        db.collection("users").whereField("username", in: truncatedUsernames)
            .getDocuments() { (querySnapshot, err) in
                var users = [User]()
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        if let user = User(snapshot: document) {
                            users.append(user)
                        }
                    }
                }
                callback(users)
            }
    }

    static func update(userID: String?, data: [String: Any]) {
        guard let userID = userID else { return }
        db.collection("users").document(userID).setData(data, merge: true)
    }
    
    static func update(userID: String?, data: [String: Any], callback: @escaping (Bool) -> Void) {
        guard let userID = userID else { return }
        db.collection("users").document(userID).setData(data, merge: true) { err in
            if let err = err {
                Logger.log("Error updating document: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                callback(true)
            }
        }
    }

    static func validate(username: String, callback: @escaping (Bool) -> Void) {
        let docRef = db.collection("users").whereField("username", isEqualTo: username).limit(to: 1)
        docRef.getDocuments { (querysnapshot, error) in
            if let err = error {
                Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                if let doc = querysnapshot?.documents, !doc.isEmpty { callback(true) }
                else { callback(false) }
            }
        }
    }

    static func updateImage(
        userID: String?,
        avatarPhoto: UIImage?,
        color: String,
        pcolor: String,
        scolor: String,
        callback: @escaping (String) -> Void) {
        guard let userID = userID else { return }

        let uuid = UUID().uuidString
        let imgRef = imageRef.child("\(userID)_\(uuid).png")

        let avatarUrl = URL(string: "https://firebasestorage.googleapis.com/v0/b/sup-89473.appspot.com/o/images%2Fdefaults%2Fdefault-cover.png?alt=media&token=0ee68c09-67c8-4ede-94d1-00868f6f99ea")!

        let data = ["avatarUrl": avatarUrl.absoluteString]

        if let imgData = avatarPhoto?.pngData() {
            let metadata = StorageMetadata()
            metadata.contentType = "image/png"
            let _ = imgRef.putData(imgData, metadata: metadata) { metadata, error in
                imgRef.downloadURL { (url, error) in
                    if let url = url {
                        let avatarUrl = url.absoluteString.replacingOccurrences(
                            of: ".png?", with: "_636x636.png?"
                        )
                        let data = [
                            "avatarUrl": avatarUrl,
                            "color": color,
                            "pcolor": pcolor,
                            "scolor": scolor
                        ]
                        db.collection("users").document(userID).setData(data, merge: true) { err in
                            if let err = err {
                                Logger.log("Error updating image: %{public}@", log: .debug, type: .error, err.localizedDescription)
                            } else {
                                callback(avatarUrl)
                            }
                        }
                    }
                }
            }
        } else {
            db.collection("users").document(userID).setData(data, merge: true) { err in
                if let err = err {
                    Logger.log("Error updating image: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    callback(avatarUrl.absoluteString)
                }
            }
        }
    }
    
    static func updateInviteImage(userID: String?, invitePhoto: UIImage?, callback: @escaping (String?) -> Void) {
        guard let userID = userID else {
            callback(nil)
            return
        }

        let uuid = UUID().uuidString
        let imgRef = imageRef.child("\(userID)_\(uuid).png")

        if let imgData = invitePhoto?.pngData() {
            let metadata = StorageMetadata()
            metadata.contentType = "image/png"
            let _ = imgRef.putData(imgData, metadata: metadata) { metadata, error in
                imgRef.downloadURL { (url, error) in
                    if let url = url {
                        let data = ["inviteBannerImageUrl": url.absoluteString]
                        db.collection("users").document(userID).setData(data, merge: true) { err in
                            if let err = err {
                                callback(nil)
                                Logger.log("Error updating image: %{public}@", log: .debug, type: .error, err.localizedDescription)
                            } else {
                                callback(url.absoluteString)
                            }
                        }
                    } else {
                        callback(nil)
                    }
                }
            }
        } else {
            let defaultBannerImageUrl = URL(string: "https://firebasestorage.googleapis.com/v0/b/sup-89473.appspot.com/o/images%2Fdefaults%2Fdefault-cover.png?alt=media&token=0ee68c09-67c8-4ede-94d1-00868f6f99ea")!
            let data = ["inviteBannerImageUrl": defaultBannerImageUrl.absoluteString]
            db.collection("users").document(userID).setData(data, merge: true) { err in
                if let err = err {
                    callback(nil)
                    Logger.log("Error updating image: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    callback(defaultBannerImageUrl.absoluteString)
                }
            }
        }
    }

    static func fromDynamicLink(_ link: DynamicLink, currentUserId: String?) {
        guard let url = link.url else {
            return
        }

        guard let linkUUID = url.absoluteString.split(separator: "/").last else {
            return
        }

        if currentUserId == nil {
            AppDelegate.inviteLinkUUID = String(linkUUID)
            return
        }

        self.fromInviteLinkUUID(String(linkUUID), currentUserId: currentUserId)
    }

    static func fromInviteLinkUUID(_ linkUUID: String, currentUserId: String?) {
        guard let currentUserId = currentUserId else {
            return
        }

        func getUserFromLink() {
            db.collection("users")
                .whereField("dynamicLinkUUID", isEqualTo: linkUUID)
                .getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                    } else {
                        if let document = querySnapshot!.documents.first {
                            guard let user = User(snapshot: document) else {
                                return
                            }

                            getLoggedInUser(user)
                        }
                    }
                }
        }

        func getLoggedInUser(_ userFromLink: User) {
            User.get(userID: currentUserId) { loggedInUser in
                guard let loggedInUser = loggedInUser else { return }
                guard userFromLink.uid != loggedInUser.uid else { return }

                saveRecentGuests(currentUser: loggedInUser, guestUser: userFromLink) { _ in
                    if SupUserDefaults.timesSharePassHintShown >= 1 {
                        self.showAlert(loggedInUser, userFromLink)
                    }
                }
                saveRecentGuests(currentUser: userFromLink, guestUser: loggedInUser) { _ in
                    self.sendPush(loggedInUser, userFromLink)
                }
            }
        }

        getUserFromLink()
    }
    
    static func saveRecentGuests(
        currentUser: User,
        guestUser: User,
        callback: @escaping (Guest) -> Void
    ) {
        DispatchQueue.global(qos: .background).async {
            Guest.get(userID: currentUser.uid) { guest in
                if let guest = guest {
                    var users = [[String:String]]()
                    
                    let user = [
                        "userID": guestUser.uid,
                        "username": guestUser.username ?? "",
                        "avatarUrl": guestUser.avatarUrl ?? ""
                    ]
                    
                    if !guest.users.contains(where: { $0["userID"] == guestUser.uid }) {
                        users.append(user)
                    } else {
                        Guest.delete(userID: currentUser.uid, users: [user]) { guest in }
                        users.append(user)
                    }
                    
                    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {
                        Guest.create(userID: currentUser.uid, users: users) { guest in
                            callback(guest)
                        }
                    }
                }
            }
        }
    }
    
    static func updateCoins(
        username: String,
        coins: Int,
        callback: @escaping (Bool) -> Void
    ) {
        var data:[String: Any] = [:]
        
        db.collection("users").whereField("username", isEqualTo: username)
        .getDocuments() { (querySnapshot, err) in
            if let err = err {
                Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                if let document = querySnapshot!.documents.first {
                    data["coins"] = NSNumber(value: coins)
                    
                    self.update(document: document,
                                data: data,
                                callback: callback)
                }
            }
        }
    }

    static func updateNOL(
        username: String,
        callback: @escaping (Bool) -> Void
    ) {
        var data:[String: Any] = [:]
        
        db.collection("users").whereField("username", isEqualTo: username)
        .getDocuments() { (querySnapshot, err) in
            if let err = err {
                Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                if let document = querySnapshot!.documents.first {
                    let value = document.data()
                    if let numberOfListens = value["numberOfListens"] as? Int {
                        var  numberOfListens = numberOfListens
                        
                        numberOfListens += 1
                        data["numberOfListens"] = NSNumber(value: numberOfListens)
                        
                        self.update(document: document,
                                    data: data,
                                    callback: callback)
                    }
                }
            }
        }
    }
    
    private static func update(
        document: QueryDocumentSnapshot,
        data: [String: Any],
        callback: @escaping (Bool) -> Void
    ) {
        document.reference.updateData(data) { err in
            if let err = err {
                Logger.log("Error updating document: %{public}@", log: .debug, type: .error, err.localizedDescription)
            } else {
                callback(true)
            }
        }
    }
    
    static func allToUpdateNewField(callback: @escaping () -> Void) {
        db.collection("users")
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.log("Error getting documents: %{public}@", log: .debug, type: .error, err.localizedDescription)
                } else {
                    for document in querySnapshot!.documents {
                        let value = document.data()
                        //if value["coins"] == nil {
                            /// Add default value
                            let data:[String: Any] = [
                                "coins": NSNumber(value: 100)
                            ]
                            document.reference.updateData(data)
                        //}
                    }
                    callback()
                }
            }
    }
    
    static func sendPush(_ loggedInUser:User, _ userFromLink: User) {
        guard let username = loggedInUser.username else { return }
        var playerIds = [String]()
        playerIds.append(userFromLink.oneSignalPlayerId ?? "")
        let pushText = "\(username) is on your guest list! start a sup 🎤😀"
        OneSignal.postNotification(
            ["contents": ["en": pushText],
             "include_player_ids": playerIds])
    }
    
    static func showAlert(_ loggedInUser:User, _ userFromLink: User) {
        let alertController = UIAlertController(title: "\(userFromLink.username ?? "") added!", message: "you can now record sups with \(userFromLink.username ?? "")", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "okay!", style: .default, handler: nil))
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        vc?.present(alertController, animated: true, completion: nil)
    }
}
