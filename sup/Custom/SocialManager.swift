//
//  SocialManager.swift
//  sup
//
//  Created by Justin Spraggins on 2/26/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import UIKit
import Photos
import TikTokOpenSDK
import SCSDKCreativeKit

class SocialManager: NSObject, UIDocumentInteractionControllerDelegate {
    private let documentInteractionController = UIDocumentInteractionController()
    private let kInstagramURL = "instagram://"
    private let kUTI = "com.instagram.exclusivegram"
    private let kfileNameExtension = "instagram.igo"
    private let kAlertViewTitle = "Error"
    private let kAlertViewMessage = "Please install the Instagram application"

    private let documentDirectory = FileManager.default.urls(
        for: .documentDirectory, in: .userDomainMask
    )[0]

    // singleton manager
    class var sharedManager: SocialManager {
        struct Singleton {
            static let instance = SocialManager()
        }
        return Singleton.instance
    }

    fileprivate lazy var snapAPI = {
        return SCSDKSnapAPI()
    }()

    func postToInstagramFeed(image: UIImage, text:String, vc: UIViewController?) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        if let lastAsset = fetchResult.firstObject {
            var encoded = ""
            if let sencoded = getEncoded(text: text) { encoded = sencoded }

            var url = URL(string: "instagram://library?LocalIdentifier=\(lastAsset.localIdentifier)")!

            if !encoded.isEmpty {
                url = URL(string: "instagram://library?LocalIdentifier=\(lastAsset.localIdentifier)&InstagramCaption=\(encoded)")!
            }

            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                let alertController = UIAlertController(title: "error", message: "Instagram is not installed", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
                vc?.present(alertController, animated: true, completion: nil)
            }
        }
    }

    func postToInstagramFeedVideo(sup: Sup, startTime: Double, endTime: Double, vc: UIViewController?, completion: @escaping (Bool) -> Void){
        let url = URL(string: "instagram://")!
        if UIApplication.shared.canOpenURL(url) {
            self.generateVideoFeed(sup: sup, startTime: startTime, endTime: endTime) { saved in
                if saved {
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
                    if let lastAsset = fetchResult.firstObject {
                        var encoded = ""
                        if let sencoded = self.getEncoded(text: sup.description) { encoded = sencoded }

                        var url = URL(string: "instagram://library?LocalIdentifier=\(lastAsset.localIdentifier)")!

                        if !encoded.isEmpty {
                            url = URL(string: "instagram://library?LocalIdentifier=\(lastAsset.localIdentifier)&InstagramCaption=\(encoded)")!
                        }

                        DispatchQueue.main.async {
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }

                        completion(saved)
                    } else {
                        completion(false)
                    }
                }
            }
        } else {
            completion(false)
            let alertController = UIAlertController(title: "error", message: "Instagram is not installed", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
            vc?.present(alertController, animated: true, completion: nil)
        }
    }

    func postToInstagramStories(sup: Sup, startTime: Double, endTime: Double, vc: UIViewController?, completion: @escaping (Bool) -> Void){
        let url = URL(string: "instagram-stories://share")!
        if UIApplication.shared.canOpenURL(url) {
            self.generateVideo(sup: sup, startTime: startTime, endTime: endTime) { saved in
                if saved {
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
                    if let lastAsset = fetchResult.firstObject {
                        PHCachingImageManager().requestAVAsset(forVideo: lastAsset, options: nil) { (asset, _, _) in
                            let asset = asset as? AVURLAsset
                            let data = try! Data(contentsOf: asset!.url)
                            DispatchQueue.main.async {
                                let stickerData =  Sticker.shared.generateIGSticker(sup: sup)!.pngData()!
                                let pasteBoardItems = [
                                    ["com.instagram.sharedSticker.backgroundVideo" : data,
                                     "com.instagram.sharedSticker.stickerImage" : stickerData]
                                ]
                                UIPasteboard.general.setItems(pasteBoardItems, options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
                                UIApplication.shared.open(url)
                            }

                            completion(saved)
                        }
                    }
                } else {
                    completion(false)
                }
            }
        } else {
            completion(false)
            let alertController = UIAlertController(title: "error", message: "Instagram is not installed", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
            vc?.present(alertController, animated: true, completion: nil)
        }
    }

    func postToInstagramStoriesImage(sup: Sup, startTime: Double, endTime: Double, vc: UIViewController?, completion: @escaping (Bool) -> Void){
        let url = URL(string: "instagram-stories://share")!
        if UIApplication.shared.canOpenURL(url) {
            DispatchQueue.main.async {
                let bgImageData = VerticalPhotoBackground(sup: sup, isTikTok: false).asImage().pngData()!
                let stickerData =  Sticker.shared.generateIGSticker(sup: sup)!.pngData()!
                let pasteBoardItems = [
                    ["com.instagram.sharedSticker.backgroundImage" : bgImageData,
                     "com.instagram.sharedSticker.stickerImage" : stickerData,
                     UIPasteboard.typeListString[0] as! String : sup.url.absoluteString]
                ]
                UIPasteboard.general.setItems(pasteBoardItems, options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
                UIApplication.shared.open(url)
            }

            completion(true)
//            let alertController = UIAlertController(title: "alert", message: "the sup link has been save to your clipboard to share in the swipe up", preferredStyle: .alert)
//            alertController.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
//            vc?.present(alertController, animated: true, completion: nil)
        } else {
            completion(false)
            let alertController = UIAlertController(title: "error", message: "Instagram is not installed", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
            vc?.present(alertController, animated: true, completion: nil)
        }
    }

    func postToInstagramStoriesVideo(sup: Sup, startTime: Double, endTime: Double, vc: UIViewController?, completion: @escaping (Bool) -> Void){
        let url = URL(string: "instagram://")!
        if UIApplication.shared.canOpenURL(url) {
            self.generateVideo(sup: sup, startTime: startTime, endTime: endTime) { saved in
                if saved {
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
                    if let lastAsset = fetchResult.firstObject {
                        var encoded = ""
                        if let sencoded = self.getEncoded(text: sup.description) { encoded = sencoded }

                        var url = URL(string: "instagram://library?LocalIdentifier=\(lastAsset.localIdentifier)")!

                        if !encoded.isEmpty {
                            url = URL(string: "instagram://library?LocalIdentifier=\(lastAsset.localIdentifier)&InstagramCaption=\(encoded)")!
                        }

                        DispatchQueue.main.async {
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        completion(saved)
                    } else {
                        completion(false)
                    }
                }
                
            }
        } else {
            completion(false)
            let alertController = UIAlertController(title: "error", message: "Instagram is not installed", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
            vc?.present(alertController, animated: true, completion: nil)
        }
    }

    func postToSnapchat(sup: Sup, url: String, vc: UIViewController?) {
        let supPlayURL = url
        let stickerImage = SnapchatPlaySticker(sup: sup).asImage()
        let sticker = SCSDKSnapSticker(stickerImage: stickerImage)
        sticker.posY = 0.5
        sticker.posX = 0.6
        sticker.rotation = 0.2

        let snapContent = SCSDKNoSnapContent()
        snapContent.sticker = sticker
        snapContent.attachmentUrl = supPlayURL

        DispatchQueue.main.async {
            vc?.view.isUserInteractionEnabled = false
            self.snapAPI.startSending(snapContent) { error in
                vc?.view.isUserInteractionEnabled = true
            }
        }
    }

    func postInviteToSnapchat(url: String, vc: UIViewController?) {
        guard let username = AppDelegate.appState?.currentUser?.username else {
            // TODO: pop an error message?
            return
        }
        let fileName = "guestpass_\(username).mp4"
        let guestPassURL = documentDirectory.appendingPathComponent(fileName)
        let video = SCSDKSnapVideo(videoUrl: guestPassURL)
        let snapContent = SCSDKVideoSnapContent(snapVideo: video)
        snapContent.attachmentUrl = url

        DispatchQueue.main.async {
            vc?.view.isUserInteractionEnabled = false
            self.snapAPI.startSending(snapContent) { error in
                if let error = error {
                    Logger.log("Error posting guest pass: %{public}@", log: .debug, type: .error, error.localizedDescription)
                }
                DispatchQueue.main.async {
                    vc?.view.isUserInteractionEnabled = true
                }
            }
        }
    }

    func postToTikTok(sup: Sup, startTime: Double, endTime: Double, vc: UIViewController?, completion: @escaping (Bool) -> Void) {
        if TikTokOpenSDKApplicationDelegate.sharedInstance().isAppInstalled() {
            self.generateTikTokVideo(sup: sup, startTime: startTime, endTime: endTime) { saved in
                if saved {
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
                    if let lastAsset = fetchResult.firstObject {
                        let req = TikTokOpenSDKShareRequest()
                        req.mediaType = .video
                        req.localIdentifiers = [lastAsset.localIdentifier]

                        completion(saved)
                        DispatchQueue.main.async {
                            req.send { response in
                                if response.shareState == .stateSuccess {
                                    completion(saved)
                                } else {
                                    completion(false)
                                }
                            }
                        }
                    }
                } else {
                    completion(false)
                }
            }
        } else {
            completion(false)
            let alertController = UIAlertController(title: "error", message: "TikTok is not installed", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
            vc?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func postToYoutube(sup: Sup, startTime: Double, endTime: Double, vc: UIViewController?, completion: @escaping (Bool) -> Void){
        let url = URL(string: "youtube://")!
        if UIApplication.shared.canOpenURL(url) {
            self.generateYTVideo(sup: sup, startTime: startTime, endTime: endTime) { saved in
                completion(saved)
            }
        } else {
            completion(false)
            let alertController = UIAlertController(title: "error", message: "Youtube is not installed", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
            vc?.present(alertController, animated: true, completion: nil)
        }
    }

    private func getEncoded(text:String) -> String? {
        let urlString = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return urlString
    }
}

extension SocialManager {
    func generateVideoFeed(sup: Sup, startTime: Double, endTime: Double, completion: @escaping (Bool) -> Void) {
        SocialVideoGenerator.generate(type: .square, sup: sup, isTiktok: false, startTime: startTime, endTime: endTime) { result in
            switch result {
            case .success(let url):
                self.saveVideo(file: url, completion: completion)
            case .failure(let error):
                Logger.log("generateVideo error: %{public}@", log: .debug, type: .error, error.localizedDescription)
                completion(false)
            }
        }
    }

    func generateVideo(sup: Sup, startTime: Double, endTime: Double, completion: @escaping (Bool) -> Void) {
        SocialVideoGenerator.generate(type: .vertical, sup: sup, isTiktok: false, startTime: startTime, endTime: endTime) { result in
            switch result {
            case .success(let url):
                self.saveVideo(file: url, completion: completion)
            case .failure(let error):
                Logger.log("generateVideo error: %{public}@", log: .debug, type: .error, error.localizedDescription)
                completion(false)
            }
        }
    }

    func generateTikTokVideo(sup: Sup, startTime: Double, endTime: Double, completion: @escaping (Bool) -> Void) {
        SocialVideoGenerator.generate(type: .vertical, sup: sup, isTiktok: true, startTime: startTime, endTime: endTime) { result in
            switch result {
            case .success(let url):
                self.saveVideo(file: url, completion: completion)
            case .failure(let error):
                Logger.log("generateVideo error: %{public}@", log: .debug, type: .error, error.localizedDescription)
                completion(false)
            }
        }
    }
    //AIzaSyBrQRK-keFHIWNeJSUogg9srKYaZo7qgLw
    //682787268706-ja4h33rmsm0s2gfk46r0cn2tn03sv9b1.apps.googleusercontent.com
    func generateYTVideo(sup: Sup, startTime: Double, endTime: Double, completion: @escaping (Bool) -> Void) {
        SocialVideoGenerator.generate(type: .horizontal, sup: sup, isTiktok: false, startTime: startTime, endTime: endTime) { result in
            switch result {
            case .success(let url):
                self.saveVideo(file: url, completion: completion)
            case .failure(let error):
                Logger.log("generateVideo error: %{public}@", log: .debug, type: .error, error.localizedDescription)
                completion(false)
            }
        }
    }

    func saveVideo(file: URL, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: file)
        }) { saved, error in
            if let err = error {
                Logger.log("saveVideo error: %{public}@", log: .debug, type: .error, err.localizedDescription)
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}
