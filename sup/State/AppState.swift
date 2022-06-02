//
//  AppState.swift
//  sup
//
//  Created by Robert Malko on 11/16/19.
//  Copyright © 2019 Episode 8, Inc.. All rights reserved.
//

import Combine
import SwiftUI
import UIKit
import SCSDKLoginKit
import FirebaseAuth
import UIImageColors
import AVFoundation
import Photos

final class AppState: ObservableObject {
    init() {
        /// NOTE: SwiftUI doesn't support nested Observables yet
        /// See: https://stackoverflow.com/a/58878219
        audioPlayerCancellable = audioPlayer.objectWillChange.sink { (_) in
            self.objectWillChange.send()
        }
        audioRecorderCancellable = audioRecorder.objectWillChange.sink { (_) in
            self.objectWillChange.send()
        }

        if let coverPhoto = SupUserDefaults.coverPhoto() {
            let image = UIImage(data: coverPhoto) ?? UIImage()
            let imageView = Image(uiImage: image)
            self.coverPhotoData = coverPhoto
            self.coverPhoto = imageView

            if SupUserDefaults.coverPhotoHash() == nil {
                SupUserDefaults.saveCoverPhotoHash(photoData: coverPhoto)
            }

            image.getColors { colors in
                self.coverColor = colors?.background
                self.primaryColor = colors?.primary
                self.secondaryColor = colors?.secondary
            }
        }

        if let bitmojiPhoto = SupUserDefaults.bitmojiPhoto() {
            let image = UIImage(data: bitmojiPhoto) ?? UIImage()
            let imageView = Image(uiImage: image)
            self.bitmojiPhoto = imageView
        }
    }

    deinit {
        audioPlayerCancellable?.cancel()
        audioRecorderCancellable?.cancel()
    }

    @Published var isAdmin = false
    @Published var albums: [EVPhotoKit.Album] = []
    @Published var hasPhotoAccess = false

    @Published var currentUser: User?
    @Published var selectedUser: User?
    @Published var guest: Guest?
    @Published var guestUsers = [User]()
    @Published var isVerified = false

    ///General
    @Published var keyboardShown: Bool = false
    @Published var fadeIn: Bool = false
    @Published var showNotification = false
    @Published var tapPlay = false
    @Published var audioRecorder = AudioRecorder()
    @Published var audioPlayer = AudioPlayer()
    @Published var profilePlaylist = [Sup]()
    @Published var selectedSup: Sup?
    @Published var playingSup: Sup?
    @Published var publishedSup: Sup?
    @Published var selectedMention: String?
    @Published var selectedComment: Comment?
    @Published var friends = [User]()
    @Published var allComments = [Comment]()
    @Published var animateStartButton = false
    @Published var questions = [Question]()
    @Published var showQuestions = true
    @Published var browseQuestions = false
    @Published var isConnectHappyHour = false
    @Published var showQuestionsCard = false

    ///Onboarding
    @Published var isOnboarding: Bool = false
    @Published var loadPhotoLibrary = false
    @Published var disabledButton = false
    @Published var onboardingStage: OnboardingStage = .AppleLogin
    @Published var isRecording: Bool = false
    @Published var disableOnRecord = false

    ///Main
    @Published var showSplashLogo = true
    @Published var moveToHome = true
    @Published var moveToProfile = false
    @Published var moveToFriends = false
    @Published var showPublishSocials = false
    @Published var showNotifications = false

    lazy var moveToProfile$: AnyPublisher<Bool, Never> = {
        return $moveToProfile.removeDuplicates().eraseToAnyPublisher()
    }()
    lazy var moveToFriends$: AnyPublisher<Bool, Never> = {
        return $moveToFriends.removeDuplicates().eraseToAnyPublisher()
    }()
    
    @Published var hostname: String? = nil
    @Published var hostAvatar = ""
    @Published var guestAvatars = [String]()
    @Published var latestFeed = false
    @Published var showRecents = false
    @Published var animateRecents = false
    @Published var showAddFriend = false
    @Published var animateAddFriend = false
    @Published var showMediaPlayerDrawer = false
    @Published var showMediaPlayer = false
    lazy var showMediaPlayer$: AnyPublisher<Bool, Never> = {
        return $showMediaPlayer.removeDuplicates().eraseToAnyPublisher()
    }()
    @Published var showMediaPLayerHint = false
    @Published var animateNavBar = false
    @Published var animateNavDot = false
    @Published var showSplashVideo = true
    @Published var guestAdded = false

    ///Cards
    @Published var hideRecordButton = true
    @Published var showInviteGuest = false
    @Published var showSettingsCard = false
    @Published var showUserProfile = false
    lazy var showUserProfile$: AnyPublisher<Bool, Never> = {
        return $showUserProfile.removeDuplicates().eraseToAnyPublisher()
    }()
    @Published var showShareCard = false
    @Published var showShareVideoCard = false
    @Published var showFollowingCard = false
    @Published var showCallEnded = false
    @Published var showMessageCard = false
    @Published var showReplyCard = false
    @Published var showCoinsCard = false
    @Published var showLoginCard = false
    @Published var showHappyHourCard = false
    @Published var liveMatching = false
    @Published var happyHourLogo = false
    @Published var showSnapchatCard = false
    @Published var happyHourHost = false

    ///Call
    @Published var guestSelected = false

    @Published var hideNav = false
    @Published var hideLogoButton = false
    @Published var hideMain = false
    @Published var hidePublish = false
    @Published var isConnecting = false
    @Published var hideInvite = false

    @Published var moveMainUp = false
    @Published var showGuestList = false

    @Published var showOutgoing = false
    @Published var animateOutgoing = false
    @Published var hideEndButton = false
    @Published var settingUpMic = true
    @Published var isWaiting = false
    @Published var startedRecording = false
    @Published var scaleMediaPlayer = false
    @Published var loadingCall = false
    @Published var animateLoadingCard = false
    @Published var animateCallers = false
    @Published var isConnect = false
    @Published var isCalling = false
    @Published var showCalling = false
    @Published var animateCalling = false
    @Published var isCallArchived = false
    @Published var callArchiveId: String?
    @Published var maxSeconds = 10 * 60.0
    @Published var callBaseURL: String?
    @Published var selectedPrompt: Prompt?
    @Published var animateQuestions = false
    @Published var hideQuestionText = false
    @Published var showRateCard = false
    @Published var showWriteCard = false
    @Published var animateWriteCard = false

    @Published var guestLoadingCall = false
    @Published var callerLoadingCall = false

    @Published var count3 = false
    @Published var count2 = false
    @Published var count1 = false

    //Call navigation buttons
    @Published var animateStartRecording = true
    @Published var animateIsRecording = false
    @Published var animateAudioSaved = false

    @Published var showingCallScreen = false
    @Published var showCallScreen = false
    @Published var animateCallScreen = false

    ///Share Flow
    @Published var hideProfile = false

    @Published var showPublish = false
    @Published var showOverlay = false
    @Published var showPhotoLibrary = false
    @Published var animatePhotoLibrary = false
    @Published var noCoverPhoto = false
    @Published var isPublishStage = false
    @Published var isPlayingPreview = false

    func animateToCall() {
        self.moveToHome = true
        self.moveMainUp = false
        self.showGuestList = false
        self.moveToProfile = false
        self.moveToFriends = false
        self.showMediaPlayerDrawer = false
        self.hideInvite = true
        self.browseQuestions = false
        self.showHappyHourCard = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.hideInvite = false
        }
    }

    ///Data
    @Published var selectedProfile: ProfileCardable?
    @Published var selectedSoundClip: SoundClips?
    @Published var coverPhoto: Image = Image("default-cover")
    @Published var coverPhotoData: Data?
    @Published var coverPhotoChanged: Bool = false
    @Published var coverImage: UIImage?
    @Published var coverColor: UIColor?
    @Published var primaryColor: UIColor?
    @Published var secondaryColor: UIColor?
    @Published var avatarPhoto: Image = Image("default-avatar")
    @Published var bitmojiPhoto: Image?
    @Published var avatarPhotoData: Data?
    @Published var defaultImage = UIImage(named: "default-avatar")!
    @Published var avatarImage: UIImage?

    @Published var feedOffset: CGPoint = CGPoint(x: 0, y: 0)

    func isEditStage() -> Bool {
        audioRecorder.clips.count > 0
      }

    enum OnboardingStage {
        case AppleLogin
        case ConnectSnapchat
        case ClaimUsername
        case PushNotifications
        case PermissionSettings
    }

    var audioPlayerCancellable: AnyCancellable? = nil
    var audioRecorderCancellable: AnyCancellable? = nil
    let supDidCreate = PassthroughSubject<Sup, Never>()
    let supDidDelete = PassthroughSubject<Sup, Never>()
    let playlistDidCreate = PassthroughSubject<Playlist, Never>()
    let playlistDidDelete = PassthroughSubject<Bool, Never>()
    let friendDidAdd = PassthroughSubject<Bool, Never>()
    let callInitiated$ = PassthroughSubject<SupAPI.Call, Never>()
    let openTokSession$ = PassthroughSubject<OpenTokEvent, Never>()
    let callNotActive$ = PassthroughSubject<Void, Never>()
    let callNotAllowed$ = PassthroughSubject<Void, Never>()
    let callDidStart$ = PassthroughSubject<Bool, Never>()
    let userDidLoad$ = PassthroughSubject<Void, Never>()
    let receiverOnCallEnd$ = PassthroughSubject<Void, Never>()
    let startGuestTimer$ = PassthroughSubject<Double, Never>()
    let startGuestCounter$ = PassthroughSubject<Void, Never>()

    var rootController: UIViewController?

    var snapchatExternalId: String?
    var snapchatDisplayName: String?
    var bitmojiAvatarURL: String?
    
    var bitmojiSelfie: String?

    func authSetMissingUsername(user: User?) {
        if (user?.username == nil || (user?.username?.isEmpty ?? false)) {
            self.audioPlayer.stopPlayback()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.moveToProfile = false
                self.moveToFriends = false
                self.moveToHome = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.downloadAvatarURL { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.isOnboarding = true
                            self.onboardingStage = .ClaimUsername
                        }
                    }
                }
            }
        }
    }

    func getSnapchatInfo(callback: @escaping () -> Void) {
        snapchatLogin(onSuccess: {
            self.fetchSnapchatData { (externalId, displayName, bitmojiAvatarURL) in
                self.snapchatExternalId = externalId
                self.snapchatDisplayName = displayName
                self.bitmojiAvatarURL = bitmojiAvatarURL
                callback()
            }
        }, onError: {
            Logger.log("Error: getSnapchatInfo", log: .debug, type: .error)
        })
    }

    func snapchatLogin(onSuccess: @escaping () -> Void,
                       onError: @escaping () -> Void) {
        if let rootController = rootController {
            SCSDKLoginClient.login(from: rootController) { (success : Bool, error : Error?) in
                if let error = error {
                    Logger.log("snapchatLogin error: %{public}@", log: .debug, type: .error, error.localizedDescription)
                    onError()
                } else if !success {
                    onError()
                } else {
                    onSuccess()
                }
            }
        }
    }

    func fetchSnapchatData(onSuccess: @escaping (String, String, String) -> Void) {
        let graphQLQuery = "{me{externalId, displayName, bitmoji{avatar}}}"

        let variables = ["page": "bitmoji"]

        SCSDKLoginClient.fetchUserData(withQuery: graphQLQuery, variables: variables, success: { (resources: [AnyHashable: Any]?) in
          guard let resources = resources,
            let data = resources["data"] as? [String: Any],
            let me = data["me"] as? [String: Any] else { return }

            if let externalId = me["externalId"] as? String,
                let displayName = me["displayName"] as? String {
                
                var bitmojiAvatarUrl: String?
                if let bitmoji = me["bitmoji"] as? [String: Any] {
                  bitmojiAvatarUrl = bitmoji["avatar"] as? String
                }
                
                onSuccess(externalId, displayName, bitmojiAvatarUrl ?? "")
            }
        }, failure: { (error: Error?, isUserLoggedOut: Bool) in
            // handle error
            if let error = error {
                Logger.log("fetchSnapchatData error: %{public}@", log: .debug, type: .error, error.localizedDescription)
            }
            if isUserLoggedOut {}
        })
    }
    
    func fetchSelfie(onSuccess: @escaping (String?) -> Void) {
        let graphQLQuery = "{me{bitmoji{selfie}}}"

        SCSDKLoginClient.fetchUserData(withQuery: graphQLQuery, variables: nil, success: { (resources: [AnyHashable: Any]?) in
          guard let resources = resources,
            let data = resources["data"] as? [String: Any],
            let me = data["me"] as? [String: Any] else { return }

          var bitmojiSelfieUrl: String?
          if let bitmoji = me["bitmoji"] as? [String: Any] {
            bitmojiSelfieUrl = bitmoji["selfie"] as? String
          }
            
            onSuccess(bitmojiSelfieUrl)
        }, failure: { (error: Error?, isUserLoggedOut: Bool) in
            // handle error
        })
    }
    
    func color(user: User? = nil, sup: Sup? = nil) -> Color {
        if let user = user {
            return Color(user.color.color())
        } else if let sup = sup {
            return Color(sup.color.color())
        } else {
            return Color.clear
        }
    }
    
    func pcolor(user: User?, sup: Sup? = nil) -> Color {
        if let user = user {
            return Color(user.pcolor.color())
        } else if let sup = sup {
            return Color(sup.pcolor.color())
        } else {
            return Color.clear
        }
    }
    
    func scolor(user: User?, sup: Sup? = nil) -> Color {
        if let user = user {
            return Color(user.scolor.color())
        } else if let sup = sup {
            return Color(sup.scolor.color())
        } else {
            return Color.clear
        }
    }
    
    func uploadImage() {
        if let avatarURL = self.bitmojiAvatarURL {
            if let url = URL(string: avatarURL) {
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    guard let data = data, error == nil else { return }
                    DispatchQueue.main.async {
                        SupUserDefaults.saveBitmojiPhoto(photoData: data)
                        if let image = UIImage(data: data) {
                            let imageView = Image(uiImage: image)
                            self.bitmojiPhoto = imageView
                        }
                        if let image = UIImage(data: data) {
                            self.avatarImage = image
                            self.avatarPhoto = Image(uiImage: image)
                            
                            image.getColors { colors in
                                let color = colors?.background.hexString() ?? "#36383B"
                                let pcolor = colors?.primary.hexString() ?? "#FFFFFF"
                                let scolor = colors?.secondary.hexString() ?? "#FFFFFF"
                                
                                /// Upload Avatar Photo
                                DispatchQueue.global(qos: .background).async {
                                    User.updateImage(
                                    userID: self.currentUser?.uid,
                                    avatarPhoto: self.avatarImage,
                                    color: color,
                                    pcolor: pcolor,
                                    scolor: scolor
                                    ) { avatarUrl in
                                        let defaults = UserDefaults.standard
                                        defaults.set(nil, forKey: "color")
                                        if let currentUser = self.currentUser {
                                            let user = currentUser
                                            user.avatarUrl = avatarUrl
                                            user.color = color
                                            user.pcolor = pcolor
                                            user.scolor = scolor
                                            self.currentUser = user
                                            self.refreshGuestPassVideo()
                                            /// Upload Invite Photo
                                            self.uploadInviteImage() {}
                                        }
                                    }
                                }
                            }
                        }
                    }
                }.resume()
            }
        }
    }

    func downloadAvatarURL(callback: @escaping (Bool) -> Void) {
        guard let avatarURL = self.currentUser?.avatarUrl else {
            return callback(false)
        }
        guard let url = URL(string: avatarURL) else {
            return callback(false)
        }
        guard let data = try? Data(contentsOf: url) else {
            return callback(false)
        }

        DispatchQueue.main.async {
            SupUserDefaults.saveBitmojiPhoto(photoData: data)
            if let image = UIImage(data: data) {
                let imageView = Image(uiImage: image)
                self.bitmojiPhoto = imageView
            }
            if let image = UIImage(data: data) {
                self.avatarImage = image
                self.avatarPhoto = Image(uiImage: image)
            }
            return callback(true)
        }
    }

    func refreshGuestPassVideo() {
        if let currentUser = self.currentUser {
            GuestPassVideoGenerator.generate(user: currentUser) { result in
                switch result {
                case .success(let value):
                    Logger.log("Generating guest pass: %{public}@", log: .debug, type: .info, value.absoluteString)
                case .failure(let error):
                    Logger.log("Error generating guest pass: %{public}@", log: .debug, type: .error, error.localizedDescription)
                }
            }
        }
    }

    func uploadInviteImage(data: [String: Any] = [:], callback: @escaping () -> Void) {
        var data = data
        DispatchQueue.main.async {
            let inviteImage = InviteBannerImage().asImage()
            DispatchQueue.global(qos: .background).async {
                User.updateInviteImage(userID: self.currentUser?.uid, invitePhoto: inviteImage) { inviteBannerImageUrl in
                    if let currentUser = self.currentUser {
                        let user = currentUser
                        user.inviteBannerImageUrl = inviteBannerImageUrl
                        self.currentUser = user

                        let uuid = user.dynamicLinkUUID ?? UUID().uuidString
                        data["dynamicLinkUUID"] = uuid
                        user.dynamicLinkUUID = uuid
                        DynamicLinkCreator(uuid: uuid, user: user).call() { inviteURL in
                            if inviteURL != nil {
                                data["inviteURL"] = inviteURL!
                                user.inviteURL = inviteURL!
                            }
                            User.update(userID: user.uid, data: data)
                            self.currentUser = user
                            callback()
                        }
                    } else {
                        callback()
                    }
                }
            }
        }
    }

    func add(coins: Int, callback: @escaping (Bool) -> Void) {
        guard let username = self.currentUser?.username else { return }
        User.updateCoins(username: username, coins: coins) { _ in
            if let currentUser = self.currentUser {
                let user = currentUser
                user.coins = coins
                self.currentUser = user
            }
            callback(true)
        }
    }

    func saveComment(sup:Sup, comment:Comment? = nil, type:String, callback: @escaping (Comment) -> Void) {
        let uuid = UUID().uuidString
        let clips = self.audioRecorder.clips
        
        if type == "comment" || type == "reply" {
            /// Add Comment / Reply
            self.audioRecorder.saveComment(clips: clips, uuid: uuid) { commentURL, commentSize, commentDuration in
                self.createComment(sup: sup, comment: comment, type: type, commentURL: commentURL, callback: callback)
            }
        } else {
            /// Add Listen
            guard let userID = self.currentUser?.uid, userID != sup.userID else { return }
            if !self.allComments.contains(where: { $0.audioFile.absoluteString == sup.url.absoluteString }) {
                self.createComment(sup: sup, comment: comment, type: type, callback: callback)
            }
        }
    }
    
    func createComment(sup:Sup, comment:Comment? = nil, type:String, commentURL: URL? = nil, callback: @escaping (Comment) -> Void) {
        guard let userID = self.currentUser?.uid, let username = self.currentUser?.username, let avatarUrl = self.currentUser?.avatarUrl else { return }
        
        let today = Date()
        let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: today)
        
        Comment.create(userID: userID,
                       username: username,
                       avatarUrl: URL(string: avatarUrl)!,
                       supTitle: comment?.supTitle ?? sup.description,
                       supUsername: comment?.username ?? sup.username,
                       audioFile: commentURL ?? sup.url,
                       type: type,
                       expireAt: nextDate!,
                       callback: callback)
    }
    
    func photosPermissions(callback: @escaping (Bool) -> Void) {
        switch PHPhotoLibrary.authorizationStatus() {

        case .authorized:
            callback(true)
        case .denied, .restricted:
            callback(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { success in
                callback(success == .authorized ? true : false)
            }
        @unknown default:
            fatalError()
        }
    }
    
    func cameraPermissions(callback: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {

        case .authorized:
            callback(true)
        case .denied, .restricted:
            callback(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { success in
                callback(success)
            }
        @unknown default:
            fatalError()
        }
    }

    func micPermissions(callback: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {

        case .granted:
            callback(true)
        case .denied:
            callback(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { success in
                callback(success)
            }
        @unknown default:
            fatalError()
        }
    }

    func promptForPermissions() {
        let ac = UIAlertController(title: "Allow mic access", message: "To record we need your microphone. Please allow permissions in your iPhone settings.", preferredStyle: .alert)

        let openAction = UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let bundleId = Bundle.main.bundleIdentifier,
                let url = URL(string: "\(UIApplication.openSettingsURLString)&path=LOCATION/\(bundleId)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        ac.addAction(openAction)
        ac.addAction(cancelAction)

        let rootvc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        if let vc = rootvc {
            vc.present(ac, animated: true)
        }
    }

    func promptForPhotoPermissions() {
        let ac = UIAlertController(title: "Allow access to your photos", message: "To add a cover photo we need access to your photo library. Please allow permissions in your iPhone settings.", preferredStyle: .alert)

        let openAction = UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let bundleId = Bundle.main.bundleIdentifier,
                let url = URL(string: "\(UIApplication.openSettingsURLString)&path=LOCATION/\(bundleId)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        ac.addAction(openAction)
        ac.addAction(cancelAction)

        let rootvc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        if let vc = rootvc {
            vc.present(ac, animated: true)
        }
    }

    func promptForPushPermissions() {
        let ac = UIAlertController(title: "Turn on notifiations", message: "To be notified when a friend accepts your guest pass invite. Please allow permissions in your iPhone settings.", preferredStyle: .alert)

        let openAction = UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let bundleId = Bundle.main.bundleIdentifier,
                let url = URL(string: "\(UIApplication.openSettingsURLString)&path=LOCATION/\(bundleId)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }

        let cancelAction = UIAlertAction(title: "Close", style: .cancel, handler: nil)

        ac.addAction(openAction)
        ac.addAction(cancelAction)

        let rootvc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        if let vc = rootvc {
            vc.present(ac, animated: true)
        }
    }
    
    func updateListens(sup: Sup) {
        guard let username = self.currentUser?.username else { return }
        if username != sup.username {
            DispatchQueue.global(qos: .background).async {
                User.updateNOL(username: sup.username) { _ in }
            }
        }
    }

    @Published var selectedAlbum: EVPhotoKit.Album?
    @Published var selectedAlbumId: String? {
        willSet {
            if newValue != selectedAlbumId {
                self.updateSelectedAlbum(albumId: newValue)
            }
        }
    }
    var cachedImages = [String: UIImage]()

    func fetchPhotoAlbums(refresh: Bool = false) {
        EVPhotoKit.Albums.fetch { photoAlbums in
            DispatchQueue.main.async {
                self.albums = photoAlbums
                self.hasPhotoAccess = EVPhotoKit.Permissions.isVerified()
                self.selectedAlbumId = photoAlbums.first?.id
                self.fetchCoverPhotosForPhotoAlbums()
                if refresh {
                    self.updateSelectedAlbum(albumId: photoAlbums.first?.id)
                }
            }
        }
    }

    private func fetchCoverPhotosForPhotoAlbums() {
        DispatchQueue.global(qos: .background).async {
            self.albums.forEach { photoAlbum in
                photoAlbum.fetchCoverPhoto(
                    targetSize: CGSize.init(width: 200, height: 200)
                ) { photo in
                    DispatchQueue.main.async {
                        self.objectWillChange.send()
                        photoAlbum.coverPhoto = photo
                    }
                }
            }
        }
    }

    private func updateSelectedAlbum(albumId: String?) {
        self.selectedAlbum = self.albums.first(where: {
            $0.id == albumId
        })
        if self.selectedAlbum?.photos.count == 0 {
            self.selectedAlbum?.fetchPhotos()
        }
    }
}

final class NewSupState: ObservableObject {
    @Published var title: String = ""
}
