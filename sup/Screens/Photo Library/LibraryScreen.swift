//
//  LibraryScreen.swift
//  sup
//
//  Created by Justin Spraggins on 11/12/19.
//  Copyright © 2019 Episode 8, Inc.. All rights reserved.
//

import Photos
import SwiftUI

struct LibraryScreen: View {
    @ObservedObject var state: AppState

    @State private var hasPhotoAccess: Bool =
        EVPhotoKit.Permissions.isVerified()
    @State private var selectedImage: UIImage?

    var onDone: ((UIImage) -> Void)? = nil

    init(state: AppState, hasLoadedLibrary: Bool, onDone: ((UIImage) -> Void)? = nil) {
        self.state = state
        self.onDone = onDone

        if !hasLoadedLibrary {
            Logger.log("LibraryScreen.init", log: .viewCycle, type: .info)
            state.fetchPhotoAlbums()
        }
    }

    private func askForPhotosPermission() {
        self.hasPhotoAccess = EVPhotoKit.Permissions.isVerified()
        state.fetchPhotoAlbums()
    }

    private func onImageTap(asset: PHAsset, image: UIImage?, frame: CGRect) {
        self.getMaxSizeImage(asset: asset) { image in
            self.selectedImage = image
            if let image = image {
                self.onDone?(image)
            }
        }
    }

    private func getMaxSizeImage(asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode =
            PHImageRequestOptionsDeliveryMode.highQualityFormat
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFill,
            options: options,
            resultHandler: { (image, info) in
                completion(image)
            }
        )
    }

    var body: some View {
        ZStack {
            VStack {
                if self.state.hasPhotoAccess {
                    PhotosCollectionView(
                        albums: self.$state.albums,
                        selectedAlbum: self.$state.selectedAlbum,
                        selectedAlbumId: self.$state.selectedAlbumId,
                        topOffset: isIPhoneX ? 160 : 105,
                        onImageTap: self.onImageTap
                    )
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        let state = AppState()
        return LibraryScreen(state: state, hasLoadedLibrary: false)
    }
}
