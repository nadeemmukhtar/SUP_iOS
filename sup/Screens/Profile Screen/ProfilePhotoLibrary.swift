//
//  ProfilePhotoLibrary.swift
//  sup
//
//  Created by Justin Spraggins on 3/9/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import UIImageColors

struct ProfilePhotoLibrary: View {
    @ObservedObject var state: AppState
    @State private var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    var onClose: (() -> Void)? = nil
    var onComplete: () -> Void

    @State private var hasLoadedLibrary = false

    var body: some View {
        Logger.log("ProfilePhotoLibrary.body", log: .viewCycle, type: .info)
        DispatchQueue.main.async {
            self.hasLoadedLibrary = true
        }

        return ZStack {
            LibraryScreen(state: self.state, hasLoadedLibrary: self.hasLoadedLibrary) { selectedPhoto in
                self.onComplete()
                DispatchQueue.main.async {
                    self.state.avatarPhoto = Image(uiImage: selectedPhoto)
                    self.state.avatarImage = selectedPhoto
                }
                DispatchQueue.global(qos: .background).async {
                    if let pngData = selectedPhoto.jpegData(compressionQuality: 1) {
                        DispatchQueue.main.async {
                            self.state.avatarPhotoData = pngData
                        }
                        //TOdo: set avatar photo
                        SupUserDefaults.saveAvatarPhoto(photoData: pngData)
                        
                        selectedPhoto.getColors { colors in
                            let color = colors?.background.hexString() ?? "#36383B"
                            let pcolor = colors?.primary.hexString() ?? "#FFFFFF"
                            let scolor = colors?.secondary.hexString() ?? "#FFFFFF"
                            
                            /// Upload Avatar Photo
                            DispatchQueue.global(qos: .background).async {
                                User.updateImage(
                                userID: self.state.currentUser?.uid,
                                avatarPhoto: selectedPhoto,
                                color: color,
                                pcolor: pcolor,
                                scolor: scolor
                                ) { avatarUrl in
                                    if let currentUser = self.state.currentUser {
                                        let user = currentUser
                                        user.avatarUrl = avatarUrl
                                        user.color = color
                                        user.pcolor = pcolor
                                        user.scolor = scolor
                                        self.state.currentUser = user
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ProfilePhotoLibrary_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePhotoLibrary(state: AppState(), onComplete:{})
    }
}
