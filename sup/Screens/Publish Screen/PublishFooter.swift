//
//  PublishFooter.swift
//  sup
//
//  Created by Justin Spraggins on 2/21/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct PublishFooter: View {
    @ObservedObject var state: AppState
    @State var pulsate = false
    @Binding var editStage: Bool
    @Binding var doneStage: Bool
    @Binding var isPrivate: Bool
    @State private var deleteActionSheet = false
    @State private var lockActionSheet = false
    @State private var uploadCoverAlert = false
    var tapChangePhoto: (() -> Void)? = nil
    var tapDelete: (() -> Void)? = nil
    var tapSave: (() -> Void)? = nil
    var tapDone: (() -> Void)? = nil

    var disabledPublish: Bool {
        state.showPublish && !self.state.isCallArchived
    }

    let baseColor: Color

    var body: some View {
        ZStack {
            HStack (spacing: 20) {
                    Button(action: {
                        impact(style: .soft)
                        self.deleteActionSheet = true
                    }) {
                        ZStack {
                            Color.white.opacity(0.1)
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                            Image("player-trash")
                                .renderingMode(.template)
                                .foregroundColor(Color.primaryTextColor.opacity(0.8))
                                .animation(nil)
                        }
                    }
                    .buttonStyle(ButtonBounce())
                    .opacity(editStage ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3))
                    .scaleEffect(editStage ? 1 : 0.01)
                    .animation(.spring())
                    .actionSheet(isPresented: $deleteActionSheet) {
                        ActionSheet(title: Text(""),
                                    message: Text("Are you sure your want to delete your sup?"),
                                    buttons: [
                                        .destructive(Text("Delete")) { self.tapDelete?() },
                                        .cancel()
                        ])
                    }

                Button(action: {
                    if self.state.selectedPrompt?.image != nil || self.state.coverPhotoData != nil {
                        self.tapSave?()
                    } else {
                        self.uploadCoverAlert = true
                    }
                }) {
                    ZStack {
                        Spacer().frame(width: 160, height: 58)
                        Color.white.opacity(0.2)
                            .frame(width: 168, height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                        if editStage && disabledPublish {
                           LoaderCircle(size: 20, innerSize: 20, isButton: true, tint: Color.white)
                        } else {
                            Text("save")
                                .modifier(TextModifier(size: 22, font: Font.textaAltBlack, color: Color.primaryTextColor))
                                .padding(.bottom, 3)
                        }
                    }
                }
                .buttonStyle(ButtonBounce())
                .opacity(editStage ? 1 : 0)
                .animation(.easeInOut(duration: 0.3))
                .scaleEffect(editStage ? 1 : 0.9)
                .animation(.spring())
                .alert(isPresented: self.$uploadCoverAlert) {
                    Alert(
                        title: Text("Upload cover photo"),
                        message: Text("To save your sup you first need to upload a cover photo."),
                        dismissButton: .default(Text("👍👌"))
                    )
                }

                if self.state.isAdmin {
                    Button(action: {
                        impact(style: .soft)
                        self.lockActionSheet = true
                    }) {
                        ZStack {
                            BackgroundBlurView(style: .prominent)
                                .frame(width: 56, height: 56)
                                .overlay(isPrivate ? Color.white : Color.clear)
                                .clipShape(Circle())
                            Image(isPrivate ? "lock-locked" : "lock-unlocked")
                                .renderingMode(.template)
                                .foregroundColor(isPrivate ? Color.black : Color.primaryTextColor.opacity(0.8))
                                .animation(nil)
                        }
                    }
                    .buttonStyle(ButtonBounce())
                    .opacity(editStage ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3))
                    .scaleEffect(editStage ? 1 : 0.01)
                    .animation(.spring())
                    .actionSheet(isPresented: $lockActionSheet) {
                        ActionSheet(title: Text(self.isPrivate ? "unlock" : "lock"),
                                    message: Text(self.isPrivate ? "Are you sure you want to unlock your sup? This will allow your friends and anyone viewing your profile to listen to your sup." : "Are you sure your want to lock your sup? This will make it only visible for you and the guests."),
                                    buttons: [
                                        .destructive(Text(self.isPrivate ? "Make public" : "Make private")) { self.isPrivate.toggle() },
                                        .cancel()
                        ])
                    }
                }
            }

            Button(action: { self.tapDone?()}) {
                ZStack {
                    BackgroundBlurView(style: .prominent)
                        .frame(width: 162, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    Text("close")
                        .modifier(TextModifier(size: 22, font: Font.textaAltBlack, color: Color.primaryTextColor))
                        .padding(.bottom, 3)
                }
            }
            .buttonStyle(ButtonBounce())
            .opacity(doneStage ? 1 : 0)
            .animation(.easeInOut(duration: 0.3))
            .scaleEffect(doneStage ? 1 : 0.9)
            .animation(.spring())
        }
    }
}
