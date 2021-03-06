//
//  PublishScreen.swift
//  sup
//
//  Created by Justin Spraggins on 2/21/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//
//
import SwiftUI
import AVFoundation
import SDWebImageSwiftUI
import OneSignal
import FirebaseStorage
import UIImageColors
import PaperTrailLumberjack

private let newSupState = NewSupState()
private let storageRef = Storage.storage().reference()
private let bgImageRef = storageRef.child("images/sup_backgrounds")

struct PublishScreen: View {
    @ObservedObject var state: AppState
    @ObservedObject var newSupState: NewSupState
    @EnvironmentObject var audioPlayer: AudioPlayer

    @State private var selectedChannel: String?
    @State private var savedSup: Sup?
    @State private var isTyping = false
    @State private var savingSupLoader = false
    @State private var supSavedButton = false
    @State private var hidePhotoLibrary = false
    @State private var editStage = true
    @State private var showPlayControls = false
    @State private var savingStage = false
    @State private var savedStage = false
    @State private var doneStage = false
    @State private var isPrivate = false
    @State var value: Double = 0

    var guestAvatars: [String]
    let previewGuestUsers: [User]
    var tapDone: (() -> Void)? = nil
    let coverSize: CGFloat = screenWidth - (isIPhoneX ? 84 : 114)
    let imageView: Image
    let topicCoverPhoto: WebImage?

    let bitmojiSize: CGFloat = isIPhoneX ? 44 : 38

    private func sendPush(sup: Sup) {
        /// Send push notificaiton to guests
        if sup.guests.isNotEmpty {
            User.all(usernames: sup.guests) { users in
                var playerIds = [String]()
                for user in users { playerIds.append(user.oneSignalPlayerId ?? "") }
                OneSignal.postNotification(
                    ["contents": ["en": "\(sup.username) just posted the sup you were a guest on: \(sup.description) 🎙"],
                     "include_player_ids": playerIds])
            }
        }

        /// Send push notificaiton to friends
        if self.state.friends.isNotEmpty {
            guard let username = self.state.currentUser?.username else { return }
            var playerIds = [String]()
            for user in self.state.friends { playerIds.append(user.oneSignalPlayerId ?? "") }
            OneSignal.postNotification(
                ["contents": ["en": "\(username) posted a new sup: \(sup.description) 🎧"],
                 "include_player_ids": playerIds])
        }

        /// Send push notificaiton to yourself
//        guard let playerId = self.state.currentUser?.oneSignalPlayerId else { return }
//        var playerIds = [String]()
//        playerIds.append(playerId)
//        OneSignal.postNotification(
//            ["contents": ["en": "Your podcast has been saved to your profile!"],
//             "include_player_ids": playerIds])
    }

    private func saveRecentGuests() {
        guard let userID = self.state.currentUser?.uid else { return }
        DispatchQueue.global(qos: .background).async {
            if let guest = self.state.guest {
                var users = [[String:String]]()

                for guestUser in self.previewGuestUsers {
                    let user = [
                        "userID": guestUser.uid,
                        "username": guestUser.username ?? "",
                        "avatarUrl": guestUser.avatarUrl ?? ""
                    ]

                    if !guest.users.contains(where: { $0["userID"] == guestUser.uid }) {
                        users.append(user)
                    } else {
                        Guest.delete(userID: userID, users: [user]) { guest in }
                        users.append(user)
                    }
                }

                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {
                    Guest.create(userID: userID, users: users) { guest in
                        self.state.guest = guest
                    }
                }
            }
        }
    }

    private func postOnComplete(callback: @escaping (Sup) -> Void) {
        let uuid = UUID().uuidString
        let bgRef = bgImageRef.child("\(uuid).png")
        let clips = self.state.audioRecorder.clips

        func saveSup(url: URL? = nil, coverData: Data? = nil) {
            self.state.audioRecorder.saveSup(clips: clips, uuid: uuid) { supURL, supSize, supDuration in
                var tags: [[String: String]] = []
                if self.state.selectedPrompt != nil {
                    let tag = [
                        "text": self.state.selectedPrompt!.text,
                        "color": self.state.selectedPrompt!.color
                    ]
                    tags.append(tag)
                }

                let duration = AVURLAsset(url: supURL).duration.seconds
                let channel = self.selectedChannel
                let defaultCoverArtUrl = "https://firebasestorage.googleapis.com/v0/b/sup-89473.appspot.com/o/images%2Fdefaults%2Fdefault-cover.png?alt=media&token=0ee68c09-67c8-4ede-94d1-00868f6f99ea"
                let defaultAvatarUrl = "https://firebasestorage.googleapis.com/v0/b/sup-89473.appspot.com/o/images%2Fdefaults%2Fdefault-avatar.png?alt=media&token=6104592c-3820-451e-b6e6-501ebc2c803a"
                var coverArtUrl = defaultCoverArtUrl
                if let url = url {
                    coverArtUrl = url.absoluteString.replacingOccurrences(of: ".png?", with: "_636x636.png?")
                }

                guard let userID = self.state.currentUser?.uid, let username = self.state.currentUser?.username else {
                    return AuthService.logout() {
                        self.state.isOnboarding = true
                        self.state.currentUser = nil
                    }
                }

                var avatarUrl = URL(string: defaultAvatarUrl)!
                if let urlString = self.state.currentUser?.avatarUrl {
                    if let url = URL(string: urlString) { avatarUrl = url }
                }

                self.getColors(coverArtUrl: coverArtUrl) { colors in
                    let color = self.state.selectedPrompt?.color ?? colors[0]
                    let pcolor = self.state.selectedPrompt?.pcolor ?? colors[1]

                    if self.state.selectedPrompt?.image != nil {
                        coverArtUrl = self.state.selectedPrompt!.image
                    }

                    DispatchQueue.global(qos: .background).async {
                        DispatchQueue.main.async {
                            if coverData != nil {
                                self.state.coverImage = UIImage(data: coverData!)
                            }
                        }

                        Sup.create(
                            userID: userID,
                            username: username,
                            description: self.newSupState.title,
                            url: supURL,
                            coverArtUrl: URL(string: coverArtUrl)!,
                            avatarUrl: avatarUrl,
                            size: supSize,
                            duration: duration,
                            channel: channel,
                            color: color,
                            pcolor: pcolor,
                            scolor: colors[2],
                            created: Date(),
                            canFeature: SupUserDefaults.featureAllowed(userID: userID),
                            guests: self.previewGuestUsers.map { $0.username ?? "" },
                            guestAvatars: self.previewGuestUsers.map { $0.avatarUrl ?? "" },
                            tags: tags,
                            isPrivate: self.isPrivate
                        ) { savedSup in
                            DDLogVerbose("sup created: id=\(savedSup.id) guests=\(savedSup.guests)")
                            callback(savedSup)
                        }
                        self.selectedChannel = nil
                    }
                }
            }
        }

        if let bgCoverData = self.state.coverPhotoData {
            if let currentCoverUrl = self.state.currentUser?.currentSupCoverUrl,
                let url = URL(string: currentCoverUrl), !self.state.coverPhotoChanged {
                saveSup(url: url, coverData: bgCoverData)
            } else {
                let metadata = StorageMetadata()
                metadata.contentType = "image/png"
                let _ = bgRef.putData(bgCoverData, metadata: metadata) { metadata, error in
                    bgRef.downloadURL { (url, error) in
                        if let url = url {
                            let data = ["currentSupCoverUrl": url.absoluteString]
                            User.update(userID: self.state.currentUser?.uid, data: data)
                        }
                        saveSup(url: url, coverData: bgCoverData)
                    }
                }
            }
        } else {
            saveSup()
        }
    }

    private func getColors(coverArtUrl: String, callback: @escaping ([String]) -> Void) {
        var color = ""
        var pcolor = ""
        var scolor = ""

        if
            let coverColor = self.state.coverColor,
            let primaryColor = self.state.primaryColor,
            let secondaryColor = self.state.secondaryColor
        {
            color = coverColor.hexString()
            pcolor = primaryColor.hexString()
            scolor = secondaryColor.hexString()

            return callback([color, pcolor, scolor])
        }

        if
            let coverArt = URL(string: coverArtUrl),
            let coverPhoto = try? Data(contentsOf: coverArt),
            let cover = UIImage(data: coverPhoto)
        {
            cover.getColors { colors in
                if
                    let bgcolor = colors?.background.hexString(),
                    let prcolor = colors?.primary.hexString(),
                    let srcolor = colors?.secondary.hexString()
                {
                    color = bgcolor
                    pcolor = prcolor
                    scolor = srcolor
                    return callback([color, pcolor, scolor])
                } else {
                    return callback([color, pcolor, scolor])
                }
            }
        } else {
            return callback([color, pcolor, scolor])
        }
    }

    private func getColors(avatarUrl: String, callback: @escaping ([String]) -> Void) {
        var color = ""
        var pcolor = ""
        var scolor = ""

        if
            let avatarArt = URL(string: avatarUrl),
            let avatarPhoto = try? Data(contentsOf: avatarArt),
            let avatar = UIImage(data: avatarPhoto)
        {
            avatar.getColors { colors in
                if
                    let bgcolor = colors?.background.hexString(),
                    let prcolor = colors?.primary.hexString(),
                    let srcolor = colors?.secondary.hexString()
                {
                    color = bgcolor
                    pcolor = prcolor
                    scolor = srcolor
                    return callback([color, pcolor, scolor])
                } else {
                    return callback([color, pcolor, scolor])
                }
            }
        } else {
            return callback([color, pcolor, scolor])
        }
    }

    private func saveSup() {
        impact(style: .soft)
        self.hidePhotoLibrary = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.editStage = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.savingStage = true
                self.showPlayControls = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.postOnComplete() { sup in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            sup.uploadListenImage(sup: sup, coverImage: self.state.coverImage) { sup in
                                self.savedSup = sup
                                self.state.publishedSup = sup
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    self.savingStage = false
                                    self.savedStage = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        self.doneStage = true
                                    }
                                }
                                self.state.supDidCreate.send(sup)
                                self.sendPush(sup: sup)
                                self.saveRecentGuests()

                                guard var coins = self.state.currentUser?.coins else { return }
                                coins = coins + 25
                                self.state.add(coins: coins) { _ in }
                            }
                        }
                    }
                }
            }
        }
    }

    private func completePublish() {
        SupAnalytics.publishSup()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.state.selectedPrompt = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
                self.state.showPublishSocials = true
            }
        }
        onDone()
    }

    private func isPlayingClip() -> Bool {
        self.audioPlayer.playingURL == self.state.audioRecorder.clips.last?.fileURL && self.audioPlayer.isPlaying
    }

    private func deletePublish() {
        self.onDone()
        DispatchQueue.main.async {
            if AppDelegate.callSessionId != nil {
                FirebaseCall.update(sessionId: AppDelegate.callSessionId!, data: ["status": "canceled"])
            }
            AppPublishers.callStatusUpdated$.send("canceled")
        }
    }

    private func onDone() {
        self.state.showPublish = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AppPublishers.publishFlowDone$.send()
            self.state.audioPlayer.stopPlayback()
            self.state.audioRecorder.clips = []
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.state.hideMain = false
                self.state.hideNav = false
                self.state.hideLogoButton = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.newSupState.title = ""
                    self.doneStage = false
                    self.showPlayControls = false
                    self.editStage = true
                }
            }
        }
    }

    private func showPublishPhotoLibrary() {
        self.state.photosPermissions { allowed in
            if allowed {
                self.state.hidePublish = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.state.showPhotoLibrary = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        self.state.animatePhotoLibrary = true
                    }
                }
            } else {
                self.state.promptForPhotoPermissions()
            }
        }
    }

    private func coverColor() -> UIColor {
        let defaultColor = UIColor(red: 54/255, green: 56/255, blue: 59/255, alpha: 1)

        if state.selectedPrompt?.color != nil {
            return state.selectedPrompt!.color.color()
        }

        return state.coverColor ?? defaultColor
    }

    var body: some View {
        VStack {
            ZStack  {
            RoundedRectangle(cornerRadius: isIPhoneX ? 40 : 8)
                .foregroundColor(Color.black)
                .frame(width: screenWidth, height: screenHeight)

            RoundedRectangle(cornerRadius: isIPhoneX ? 40 : 8)
                .foregroundColor(Color(coverColor()).opacity(0.7))
                .frame(width: screenWidth, height: screenHeight)

            VStack {
                //EditStage
                Group {
                    Spacer()
                    imageView
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: coverSize, height: coverSize)
                        .cornerRadius(18)
                        .contentShape(Rectangle())
                        .shadow(color: isPlayingClip() ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 20, x: 0, y: 5)


                    Spacer().frame(height: isIPhoneX ? (isTyping ? 25 : 20) : (isTyping ? 15 : 10))

                    SupCaption(state: state,
                                titleText: self.$newSupState.title,
                                isTyping: self.$isTyping,
                                hidePlaceholder: self.$showPlayControls,
                                showKeyboard: false,
                                accentColor: .white)
                        .disabled(editStage ? false : true)
                    Spacer().frame(height: 10)

                    if editStage {
                        Spacer()
                        Button(action: {
                            impact(style: .soft)
                            self.showPublishPhotoLibrary()
                        }) {
                            HStack (spacing: 18) {
                                ZStack {
                                    Circle()
                                        .foregroundColor(Color.primaryTextColor.opacity(0.1))
                                        .frame(width: 48, height: 48)
                                    Image("photo-library")
                                        .renderingMode(.template)
                                        .foregroundColor(Color.primaryTextColor.opacity(0.9))
                                }

                                Text("change cover photo")
                                    .modifier(TextModifier(size: 20, font: Font.textaAltBold, color: Color.primaryTextColor.opacity(0.8)))
                                Spacer()
                            }
                            .padding(.leading, 18)
                            .padding(.trailing, 20)
                            .frame(width: screenWidth - 30, height: 72)
                            .background(
                                Color.white.opacity(0.1)
                                    .frame(width: screenWidth - 30, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 27))
                            )
                        }
                        .buttonStyle(ButtonBounceLight())
                        .opacity(isTyping || hidePhotoLibrary ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3))
                        .scaleEffect(isTyping || hidePhotoLibrary ? 0.9 : 1)
                        .animation(.spring())
                    }
                }

                //SavingStage
                if !editStage {
                    VStack {
                        Spacer().frame(height: 5)
                        PlayBar(state: state,
                                value: $value,
                                isPlaying: state.isPlayingPreview,
                                duration: Double(self.state.audioRecorder.clips.last?.duration ?? 0),
                                width: screenWidth - 44)
                            .padding(.top, 2)

                        HStack {
                            Button(action: {}) {
                                ZStack {
                                    Text(calculateValue().toTime)
                                        .modifier(TextModifier(size: 16, color: Color.white.opacity(0.1)))
                                        .animation(nil)
                                    Text(calculateValue().toTime)
                                        .modifier(TextModifier(size: 16, color: .white))
                                        .animation(nil)
                                        .blendMode(.overlay)
                                }
                            }
                            .buttonStyle(ButtonBounceNone())

                            Spacer()
                            ZStack {
                                Text(Double(self.state.audioRecorder.clips.last?.duration ?? 0).toTime)
                                    .modifier(TextModifier(size: 16, color: Color.white.opacity(0.1)))
                                Text(Double(self.state.audioRecorder.clips.last?.duration ?? 0).toTime)
                                    .modifier(TextModifier(size: 16, color: .white))
                                    .blendMode(.overlay)
                            }
                        }
                        .padding(.top, 4)
                        .frame(width: screenWidth - 44)

                        Spacer().frame(height: isIPhoneX ? 40 : 20)
                        HStack (spacing: 45) {
                            MediaPlayerButton(image: "player-back", action: {})
                            Button(action: {
                                impact(style: .soft)
                                if self.state.isPlayingPreview {
                                    self.state.isPlayingPreview = false
                                    self.state.audioPlayer.pausePlayback()
                                } else {
                                    self.state.isPlayingPreview = true
                                    if let url = self.state.audioRecorder.clips.last?.fileURL {
                                        self.state.audioPlayer.startPlayback(audio: url)
                                    }
                                }
                            }) {
                                ZStack {
                                    Spacer().frame(width: 68, height: 68)
                                    if self.state.isCallArchived {
                                        Image(self.isPlayingClip() ? "player-pause" : "player-play")
                                            .renderingMode(.template)
                                            .foregroundColor(.white)
                                            .animation(nil)
                                    } else {
                                        LoaderCircle(size: 34, innerSize: 30, isButton: true, tint: .white)
                                    }
                                }
                            }
                            .buttonStyle(ButtonBounceHeavy())
                            MediaPlayerButton(image: "player-forward", action: {})
                        }
                    }
                }

                Spacer().frame(height: isIPhoneX ? (editStage ? 30 : 50) : 30)
                ZStack {
                    Spacer().frame(width: screenWidth, height: 48)
                    PublishFooter(state: state,
                                    editStage: $editStage,
                                    doneStage: $doneStage,
                                    isPrivate: $isPrivate,
                                    tapChangePhoto: { self.showPublishPhotoLibrary() },
                                    tapDelete: { self.deletePublish() },
                                    tapSave: { self.saveSup() },
                                    tapDone: { self.completePublish() },
                                    baseColor: Color(self.state.coverColor ?? UIColor(red: 54/255, green: 56/255, blue: 59/255, alpha: 1)))
                        .offset(y: isTyping ? 50 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0))

                    if self.savingStage {
                        HStack (spacing: 25) {
                            LoaderCircle(size: 20, innerSize: 20, isButton: true, tint: .white)
                                .background(Color.black.opacity(0.3).frame(width: 48, height: 48).clipShape(Circle()))
                                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))

                            Text("saving your sup...")
                                .modifier(TextModifier(size: 19, color: Color.white))
                                .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 0)
                        }
                    }
                }
                Spacer().frame(height: isIPhoneX ? 50 : 25)
            }
            .frame(width: screenWidth, height: screenHeight)
            .offset(y: isTyping ? -180 : 0)
            .animation(Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0).speed(0.7))
        }
        }
        .transition(.move(edge: .bottom))
        .animation(.spring())
    }

    func calculateValue() -> Double {
        if let clip = self.state.audioRecorder.clips.last {
            let value = Double(clip.duration) * self.value
            return value
        } else {
            return 0
        }
    }
}
