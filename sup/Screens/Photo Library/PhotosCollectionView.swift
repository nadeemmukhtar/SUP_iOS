//
//  PhotosCollectionView.swift
//  sup
//
//  Created by Robert Malko on 11/17/19.
//  Copyright © 2019 Episode 8, Inc.. All rights reserved.
//

import ASCollectionView
import Photos
import SwiftUI

struct PhotosCollectionView: View {
    @Binding var albums: [EVPhotoKit.Album]
    @Binding var selectedAlbum: EVPhotoKit.Album?
    @Binding var selectedAlbumId: String?
    let topOffset: CGFloat
    let onImageTap: (PHAsset, UIImage?, CGRect) -> Void

    var body: some View {
        ASCollectionView {
            ASCollectionViewSection(
                id: 0,
                data: self.albums,
                dataID: \.self
            ) { album, info in
                PhotoAlbumCellView(
                    album: album,
                    selectedAlbumId: self.$selectedAlbumId
                )
            }

            ASCollectionViewSection(
                id: 1,
                data: self.selectedAlbum?.photos.reversed() ?? [],
                dataID: \.self
            ) { asset, _ in
                PhotoCellView(asset: asset, onImageTap: self.onImageTap)
            }
        }
        .layout { sectionID in
            switch sectionID {
            case 0:
                return CollectionLayoutSections.horizontal(
                    itemSize: CGSize(width: 100, height: 66),
                    insets: NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15),
                    spacing: 6
                )
            default:
                return CollectionLayoutSections.mosaicGrid()
            }
        }

        .scrollIndicatorsEnabled(false)
        .alwaysBounceVertical(true)
        .contentInsets(UIEdgeInsets(top: topOffset, left: 0, bottom: 140, right: 0))
    }
}
