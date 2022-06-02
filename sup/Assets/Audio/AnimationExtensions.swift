//
//  AnimationExtensions.swift
//  sup
//
//  Created by Justin Spraggins on 12/20/19.
//  Copyright © 2019 Episode 8, Inc. All rights reserved.
//

import UIKit
import pop

extension CALayer {

    func fadeIn(withDuration duration: TimeInterval, delay: TimeInterval = 0.0, completionHandler completion: ((Bool) -> Void)? = nil) {
        self.opacity = 0.0

        let animation = POPBasicAnimation(propertyNamed: kPOPLayerOpacity)!
        animation.duration = duration
        animation.beginTime = CACurrentMediaTime() + delay
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.completionBlock = { _, finished in
            completion?(finished)
        }
        self.pop_add(animation, forKey: "opacity")
    }

    func fadeOut(withDuration duration: TimeInterval, delay: TimeInterval = 0.0, completionHandler completion: ((Bool) -> Void)? = nil) {
        self.opacity = 1.0

        let animation = POPBasicAnimation(propertyNamed: kPOPLayerOpacity)!
        animation.duration = duration
        animation.beginTime = CACurrentMediaTime() + delay
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.completionBlock = { _, finished in
            completion?(finished)
        }
        self.pop_add(animation, forKey: "opacity")
    }

}

extension UIView {

    func fadeIn(withDuration duration: TimeInterval, delay: TimeInterval = 0.0, completionHandler completion: ((Bool) -> Void)? = nil) {
        self.layer.fadeIn(withDuration: duration, delay: delay, completionHandler: completion)
    }

    func fadeOut(withDuration duration: TimeInterval, delay: TimeInterval = 0.0, completionHandler completion: ((Bool) -> Void)? = nil) {
        self.layer.fadeOut(withDuration: duration, delay: delay, completionHandler: completion)
    }

}
