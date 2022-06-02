//
//  TabBar.swift
//  sup
//
//  Created by Justin Spraggins on 8/7/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct TabBar: View {
    @ObservedObject var state: AppState
    @State var listenSelected = true
    @State var notificationSelected = false

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                BackgroundBlurView(style: .prominent)
                    .frame(width: screenWidth, height: isIPhoneX ? 96 : 74)

                VStack (spacing: isIPhoneX ? 0 : 5) {
                    HStack {
                        TabButton(image: "tab-headphones",
                                  action: {
                                    self.state.moveToProfile = false
                                    self.listenSelected = true
                                    self.notificationSelected = false
                                    self.state.showNotifications = false
                        })
                            .opacity(self.listenSelected ? 1 : 0.6)
                            .animation(.easeInOut(duration: 0.3))
                        Spacer()
                        TabButton(image: "tab-notification",
                                  action: {
                                    self.state.moveToProfile = false
                                    self.state.showNotifications = true
                                    self.listenSelected = false
                                    self.notificationSelected = true
                        })
                            .opacity(self.notificationSelected ? 1 : 0.6)
                            .animation(.easeInOut(duration: 0.3))
                        Spacer()

                        ZStack {
                            Spacer().frame(width: 50, height: 50)
                            ProfileAvatar(state: state,
                                                      currentUser: .constant(true),
                                                      tapAction: {
                                                        self.state.moveToProfile = true
                                                        self.listenSelected = false
                                                        self.notificationSelected = false
                                                        self.state.showNotifications = false
                                        },
                                                      size: 36)
                        }
                    }
                    .padding(.horizontal, 20)

                    HStack {
                        if self.state.moveToProfile {
                            Spacer()
                        }

                        if isIPhoneX  {
                            ZStack {
                                Spacer().frame(width: 50)
                                Circle()
                                    .frame(width: 7, height: 7)
                                    .foregroundColor(.white)
                            }
                        } else {
                            Rectangle()
                                .frame(width: 50, height: 4)
                                .foregroundColor(.white)
                        }

                        if self.listenSelected {
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, isIPhoneX ? 26 : 6)
            }
        }
    }
}

struct TabButton: View {
    var image: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            ZStack {
                Rectangle()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.black.opacity(0.0001))
                Image(image)
            }
        }
        .buttonStyle(ButtonBounce())
    }

}
