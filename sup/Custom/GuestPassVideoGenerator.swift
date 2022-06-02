//
//  GuestPassVideoGenerator.swift
//  sup
//
//  Created by Robert Malko on 7/16/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import AVFoundation
import Foundation
import VFCabbage

private let documentDirectory = FileManager.default.urls(
    for: .documentDirectory, in: .userDomainMask
)[0]
private let fileManager = FileManager.default

enum VideoGeneratorError: Error {
    case assetNotFound
    case exportSessionNil
    case outputURLNil
    case usernameNil
}

struct GuestPassVideoGenerator {
    static func generate(
        user: User,
        callback: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let username = user.username else {
            return callback(.failure(VideoGeneratorError.usernameNil))
        }
        guard let guestPassURL = Bundle.main.url(forResource: "guestPass-video", withExtension: "mp4") else {
            return callback(.failure(VideoGeneratorError.assetNotFound))
        }

        /* Resource */

        let badgeImage = SnapchatGuestPassVideo().asImage()
        let badgeCIImage = CIImage(cgImage: badgeImage.cgImage!)
        let badgeImageResource = ImageResource(
            image: badgeCIImage,
            duration: CMTime(seconds: 0.0)
        )

        let asset = AVAsset(url: guestPassURL)
        let duration = asset.duration.seconds
        let naturalSize = asset.tracks[0].naturalSize
        let guestPassResource = AVAssetTrackResource(asset: asset)

        /* TrackItem */

        let trackItem = TrackItem(resource: guestPassResource)
        trackItem.videoConfiguration.contentMode = .aspectFit
        trackItem.startTime = CMTime(seconds: 0.0)

        /* ImageCompositionProvider */

        let badgeImageCompositionProvider = ImageOverlayItem(resource: badgeImageResource)
        let badgeFrame = CGRect(x: 287, y: 710, width: 500, height: 430)
        badgeImageCompositionProvider.videoConfiguration.frame = badgeFrame

        let opacityConfig: KeyframeVideoConfiguration<OpacityKeyframeValue> = {
            let configuration = KeyframeVideoConfiguration<OpacityKeyframeValue>()
            let timeValues: [(Double, CGFloat)] = [
                (0.0, 0),
                (1.5, 0.0),
                (1.8, 1.0),
                (duration, 1.0)
            ]
            timeValues.forEach({ (time, value) in
                let keyframeValue = OpacityKeyframeValue()
                keyframeValue.opacity = value
                let keyframe = KeyframeVideoConfiguration.Keyframe(
                    time: CMTime(seconds: time, preferredTimescale: 600),
                    value: keyframeValue
                )
                configuration.insert(keyframe)
            })

            return configuration
        }()
        badgeImageCompositionProvider.videoConfiguration.configurations
            .append(opacityConfig)

        /* Timeline */

        let timeline = Timeline()
        timeline.videoChannel = [trackItem]
        timeline.audioChannel = [trackItem]
        timeline.renderSize = naturalSize
        timeline.passingThroughVideoCompositionProvider = badgeImageCompositionProvider

        /* CompositionGenerator */

        let compositionGenerator = CompositionGenerator(timeline: timeline)

        let _exportSession = compositionGenerator.buildExportSession(
            presetName: AVAssetExportPresetHighestQuality
        )

        guard let exportSession = _exportSession else {
            return callback(.failure(VideoGeneratorError.exportSessionNil))
        }

        let fileName = "guestpass_\(username).mp4"
        let outputURL = documentDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: outputURL)

        exportSession.outputURL = outputURL

        let start = CFAbsoluteTimeGetCurrent()
        exportSession.exportAsynchronously {
            let diff = CFAbsoluteTimeGetCurrent() - start
            if let error = exportSession.error {
                callback(.failure(error))
            } else if exportSession.outputURL != nil {
                print("GuestPassVideoGenerator: generated in \(diff) seconds.")
                callback(.success(exportSession.outputURL!))
            } else {
                return callback(.failure(VideoGeneratorError.outputURLNil))
            }
        }
    }
}
