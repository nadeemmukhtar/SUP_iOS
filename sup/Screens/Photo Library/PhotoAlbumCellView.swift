//
//  PhotoAlbumCellView.swift
//  sup
//
//  Created by Robert Malko on 11/17/19.
//  Copyright © 2019 Episode 8, Inc.. All rights reserved.
//

import Photos
import SwiftUI

struct PhotoAlbumCellView: View {
    let album: EVPhotoKit.Album
    @Binding var selectedAlbumId: String?

    var body: some View {
        ZStack {
            if album.coverPhoto != nil {
                Image(uiImage: album.coverPhoto!)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 38, alignment: .center)
                    .opacity(album.id == selectedAlbumId ? 1 : 0.3)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .saturation(album.id == selectedAlbumId ? 1 : 0.5)
                    .overlay(
                        Rectangle()
                            .frame(width: 102, height: 40)
                            .foregroundColor(album.id == selectedAlbumId ? Color.yellowAccentColor : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                )
                .shadow(color: Color.black, radius: 20, x: 0, y: 0)

            } else {
                Rectangle()
                    .frame(width: 100, height: 38)
                    .foregroundColor(Color.cardCellBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Text("\(album.title)".lowercased())
                .font(Font.custom(Font.textaAltHeavy, size: 17))
                .animation(.spring())
                .foregroundColor(album.id == selectedAlbumId ?
                    Color.backgroundColor : Color.primaryTextColor.opacity(0.6))
                .frame(width: 100, alignment: .center)
        }
        .scaleEffect(album.id == selectedAlbumId ? 1 : 0.9)
        .animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0))
        .onTapGesture {
            self.selectedAlbumId = self.album.id
        }
    }
}

struct PhotoAlbumCellView_Previews: PreviewProvider {
    static var previews: some View {
        let assetCollection = PHAssetCollection()
        let album = EVPhotoKit.Album(by: assetCollection)

        return PhotoAlbumCellView(
            album: album,
            selectedAlbumId: .constant("")
        )
    }
}
