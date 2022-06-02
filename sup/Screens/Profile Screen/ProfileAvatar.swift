//
//  ProfileAvatar.swift
//  sup
//
//  Created by Justin Spraggins on 3/6/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProfileAvatar: View {
    @ObservedObject var state: AppState
    @Binding var currentUser: Bool
    var tapAction: (() -> Void)? = nil
    var size: CGFloat = 44

    private var avatarImage: Image {
        if let avatarImage = self.state.avatarImage {
            return Image(uiImage: avatarImage)
        }

        return self.state.avatarPhoto
    }

    private var avatarWebImage: WebImage? {
        if let url = self.state.currentUser?.avatarUrl {
            guard let url = URL(string: url) else { return nil }
            return WebImage(url: url)
        }

        return nil
    }

    private var selectedAvatarImage: WebImage? {
        if let url = self.state.selectedUser?.avatarUrl {
            guard let url = URL(string: url) else { return nil }
            return WebImage(url: url)
        }

        return nil
    }

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.tapAction?()
        }) {
            ZStack {
                if currentUser {
                    if self.state.bitmojiPhoto != nil {
                        self.state.bitmojiPhoto!
                            .resizable()
                            .renderingMode(.original)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    } else if self.state.avatarImage != nil {
                        Image(uiImage: self.state.avatarImage!)
                            .resizable()
                            .renderingMode(.original)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    } else if self.avatarWebImage != nil {
                        self.avatarWebImage!
                            .resizable()
                            .renderingMode(.original)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    } else {
                        self.avatarImage
                            .resizable()
                            .renderingMode(.original)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    }
                } else {
                    if self.selectedAvatarImage != nil {
                        self.selectedAvatarImage!
                            .resizable()
                            .renderingMode(.original)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .buttonStyle(ButtonBounce())
    }
}


struct EndCallAvatar: View {
    @ObservedObject var state: AppState
    @Binding var currentUser: Bool
    var changeAvatar: (() -> Void)? = nil

    private var avatarImage: Image {
        if let avatarImage = self.state.avatarImage {
            return Image(uiImage: avatarImage)
        }

        return self.state.avatarPhoto
    }

    private var avatarWebImage: WebImage? {
        if let url = self.state.currentUser?.avatarUrl {
            guard let url = URL(string: url) else { return nil }
            return WebImage(url: url)
        }

        return nil
    }

    private var selectedAvatarImage: WebImage? {
        if let url = self.state.selectedUser?.avatarUrl {
            guard let url = URL(string: url) else { return nil }
            return WebImage(url: url)
        }

        return nil
    }

    var body: some View {
            ZStack {
                if currentUser {
                    if self.state.avatarImage != nil {
                        Image(uiImage: self.state.avatarImage!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 78, height: 78)

                    } else if self.avatarWebImage != nil {
                        self.avatarWebImage!
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 78, height: 78)
                    } else {
                        self.avatarImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 78, height: 78)
                    }
                } else {
                    if self.selectedAvatarImage != nil {
                        self.selectedAvatarImage!
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 78, height: 78)
                    }
                }
            }
    }
}

