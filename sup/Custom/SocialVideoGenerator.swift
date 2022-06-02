//
//  SocialVideoGenerator.swift
//  sup
//
//  Created by Robert Malko on 6/9/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import AudioKit
import AVFoundation
import Foundation
import VFCabbage

enum VideoType {
    case square
    case vertical
    case horizontal
}

enum SocialVideoGeneratorError: Error {
    case exportSessionNil
    case outputURLNil
}

private let audioRecorder = AudioRecorder(ignoreFetch: true)
private let documentDirectory = FileManager.default.urls(
    for: .documentDirectory, in: .userDomainMask
)[0]
private let sampleRate = 48_000

struct SocialVideoGenerator {
    static func generate(
        type: VideoType,
        sup: Sup,
        isTiktok: Bool,
        startTime: Double,
        endTime: Double,
        callback: @escaping (Result<URL, Error>) -> Void
    ) {
        AKSettings.channelCount = 1
        AKSettings.sampleRate = 48000

        let scale = UIScreen.main.scale
        let duration = endTime - startTime
        let supPath = sup.url.absoluteString
        let height = type == .square ? screenWidth : screenHeight

        let backdropImage = self.backdropImage(type: type, sup: sup, isTiktok: isTiktok)
        let backdropCIImage = CIImage(cgImage: backdropImage.cgImage!)
        let backdropImageResource = ImageResource(
            image: backdropCIImage,
            duration: CMTime(seconds: duration)
        )
        let backdropImageTrackItem = TrackItem(resource: backdropImageResource)
        backdropImageTrackItem.videoConfiguration.contentMode = .aspectFit

        let centeredImage = self.centeredImage(type: type, sup: sup, isTiktok: isTiktok)
        let centeredCIImage = CIImage(cgImage: centeredImage.cgImage!)
        let centeredImageResource = ImageResource(
            image: centeredCIImage,
            duration: CMTime(seconds: 3, preferredTimescale: 600)
        )

        let centeredImageSize = (screenWidth - 110) * scale
        let centeredImageWidth = type == .square ? screenWidth * scale : centeredImageSize
        let centeredImageFrame = CGRect.init(
            x: type == .square ? 0 : ((screenWidth * scale) - centeredImageSize) / 2,
            y: type == .square ? 0 : (((screenHeight * scale) - centeredImageSize) / 2) + 85,
            width: centeredImageWidth,
            height: centeredImageWidth
        )

        let imageCompositionProvider = ImageOverlayItem(resource: centeredImageResource)
        imageCompositionProvider.startTime = CMTime(seconds: 0, preferredTimescale: 600)
        imageCompositionProvider.videoConfiguration.frame = centeredImageFrame;

        let transformKeyframeConfiguration: KeyframeVideoConfiguration<TransformKeyframeValue> = {
            let configuration = KeyframeVideoConfiguration<TransformKeyframeValue>()

            for i in 0 ..< Int(duration) {
                let d = (Double(i) * 3.0) - i
                let timeValues: [(Double, (CGFloat, CGFloat, CGPoint))] = [
                    (0.0 + d, (1.0, 0, CGPoint.zero)),
                    (1.0 + d, (1.1, CGFloat.pi / 20, CGPoint(x: 100, y: 80))),
                    (2.0 + d, (1.0, 0, CGPoint.zero))
                ]
                timeValues.forEach({ (time, value) in
                    let opacityKeyframeValue = TransformKeyframeValue()
                    opacityKeyframeValue.scale = value.0
                    let keyframe = KeyframeVideoConfiguration.Keyframe(
                        time: CMTime(seconds: time, preferredTimescale: 600),
                        value: opacityKeyframeValue
                    )
                    configuration.insert(keyframe)
                })
            }

            return configuration
        }()
        imageCompositionProvider.videoConfiguration.configurations.append(transformKeyframeConfiguration)

        audioRecorder.checkFileExists(withLink: supPath, includeLastPath: true) { audioURL in
            do {
                // try backdropImage.pngData()?.write(to: documentDirectory.appendingPathComponent("ui.png"))
                let file = try AKAudioFile(forReading: audioURL)
                let audioSnippet = try file.extracted(
                    fromSample: Int64(sampleRate * startTime),
                    toSample: Int64(sampleRate * endTime)
                )
                let audioAsset = AVAsset(url: audioSnippet.url)
                let supAudioResource = AVAssetTrackResource(asset: audioAsset)

                let supAudioTrackItem = TrackItem(resource: supAudioResource)
                supAudioTrackItem.audioConfiguration.volume = 1.0
                supAudioTrackItem.startTime = CMTime(seconds: 0.0)

                let timeline = Timeline()
                timeline.videoChannel = [backdropImageTrackItem]
                timeline.audioChannel = []
                timeline.overlays = []
                timeline.audios = [supAudioTrackItem]
                timeline.passingThroughVideoCompositionProvider = imageCompositionProvider
                timeline.renderSize = CGSize(width: screenWidth * scale, height: height * scale)

                let compositionGenerator = CompositionGenerator(timeline: timeline)
                let _exportSession = compositionGenerator.buildExportSession(
                    presetName: AVAssetExportPresetHighestQuality
                )

                guard let exportSession = _exportSession else {
                    return callback(.failure(SocialVideoGeneratorError.exportSessionNil))
                }

                let start = CFAbsoluteTimeGetCurrent()
                exportSession.exportAsynchronously {
                    let diff = CFAbsoluteTimeGetCurrent() - start
                    print("Took \(diff) seconds")
                    if let error = exportSession.error {
                        callback(.failure(error))
                    } else if exportSession.outputURL != nil {
                        callback(.success(exportSession.outputURL!))
                    } else {
                        return callback(.failure(SocialVideoGeneratorError.outputURLNil))
                    }
                }
            } catch let error {
                return callback(.failure(error))
            }
        }
    }

    private static func backdropImage(type: VideoType, sup: Sup, isTiktok: Bool) -> UIImage {
        var backdropImage: UIImage
        switch type {
        case .square:
            backdropImage = SquareVideoBackground(sup: sup).asImage()
        case .vertical:
            backdropImage = VerticalVideoBackground(sup: sup, isTikTok: isTiktok).asImage()
        case .horizontal:
            backdropImage = HorizontalVideoBackground(sup: sup).asImage()
        }

        return backdropImage
    }

    private static func centeredImage(type: VideoType, sup: Sup, isTiktok: Bool) -> UIImage {
        var centeredImage: UIImage
        switch type {
        case .square:
            centeredImage = SquareVideoCentered(sup: sup).asImage()
        case .vertical:
            centeredImage = VerticalVideoCentered(sup: sup, isTikTok: isTiktok).asImage()
        case .horizontal:
            centeredImage = HorizontalVideoCentered(sup: sup).asImage()
        }

        return centeredImage
    }
}
