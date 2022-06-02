//
//  FriendsScreen.swift
//  sup
//
//  Created by Justin Spraggins on 5/15/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct FriendsScreen: View {
    @ObservedObject var state: AppState
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    @State private var featuredSups: [Sup]? = nil
    @State private var friendlatestSups = [Sup]()
    @State private var userProfileSups = [Sup]()
    @State private var friends = [User]()
    @State private var friend = User(uid: "", displayName: "", email: "")
    @State private var loadingURL: URL? = nil
    
    let aDummySup = Sup(
        id: "dummy",
        description: "",
        userID: "",
        username: "",
        url: URL(string: "https://www.google.com")!,
        coverArtUrl: URL(string: "https://www.google.com")!,
        avatarUrl: URL(string: "https://www.google.com")!,
        size: 0,
        duration: 0,
        channel: "",
        color: "#36383B",
        pcolor: "#FFFFFF",
        scolor: "#FFFFFF",
        created: Date(),
        guests: [],
        guestAvatars: [],
        tags: [],
        isPrivate: false
    )

    private func recentSups(sups: [Sup]) -> [Sup] {
        return sups.sorted(by: {
            $0.created.compare($1.created) == .orderedDescending
        })
    }
    private func initUserProfile() {
        if let _ = self.state.selectedSup {

        } else if let sup = self.friendlatestSups.first {
            DispatchQueue.main.async {
                self.state.selectedSup = sup
                //self.getUserProfile()
                self.updatePlayedSups(sup: sup)
            }
        }
    }

    private func deinitUserProfile() {
        self.friendlatestSups.removeAll()
        self.userProfileSups.removeAll()
        //self.state.selectedUser = nil
        self.state.selectedSup = nil
    }

    private func getUserProfile() {
        guard let userID = self.state.selectedSup?.userID else { return }
        guard let username = self.state.selectedSup?.username else { return }
        User.get(username: username) { user in
            self.state.selectedUser = user

            Sup.all(userID: userID, username: username) { sups in
                self.userProfileSups = self.recentSups(sups: sups)
            }
        }
    }

    private func updatePlayedSups(sup: Sup) {
        guard let userID = self.state.currentUser?.uid else { return }
        guard var playedSups = self.state.currentUser?.playedSups else { return }
        guard var latestSups = self.state.currentUser?.latestSups else { return }

        playedSups.append(sup.id)
        latestSups = latestSups.filter({ $0 != sup.id })

        User.update(userID: userID, data: ["playedSups": playedSups, "latestSups": latestSups]) { updated in
            if updated {
                let user = self.state.currentUser
                user?.playedSups = playedSups
                user?.latestSups = latestSups
                self.state.currentUser = user
            }
        }
    }

    private func hasPlayed(sup: Sup) -> Bool {
        guard let playedSups = self.state.currentUser?.playedSups else { return false }
        return playedSups.contains(sup.id)
    }

    private func getFriends() {
        guard let username = self.state.currentUser?.username else { return }
        Friend.get(username: username) { friend in
            if let friend = friend, friend.friendnames.isNotEmpty {
                // TODO: Think of new solution later for handling > 10 friends
                // Firebase allows only a max of 10 with in: query
                User.all(usernames: friend.friendnames) { users in
                    self.friends = users
                    self.state.friends = users
                }
            }
        }
    }

    private func getFeaturedSups() {
        Sup.featured { sups in
            self.featuredSups = sups
        }
    }
    
    private func addSupAsFriend(friends: [String], callback: @escaping ([String]) -> Void) {
        var friends = friends
        let supusername = "sup"
        if friends.contains(supusername) {
            callback(friends)
        } else {
            guard let username = self.state.currentUser?.username else { return }
            Friend.create(username: username, friendnames: [supusername]) { friend in
                friends.append(supusername)
                callback(friends)
            }
        }
    }

    // TODO: Optimize this later
    // This loads only once, and never refreshes
    private func getFriendSups() {
        guard let username = self.state.currentUser?.username else { return }
        Friend.get(username: username) { friend in
            if let friend = friend {
                self.addSupAsFriend(friends: friend.friendnames) { friendnames in
                    // TODO: Think of new solution later for handling > 10 friends
                    // Firebase allows only a max of 10 with in: query
                    Sup.allPublic(usernames: friendnames) { sups in
                        /// Friends Latest Sups
                        var friendlatestSups = [Sup]()
                        for friendname in friendnames {
                            var friendSup = sups.filter({ $0.username == friendname })
                            friendSup = self.recentSups(sups: friendSup)
                            if let sup = friendSup.first {
                                friendlatestSups.append(sup)
                            }
                        }
                        
                        /// Downsizing images
                        var optimizedSups = [Sup]()
                        for sup in friendlatestSups {
                            var sup = sup
                            let avatarUrl = sup.avatarUrl.absoluteString.replacingOccurrences(of: "_636x636.png?", with: "_210x210.png?")
                            if let url = URL(string: avatarUrl) {
                                sup.avatarUrl = url
                            }
                            
                            let coverArtUrl = sup.coverArtUrl.absoluteString.replacingOccurrences(of: "_636x636.png?", with: "_636x636.png?")
                            if let url = URL(string: coverArtUrl) {
                                sup.coverArtUrl = url
                            }
                            
                            var optimizedGuests = [String]()
                            for guest in sup.guestAvatars {
                                let guest = guest.replacingOccurrences(of: "_636x636.png?", with: "_210x210.png?")
                                optimizedGuests.append(guest)
                            }
                            sup.guestAvatars = optimizedGuests

                            optimizedSups.append(sup)
                        }

                        friendlatestSups = self.recentSups(sups: optimizedSups)
                        
                        /// Trick to manage Grid adding dummy sup to make Even number
                        if friendlatestSups.isNotEmpty && friendlatestSups.count % 2 != 0 {
                            friendlatestSups.append(self.aDummySup)
                        }
                        
                        self.friendlatestSups = friendlatestSups

                        /// Latest Sups
                        DispatchQueue.global(qos: .background).async {
                            var latestSups = friendlatestSups.map({ $0.id })

                            if let playedSups = self.state.currentUser?.playedSups {
                                latestSups = latestSups.filter({ !playedSups.contains($0) })
                            }

                            guard let userID = self.state.currentUser?.uid else { return }
                            User.update(userID: userID, data: ["latestSups": latestSups]) { updated in
                                if updated {
                                    let user = self.state.currentUser
                                    user?.latestSups = latestSups
                                    self.state.currentUser = user
                                }
                            }
                        }

                        if self.friendlatestSups.isNotEmpty {
                            /// First User Profile
                            self.initUserProfile()
                        } else {
                            /// Reset Profiel
                            self.deinitUserProfile()
                        }
                    }
                }
            } else {
                /// Reset Profiel
                self.deinitUserProfile()
            }
        }
    }
    
    var rows: Int {
        friendlatestSups.count / 2 + friendlatestSups.count % 2
    }
    
    var columns: Int {
        2
    }

    func item(_ row: Int, _ column: Int) -> Sup {
        friendlatestSups[row * columns + column]
    }
    
    func valid(_ row: Int, _ column: Int) -> Bool {
        friendlatestSups[row * columns + column].id != "dummy"
    }

    private func showRecents() {
        self.state.showRecents = true
        self.state.animateRecents = true
    }

    private func showFollowingCard() {
        impact(style: .soft)
        self.state.showMediaPlayerDrawer = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.state.showFollowingCard = true
        }
    }
    
    var body: some View {
       ScrollView(showsIndicators: false) {
            VStack (spacing: 10) {
                Spacer().frame(height: isIPhoneX ? 144 : 98)
                if self.friendlatestSups.isNotEmpty {
                    ForEach(0 ..< self.rows, id: \.self) { row in
                        HStack (spacing: 10) {
                            ForEach(0 ..< self.columns, id: \.self) { column in
                                FriendCell(
                                    state: self.state,
                                    hasPlayed: self.hasPlayed(sup: self.item(row, column)),
                                    url: self.item(row, column).url,
                                    image: self.item(row, column).avatarUrl,
                                    cover: self.item(row, column).coverArtUrl,
                                    username: self.item(row, column).username,
                                    description: self.item(row, column).description,
                                    sup: self.item(row, column),
                                    isSelected: self.state.selectedUser?.username == self.item(row, column).username,
                                    tapAvatar: { sup in
                                        DispatchQueue.main.async() {
                                            self.state.selectedSup = sup
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                self.state.showMediaPlayer = true
                                            }
                                            if self.state.selectedSup != sup {
                                                self.getUserProfile()
                                                self.updatePlayedSups(sup: sup)
                                            }
                                        }
                                })
                                    .opacity(self.valid(row, column) ? 1 : 0)
                            }
                        }
                        .frame(height: screenWidth/2 + 10)
                    }
                    .frame(height: screenWidth/2 + 10)
                } else {
                    ForEach(0..<1) { value in
                        CallPlaceholderLoading()
                    }
                }
            }

            if self.friends.count <= 9 {
                AddFriendCell(state: self.state)
                .padding(.top, 30)
                .padding(.bottom, 10)

                if self.friends.count >= 0 {
                    Spacer().frame(height: 5)
                    Button(action: { self.showFollowingCard() }) {
                        Text("following \(self.friends.count)")
                            .modifier(TextModifier(size: 17, font: Font.textaAltBlack, color: Color.yellowAccentColor))
                       }
                }
                Text("\(9 - self.friends.count) more friends to follow")
                    .modifier(TextModifier(size: 17, font: Font.textaAltBold, color: Color.secondaryTextColor))
            }
            
            /// Bottom Spacing
            Spacer().frame(width: screenWidth, height: isIPhoneX ? 170 : 150)
            Spacer()
        }
        .onReceive(self.state.userDidLoad$.eraseToAnyPublisher(), perform: { _ in
            self.getFriendSups()
            self.getFriends()
        })
        .onReceive(self.state.friendDidAdd.eraseToAnyPublisher()) { _ in
            self.getFriendSups()
            self.getFriends()
        }
        .onReceive(self.state.$moveToFriends) { isFriends in
            if isFriends {
                self.getFriendSups()
                self.getFriends()
            }
        }
    }
}

struct TextHeader: View {
    var text: String
    var button: String = ""
    var showButton: Bool = false
    var tapAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(text)
                .modifier(TextModifier(size: 22))
            Spacer()
            if showButton {
                Button(action: { self.tapAction?() }){
                    Text(button)
                        .modifier(TextModifier(size: 18, color: Color.yellowAccentColor))
                        .frame(height: 40)
                }
            .buttonStyle(ButtonBounceLight())
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 5)
        .frame(width: screenWidth, height: 34)
    }
}

