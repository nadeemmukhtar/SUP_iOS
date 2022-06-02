//
//  CoverPhotoLibrary.swift
//  sup
//
//  Created by Justin Spraggins on 5/4/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import UIImageColors

struct CoverPhotoLibrary: View {
    @ObservedObject var state: AppState
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    var tapRefresh: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil
    var onComplete: () -> Void

    @State private var hasLoadedLibrary = false

    var body: some View {
        Logger.log("CoverPhotoLibrary.body", log: .viewCycle, type: .info)
        DispatchQueue.main.async {
            self.hasLoadedLibrary = true
        }

        return ZStack {
            LibraryScreen(state: self.state, hasLoadedLibrary: self.hasLoadedLibrary) { selectedPhoto in
                self.onComplete()
                DispatchQueue.main.async {
                    self.state.coverPhoto = Image(uiImage: selectedPhoto)

                    selectedPhoto.getColors { colors in
                        self.state.coverColor = colors?.background
                        self.state.primaryColor = colors?.primary
                        self.state.secondaryColor = colors?.secondary
                    }
                }
                DispatchQueue.global(qos: .background).async {
                    if let pngData = selectedPhoto.pngData() {
                        DispatchQueue.main.async {
                            if let coverPhotoHash = SupUserDefaults.coverPhotoHash() {
                                self.state.coverPhotoChanged =
                                    coverPhotoHash != pngData.toHash()
                            }
                            self.state.coverPhotoData = pngData
                        }
                        SupUserDefaults.saveCoverPhoto(photoData: pngData)
                    }
                }
            }
            .opacity(self.state.showPhotoLibrary ? 1 : 0)
            .animation(.easeInOut(duration: 0.3))

            VStack {
                Spacer().frame(height: isIPhoneX ? 40 : 18)
                HStack {
                    Text("change cover")
                        .modifier(TextModifier(size: 22, font: Font.ttNormsBold, color: .white))
                        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 0)
                        .opacity(self.state.showPhotoLibrary ? 1 : 0)
                    Spacer()

                    TintImageButton(image: "nav-refresh",
                                    width: 50,
                                    height: 50,
                                    corner: 25,
                                    background: Color.clear,
                                    tint: Color.white,
                                    blur: true,
                                    action: { self.tapRefresh?() })
                        .scaleEffect(self.state.showPhotoLibrary ? 1 : 0)

                    TintImageButton(image: "nav-close",
                                    width: 50,
                                    height: 50,
                                    corner: 25,
                                    background: Color.clear,
                                    tint: Color.white,
                                    blur: true,
                                    action: { self.onClose?() })
                    .scaleEffect(self.state.showPhotoLibrary ? 1 : 0)
                }
                .frame(width: screenWidth - 38)
                Spacer()
            }
        .frame(width: screenWidth, height: screenHeight)

        }
    }
}
