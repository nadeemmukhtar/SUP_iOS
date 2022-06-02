//
//  Debug.swift
//  sup
//
//  Created by Robert Malko on 4/11/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation
import AVFoundation
import mobileffmpeg
import VFCabbage

struct Debug {
    static func testAudio(state: AppState) {
        print("Debug.testAudio")
        let audioRecorder = AudioRecorder()
        let callArchiveId = "7795105a-67d4-40f9-b994-6fe4afdfe3da"
        let baseURL = "https://sup-archives.s3.us-east-2.amazonaws.com/46602742"
        let url = "\(baseURL)/\(callArchiveId)/archive.mp4"
        let documentDirectory = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        )[0]
        audioRecorder.checkFileExists(withLink: url, includeLastPath: true) { audioUrl in
            audioRecorder.createCallClip(
                filename: audioUrl,
                image: state.selectedUser?.avatarUrl,
                userId: state.currentUser?.uid ?? ""
            )
            let fileList: String = audioRecorder.clips.compactMap { clip in
                if let fileURL = clip.fileURL {
                    return "file '\(fileURL)'"
                }
                return nil
            }.joined(separator: "\n")
            let filename = documentDirectory.appendingPathComponent("sup_file_list.txt")
            do {
                try fileList.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("error writing file")
            }
            let outputFile = documentDirectory.appendingPathComponent("concat.m4a")
            MobileFFmpegConfig.setLogLevel(AV_LOG_QUIET)
            MobileFFmpeg.execute("-f concat -safe 0 -i \(filename) -c copy -y \(outputFile)")
            print("File saved at \(outputFile)")
        }
    }

    static func testVideoGeneration(state: AppState) {
        print("Debug.testVideoGeneration")

        let now = Date()
        let sup = Sup(
            id: "", description: "", userID: "", username: "",
            url: URL(string: "")!, coverArtUrl: URL(string: "")!, avatarUrl: URL(string: "")!,
            size: 0, duration: 0, channel: "",
            color: "", pcolor: "", scolor: "", created: now,
            guests: [], guestAvatars: [], tags: [], isPrivate: false
        )
        let backdropView = VerticalVideoBackground(sup: sup, isTikTok: true)
        let backdropImage = backdropView.asImage()
        let backdropCIImage = CIImage(cgImage: backdropImage.cgImage!)
        let soundWavesImage = UIImage(named: "soundwaves.gif")!
        let soundWavesCIImage = CIImage(cgImage: soundWavesImage.cgImage!)

        // 1. Create resources
        let placeholderAsset: AVAsset = AVAsset(url: Bundle.main.url(forResource: "placeholder", withExtension: "mp4")!)
        let placeholderResource = AVAssetTrackResource(asset: placeholderAsset)
        let startedAsset: AVAsset = AVAsset(url: Bundle.main.url(forResource: "getstarted", withExtension: "mp4")!)
        let startedResource = AVAssetTrackResource(asset: startedAsset)
        // let soundWavesAsset: AVAsset = AVAsset(url: Bundle.main.url(forResource: "soundwaves", withExtension: "gif")!)
        // let soundWavesResource = AVAssetTrackResource(asset: soundWavesAsset)
        let soundWavesResource = ImageResource(image: soundWavesCIImage, duration: CMTime(seconds: 15.0))
        let backdropImageResource = ImageResource(image: backdropCIImage, duration: CMTime(seconds: 15.0))

        // 2. Create a TrackItem instance, TrackItem can configure video&audio configuration
        let placeholderTrackItem = TrackItem(resource: placeholderResource)
        placeholderTrackItem.videoConfiguration.contentMode = .aspectFill
        let startedTrackItem = TrackItem(resource: startedResource)
        startedTrackItem.videoConfiguration.frame = CGRect(x: 50, y: 50, width: 480/2, height: 360/2)
        startedTrackItem.startTime = CMTime(seconds: 1.5)
        startedTrackItem.videoConfiguration.opacity = 0.5
        startedTrackItem.videoConfiguration.contentMode = .aspectFill
        let soundWavesTrackItem = TrackItem(resource: soundWavesResource)
        soundWavesTrackItem.startTime = CMTime(seconds: 0.0)
        let backdropImageTrackItem = TrackItem(resource: backdropImageResource)

        // 3. Add TrackItem to timeline
        let timeline = Timeline()
        timeline.videoChannel = [backdropImageTrackItem] // channels at end appear first in timeline
        timeline.audioChannel = []
        timeline.overlays = [soundWavesTrackItem]
        timeline.renderSize = CGSize(width: screenWidth, height: screenHeight)

        // 4. Use CompositionGenerator to create AVAssetExportSession/AVAssetImageGenerator/AVPlayerItem
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let exportSession = compositionGenerator.buildExportSession(presetName: AVAssetExportPresetMediumQuality)
        let playerItem = compositionGenerator.buildPlayerItem()
        let imageGenerator = compositionGenerator.buildImageGenerator()
        exportSession?.exportAsynchronously {
            print("exported")
        }
    }

    static func testSupCall(state: AppState) {
        print("Debug.testSupCall")
        guard let username = state.currentUser?.username else {
            print("Debug.testSupCall error: username does not exist")
            return
        }

        SupAPI.call(json: ["from": username]) { response in
            switch response {
            case .success(let response):
                print("Debug.testSupCall api success", response)
                DispatchQueue.main.async {
                    state.callBaseURL = FirebaseCall.callJoinURL(
                        sessionId: response.sessionId
                    )
                }
                AppDelegate.isCaller = true
                AppDelegate.callSessionId = response.sessionId
                AppDelegate.callToken = response.token
                AppDelegate.callListener?.remove()
                AppDelegate.callListener = FirebaseCall.listenToCall(sessionId: response.sessionId) { (callStatus, startTime) in
                    print("Debug.testSupCall callStatus=\(callStatus)")

                    AppPublishers.callStatusUpdated$.send(callStatus)

                    if callStatus.isEmpty {
                        print("Debug.testSupCall join as a guest")
                        let dataToMerge: [String : String] = [
                            "status": "answer",
                            "guest": "testuser"
                        ]
                        FirebaseCall.update(
                            sessionId: response.sessionId,
                            data: dataToMerge
                        )
                        FirebaseCall.get(sessionId: response.sessionId) { call in
                            guard let call = call else { return }

                            call.guestUsers { users in
                                var guestAvatars: [String] = [AppDelegate.appState?.currentUser?.avatarUrl ?? ""]
                                for user in users {
                                    guestAvatars.append(user.avatarUrl ?? "")
                                }
                                DispatchQueue.main.async {
                                    AppDelegate.appState?.guestAvatars = guestAvatars
                                }
                            }

                            state.openTokSession$.send(.subscriberDidConnect)
                        }
                    }
                    if callStatus == "answer" {
                        state.callInitiated$.send(response)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            AppDelegate.appState!.callerLoadingCall = true
                        }
                    }
                    if callStatus == "recording-started" && startTime > 0 {
                        DispatchQueue.main.async {
                            if AppDelegate.isCaller && AppDelegate.callSessionId != nil {
                                SupAPI.startArchive(sessionId: AppDelegate.callSessionId!) { response in
                                    switch response {
                                    case .success(let response):
                                        DispatchQueue.main.async {
                                            state.callArchiveId = response.id
                                        }
                                    case .failure(let error):
                                        print("Debug.testSupCall startArchive error", error)
                                    }
                                }
                            }
                        }
                    }
                    if callStatus == "end" {
                        DispatchQueue.main.async {
                            AppPublishers.onCallEnd$.send()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                if let callArchiveId = state.callArchiveId {
                                    let baseURL = "https://sup-archives.s3.us-east-2.amazonaws.com/46602742"
                                    let url = "\(baseURL)/\(callArchiveId)/archive.mp4"
                                    if AppDelegate.isCaller {
                                        state.audioRecorder.checkFileExists(withLink: url, includeLastPath: true) { audioUrl in
                                            print("Debug.testSupCall recording downloaded")
                                            AppDelegate.isCaller = false
                                            state.isCallArchived = true
                                            AppDelegate.callListener?.remove()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            case .failure(let error):
                print("Debug.testSupCall api error", error)
            }
        }
    }
}
