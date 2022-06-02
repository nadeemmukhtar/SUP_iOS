//
//  PhotoCellView.swift
//  sup
//
//  Created by Robert Malko on 11/17/19.
//  Copyright © 2019 Episode 8, Inc.. All rights reserved.
//

import Photos
import SwiftUI

struct PhotoCellView: View {
    @State private var image: UIImage?
    @State private var pulsate = false
    @State private var showWaves = false
    let asset: PHAsset
    let onImageTap: (PHAsset, UIImage?, CGRect) -> Void

    func onAppear() {
        let options = PHImageRequestOptions()
        options.deliveryMode =
            PHImageRequestOptionsDeliveryMode.highQualityFormat
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 400, height: 400),
            contentMode: .aspectFill,
            options: options,
            resultHandler: { (image, info) in
                self.image = image
            }
        )
    }

    var body: some View {
        GeometryReader { geom in
            VStack {
                if self.image != nil {
                    Image(uiImage: self.image!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: geom.size.width,
                            height: geom.size.height,
                            alignment: .center
                        )
                        .clipped()
                } else {
                    Color.cardCellBackground
                }
            }.onAppear {
                self.onAppear()
            }.onTapGesture {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                let frame = geom.frame(in: .global)
                self.onImageTap(self.asset, self.image, frame)
            }
        }
    }
}
