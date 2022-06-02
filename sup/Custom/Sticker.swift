//
//  Sticker.swift
//  sup
//
//  Created by Justin Spraggins on 2/28/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import UIKit
import Photos
import Foundation
import BonMot
import UIImageColors

class Sticker: NSObject {
    var avatar: String?
    var coverPhoto: String?

    static var shared = Sticker()

    func generateSticker(sup: Sup) -> UIImage? {
        let avatarData = try? Data(contentsOf: sup.avatarUrl)
        if avatarData == nil { return nil }
        guard let avatarImage = UIImage(data: avatarData!) else { return nil }

        let stickerSize = CGSize(width: screenWidth, height: screenWidth)
        let view = UIView(frame: CGRect(origin: .zero, size: stickerSize))
        view.layer.masksToBounds = false

        let avatarView = UIImageView(image: avatarImage)
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.masksToBounds = false
        avatarView.frame = CGRect(x: 234/2 - 28,
                                  y: 62,
                                  width: 60,
                                  height: 60)
        avatarView.layer.masksToBounds = true
        avatarView.layer.cornerRadius = 30

        let stickerView = UIImageView(image: UIImage(named: "sticker-play"))
        stickerView.contentMode = .scaleAspectFit
        stickerView.layer.masksToBounds = false
        stickerView.frame = CGRect(x: 0,
                                   y: 0,
                                   width: 234,
                                   height: 275)

        view.addSubview(stickerView)
        view.addSubview(avatarView)

        UIGraphicsBeginImageContextWithOptions(stickerSize, false, UIScreen.main.scale)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return finalImage
    }

    func generateIGSticker(sup: Sup) -> UIImage? {
        let stickerSize = CGSize(width: screenWidth, height: screenHeight)

        let view = UIView(frame: CGRect(origin: .zero, size: stickerSize))
        view.layer.masksToBounds = false

        let logoView = UIImageView(image: UIImage(named: "sticker-IG"))
        logoView.contentMode = .scaleAspectFit
        logoView.frame = CGRect(x: view.frame.maxX - 150,
                                y: view.frame.minY + (isIPhoneX ? 100 : 40),
                                width: 160,
                                height: 160)
        view.addSubview(logoView)

        UIGraphicsBeginImageContextWithOptions(stickerSize, false, UIScreen.main.scale)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return finalImage
    }
}
