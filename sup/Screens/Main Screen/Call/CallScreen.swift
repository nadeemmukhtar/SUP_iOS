//
//  CallScreen.swift
//  sup
//
//  Created by Justin Spraggins on 3/18/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Combine
import MessageUI
import PaperTrailLumberjack
import SDWebImageSwiftUI
import SwiftUI

private let onPresent$ = PassthroughSubject<Void, Never>()

struct CallScreen: View {
    @ObservedObject var state: AppState
    @State private var friends = [User]()
    @State private var friend = User(uid: "", displayName: "", email: "")
    @Binding var showLoader: Bool
    @State private var showingShare = false
    @State private var showInivteAlert = false
    @State private var showCopyAlert = false
    @State private var showCallAlert = false
    @State private var showFullAlert = false
    @State private var callBaseURL: String?
    @State private var sessionConnected = false
    @State private var recentGuests = false
    @State private var inviteOptions = false
    @State private var animateLoader = false
    var tapClose: (() -> Void)? = nil
    var onCallEnd: (() -> Void)? = nil

    var showShare: Bool {
        self.callBaseURL != nil && self.state.showingCallScreen && self.sessionConnected
    }

    private func callerMoveToCall() {
        self.state.audioPlayer.stopRingTone()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.state.isConnect = true
            self.state.guestSelected = false
            self.state.showQuestions = true
            self.state.isConnectHappyHour = false
            self.state.isConnecting = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if AppDelegate.isCaller {
                    self.state.callDidStart$.send(true)
                }
            }
        }
    }

    private func guestMoveToCall() {
        self.state.isConnecting = false
        self.state.isConnect = true
        self.state.showQuestions = true
        self.state.isConnectHappyHour = false
    }

    private func onRecordingStarted() {
        if AppDelegate.isCaller && AppDelegate.callSessionId != nil {
            SupAPI.startArchive(sessionId: AppDelegate.callSessionId!) { response in
                switch response {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.state.callArchiveId = response.id
                    }
                case .failure(let error):
                    // TODO: do something with UI
                    Logger.log("SupAPI.startArchive failure: %{public}@", log: .debug, type: .error, error.localizedDescription)
                }
            }
        }
    }

    var body: some View {
        ZStack {
            EmptyView()
        }
        .alert(isPresented: self.$showInivteAlert) {
            Alert(title: Text("invite link not ready"),
                  message: Text("once your invite link is ready you can invite your friends."),
                  dismissButton: .default(Text("👍👌"))
            )
        }
        .alert(isPresented: self.$showCallAlert) {
            Alert(title: Text("recording ended"),
                  message: Text("this recording has ended. start a new one by tapping the start button and inviting a friend to join."),
                  dismissButton: .default(Text("👍👌"))
            )
        }
        .alert(isPresented: self.$showFullAlert) {
            Alert(title: Text("recording full"),
                  message: Text("this recording is full."),
                  dismissButton: .default(Text("👍👌"))
            )
        }
        .onReceive(self.state.callNotActive$.eraseToAnyPublisher()) {
            self.showCallAlert = true
        }
        .onReceive(self.state.callNotAllowed$.eraseToAnyPublisher()) {
            self.showFullAlert = true
        }
        .onReceive(AppPublishers.callStatusUpdated$.eraseToAnyPublisher()) { callStatus in
            // Note we are already calling this on SupAPI.call if isCaller so I changed this to only call if user is not isCaller
            if !AppDelegate.isCaller {
                if callStatus == "end" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.state.isConnect = false
                    }
                }
            }
        }
        .onReceive(self.state.openTokSession$.eraseToAnyPublisher()) { openTokEvent in
            DDLogVerbose("onReceive - openTokSession$ openTokEvent=\(openTokEvent.description)")
            Logger.log("onReceive openTokEvent: %{public}@", log: .debug, type: .debug, openTokEvent.description)
            switch openTokEvent {
            case .subscriberDidConnect:
                DispatchQueue.main.async {
                    if AppDelegate.isCaller {
                        self.callerMoveToCall()
                    } else {
                        self.guestMoveToCall()
                    }
                }
            case .streamDestroyed:
                ()
            case .streamCreated:
                ()
            case .sessionDidDisconnect:
                ()
            case .sessionDidConnect:
                self.sessionConnected = true
            case .archiveStarted(_):
                Logger.log("CallScreen archiveStarted: %{public}@", log: .debug, type: .debug, AppDelegate.isCaller)
                if AppDelegate.isCaller {
                    self.state.audioRecorder.createCallClip(
                        filename: nil,
                        image: self.state.selectedUser?.avatarUrl,
                        userId: self.state.currentUser?.uid ?? ""
                    )
                }
            }
        }
    }
}

// MARK: The message part
extension CallScreen {
    private func presentSnapchat() {
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        SocialManager.sharedManager.postInviteToSnapchat(url: "\(self.callBaseURL!)", vc: vc)
    }
}

struct RecentGuestsCell: View {
    let image: String
    let username: String
    @Binding var isActive: Bool
    var tapSnap: (() -> Void)? = nil
    var tapIMessage: (() -> Void)? = nil

    var body: some View {
        HStack {
            WebImage(url: URL(string: image))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 46, height: 46)
                .padding(.bottom, 2)

            Text(username)
                .modifier(TextModifier(size: 18))

            Spacer()
            Button(action: { self.tapSnap?() }) {
                ZStack {
                    Circle()
                        .frame(width: 50, height: 50)
                        .foregroundColor(isActive ? Color.snapchatBaseColor : Color.backgroundColor.opacity(0.7))
                    Image("startcall-snapchat")
                        .renderingMode(.original)
                        .opacity(isActive ? 1 : 0.4)
                }
            }
            .buttonStyle(ButtonBounceLight())

            Button(action: { self.tapIMessage?() }) {
                ZStack {
                    Circle()
                        .frame(width: 50, height: 50)
                        .foregroundColor(isActive ? Color.greenBaseColor : Color.backgroundColor.opacity(0.7))
                    Image("startcall-imessage")
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .opacity(isActive ? 1 : 0.4)
                }
            }
            .buttonStyle(ButtonBounceLight())
        }
        .padding(.leading, 10)
        .padding(.trailing, 20)
        .frame(width: screenWidth - 30 , height: 90)
        .background(
            RoundedRectangle(cornerRadius: 27)
                .frame(width: screenWidth - 30 , height: 90)
                .foregroundColor(Color.cellBackground)
        )
    }
}
