//
//  AudioRecorder.swift
//  sayit
//
//  Created by Robert Malko on 12/18/19.
//  Copyright © 2019 Extra Visual. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import AudioKit
import FirebaseStorage
import mobileffmpeg
import PaperTrailLumberjack

typealias OnPermission = (Bool) -> Void

private let storageRef = Storage.storage().reference()
private let supsRef = storageRef.child("sups")
private let commentsRef = storageRef.child("comments")
private let audioManager = AudioManager()

class AudioRecorder: NSObject, ObservableObject {
    override init() {
        super.init()
        fetchRecordings()
    }

    init(ignoreFetch: Bool = false) {
        super.init()
        if !ignoreFetch {
            fetchRecordings()
        }
    }

    var filename: URL!
    var userId: String!

    let objectWillChange = PassthroughSubject<AudioRecorder, Never>()
    let clipsDidChange = PassthroughSubject<Bool, Never>()
    let recordingTimeDidChange = PassthroughSubject<Float, Never>()

    var audioRecorder: AVAudioRecorder!
    var recording = false {
        didSet {
            objectWillChange.send(self)

            if var clip = clips.last {
                clip.recording = recording
                clips[clips.count - 1] = clip
            }
        }
    }
    var recordings = [Recording]()
    var clips = [SoundClip]() {
        didSet {
            if oldValue.count != clips.count {
                clipsDidChange.send(oldValue.count > clips.count)
            }
        }
    }
    var recordingTime: Float = 0.0 {
        didSet {
            if recordingTime < 0.1 { return }
            if var clip = clips.last {
                clip.duration = recordingTime
                clips[clips.count - 1] = clip
                recordingTimeDidChange.send(recordingTime)
            }
        }
    }

    func createCallClip(filename: URL?, image: String?, userId: String) {
        var duration:Float = 0
        if let fileURL = filename {
            duration = Float(AVURLAsset(url: fileURL).duration.seconds)
        }
        createIntroClip(userId: userId)
        clips.append(SoundClip(
            type: .call,
            fileURL: filename,
            image: image,
            duration: duration
        ))
    }

    func createClip(filename: URL, userId: String) {
        createIntroClip(userId: userId)
        clips.append(SoundClip(
            type: .recording,
            fileURL: filename,
            image: nil,
            duration: 0
        ))
    }

    private let documentDirectory = FileManager.default.urls(
        for: .documentDirectory, in: .userDomainMask
    )[0]

    func createIntroClip(userId: String) {
        var fileURL = Bundle.main.url(forResource: "intro", withExtension: "m4a")
        let pathComponent = documentDirectory.appendingPathComponent("\(userId)_intro.m4a")
        if FileManager.default.fileExists(atPath: pathComponent.path) {
            fileURL = pathComponent
        }

        let clip = SoundClip(
            type: .intro,
            fileURL: fileURL,
            image: "default-avatar",
            duration: 3.0
        )

        if clips.count > 0 && clips[0].type == .intro {
            clips[0] = clip
        } else {
            clips.insert(clip, at: 0)
        }
    }

    func createStockClip(clip: SoundClips, userId: String) {
        createIntroClip(userId: userId)
        clips.append(SoundClip(
            type: .stock,
            fileURL: clip.audio,
            image: clip.image,
            duration: 0
        ))
    }

    func saveIntroClip() {
        SupUserDefaults.saveAudioIntro(userID: userId, file: filename)
    }

    func fetchClip(userId: String) {
        if let filename = SupUserDefaults.audioIntro(userID: userId) {
            let clip = SoundClip(
                type: .intro,
                fileURL: filename,
                image: "default-avatar",
                duration: 3.0
            )

            if clips.count > 0 && clips[0].type == .intro {
                clips[0] = clip
            } else {
                clips.insert(clip, at: 0)
            }
        }
    }

    func fetchRecordings() {
        recordings.removeAll()
        let directoryContents = try! FileManager.default.contentsOfDirectory(
            at: documentDirectory, includingPropertiesForKeys: nil
        )

        for audio in directoryContents {
            let recording = Recording(
                fileURL: audio,
                createdAt: Recording.creationDate(for: audio)
            )
            recordings.append(recording)
        }

        recordings.sort(by: {
            $0.createdAt.compare($1.createdAt) == .orderedDescending
        })

        objectWillChange.send(self)
    }

    func removeAllClips() {
        clips.removeLast()
        objectWillChange.send(self)
    }

    func removeLastClip() {
        if clips.count == 0 { return }

        if clips.count <= 2 && clips[0].type == .intro {
            clips = []
        } else {
            clips.removeLast()
        }
        objectWillChange.send(self)
    }

    func removeLastClipWithoutIntro() {
        if clips.count == 0 { return }

        clips.removeLast()
        objectWillChange.send(self)
    }

    func saveSup(clips: [SoundClip], uuid: String, callback: @escaping (URL, Int64, Double) -> Void) {
        if let lastClip = clips.last, let fileURL = lastClip.fileURL {
            self.saveCallback(fileURL: fileURL, uuid: uuid, callback: callback)
            /* TODO: Fix me to make sure enhance doesn't block
            audioManager.enhance(audioURL: fileURL) { newURL in
                self.saveCallback(fileURL: newURL, uuid: uuid, callback: callback)
            }
            */
        }
    }
    
    func saveComment(clips: [SoundClip], uuid: String, callback: @escaping (URL, Int64, Double) -> Void) {
        if let lastClip = clips.last, let fileURL = lastClip.fileURL {
            saveCommentCallback(fileURL: fileURL, uuid: uuid, callback: callback)
        }
    }

    func getPermission(completion: @escaping OnPermission) {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        
                    } else {
                        // failed to record!
                    }
                    
                    completion(allowed)
                }
            }
        } catch {
            Logger.log("Failed to set up recording session", log: .debug, type: .error)
        }
    }

    func startRecording(userId: String) {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            Logger.log("Failed to set up recording session", log: .debug, type: .error)
        }
        let filename = documentDirectory.appendingPathComponent(
            "\(Date().toString(dateFormat: "dd-MM-YY_'at'_HH:mm:ss")).m4a"
        )
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(
                url: filename, settings: settings
            )
            createClip(filename: filename, userId: userId)
            audioRecorder.record()
            recording = true
        } catch {
            Logger.log("Could not start recording", log: .debug, type: .error)
        }
    }

    func startRecordingIntro(userId: String) {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            Logger.log("Failed to set up recording session", log: .debug, type: .error)
        }
        let filename = audioIntroURL(userId: userId)
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(
                url: filename, settings: settings
            )
            audioRecorder.record()
            recording = true
            self.filename = filename
            self.userId = userId
        } catch {
            Logger.log("Could not start recording", log: .debug, type: .error)
        }
    }

    func audioIntroURL(userId: String) -> URL {
        return documentDirectory.appendingPathComponent("\(userId)_intro.m4a")
    }

    func stopRecording() {
        audioRecorder.stop()
        recording = false
        recordingTime = 0
        fetchRecordings()
    }

    func stopRecordingIntro() {
        audioRecorder.stop()
        recording = false
        recordingTime = 0
        fetchRecordings()
    }

    private func saveCallback(
        fileURL: URL,
        uuid: String,
        callback: @escaping (URL, Int64, Double) -> Void
    ) {
        DDLogVerbose("saving sup uuid=\(uuid)")
        let supRef = supsRef.child("\(uuid).m4a")
        let _ = supRef.putFile(from: fileURL, metadata: nil) { metadata, error in
            DDLogVerbose("sup uploaded to \(supRef)")
            if let error = error {
                DDLogError("saving sup error=\(error)")
            }
            var size: Int64 = 0
            if let metadata = metadata {
                size = metadata.size
            }
            supRef.downloadURL { (url, error) in
                if let error = error {
                    DDLogError("saving sup error=\(error)")
                }
                guard let downloadURL = url else {
                    DDLogError("download url is nil url=\(url)")
                    return
                }
                DDLogVerbose("sup downloadURL=\(downloadURL) size=\(size)")
                callback(downloadURL, size, 0)
            }
        }
    }

    private func saveCommentCallback(
        fileURL: URL,
        uuid: String,
        callback: @escaping (URL, Int64, Double) -> Void
    ) {
        let commentRef = commentsRef.child("\(uuid).m4a")
        let _ = commentRef.putFile(from: fileURL, metadata: nil) { metadata, error in
            guard let metadata = metadata else {
                Logger.log("Error with metadata", log: .debug, type: .error)
                return
            }
            let size = metadata.size
            commentRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    return
                }
                callback(downloadURL, size, 0)
            }
        }
    }

    private func writeFileList(clips: [SoundClip]) -> URL {
        let fileList: String = clips.compactMap { clip in
            if let fileURL = clip.fileURL {
                return "file '\(fileURL)'"
            }
            return nil
        }.joined(separator: "\n")
        let filename = documentDirectory.appendingPathComponent("sup_file_list.txt")
        do {
            try fileList.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            Logger.log("error writing file", log: .debug, type: .error)
        }

        return filename
    }
}

extension AudioRecorder {
    
    func checkFileExists(withLink link: String, includeLastPath: Bool = false, completion: @escaping ((_ filePath: URL)->Void)){
        if let url  = URL.init(string: link) {
            let fileManager = FileManager.default
            if let documentDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create: false) {

                var filePath = documentDirectory.appendingPathComponent(url.lastPathComponent, isDirectory: false)
                if includeLastPath {
                    let pathComponent = Array(url.pathComponents.suffix(2)).joined(separator: "_")
                    filePath = documentDirectory.appendingPathComponent(pathComponent, isDirectory: false)
                }

                do {
                    if try filePath.checkResourceIsReachable() {
                        completion(filePath)
                    } else {
                        Logger.log("file doesnt exist", log: .debug, type: .error)
                        downloadFile(withUrl: url, andFilePath: filePath, completion: completion)
                    }
                } catch {
                    Logger.log("file doesnt exist", log: .debug, type: .error)
                    downloadFile(withUrl: url, andFilePath: filePath, completion: completion)
                }
            } else {
                Logger.log("file doesnt exist", log: .debug, type: .error)
            }
        } else {
            Logger.log("file doesnt exist", log: .debug, type: .error)
        }
    }
    
    func downloadFile(withUrl url: URL, andFilePath filePath: URL, retryCount: Int = 60, completion: @escaping ((_ filePath: URL)->Void)){
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try Data.init(contentsOf: url)
                try data.write(to: filePath, options: .atomic)
                Logger.log("downloadFile saved: %{public}@", log: .debug, type: .debug, filePath.absoluteString)
                DispatchQueue.main.async {
                    completion(filePath)
                }
            } catch let err {
                Logger.log("an error happened while downloading or saving the file: %{public}@", log: .debug, type: .error, err.localizedDescription)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    self.downloadFile(withUrl: url, andFilePath: filePath, retryCount: retryCount - 1, completion: completion)
                }
            }
        }
    }
}
