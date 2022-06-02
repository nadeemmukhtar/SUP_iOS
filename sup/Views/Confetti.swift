//
//  Confetti.swift
//  orange
//
//  Created by Justin Spraggins on 11/8/19.
//  Copyright © 2019 Unmute, Inc. All rights reserved.
//

import UIKit
import pop
import QuartzCore

class ConfettiView: UIView {

var confettiTimer: Timer?

    init() {
           super.init(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 100))
           beginConfetti()
       }

       required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }


    // MARK: - Actions

    func beginConfetti() {
          self.confettiTimer = Timer.scheduledTimer(timeInterval: 6, target: self, selector: #selector(self.endConfetti), userInfo: nil, repeats: false)
          self.beginAnimating()
      }

      @objc func endConfetti() {
          self.endAnimating()

          self.fadeOut(withDuration: 1.0, delay: 0.0) { _ in
              self.removeFromSuperview()
          }
      }

    func beginAnimating() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        guard self.isActive == false else { return }

        let emitterLayer = CAEmitterLayer()
        emitterLayer.seed = arc4random_uniform(UInt32.max)
        emitterLayer.frame = self.bounds
        emitterLayer.beginTime = CACurrentMediaTime()
        emitterLayer.emitterPosition = CGPoint(x: self.bounds.width / 2.0, y: -50)
        emitterLayer.emitterShape = CAEmitterLayerEmitterShape.line
        emitterLayer.emitterSize = CGSize(width: screenWidth, height: 1.0)
        emitterLayer.contentsScale = self.contentScaleFactor

        var cells: [CAEmitterCell] = []
        for image in self.images {
            for color in self.colors {
                cells.append(self.cell(with: color, image: image))
            }
        }
        emitterLayer.emitterCells = cells
        self.layer.addSublayer(emitterLayer)
        self.emitterLayer = emitterLayer
        self.isActive = true
    }

    func endAnimating() {
        let emitterLayer = self.emitterLayer
        emitterLayer?.birthRate = 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            emitterLayer?.removeFromSuperlayer()
        }
        self.isActive = false
    }

    // MARK: - Accessing

    func cell(with color: UIColor, image: UIImage) -> CAEmitterCell {
        let confetti = CAEmitterCell()
        confetti.birthRate = (1.0 + Float(arc4random_uniform(2))) * self.intensity
        confetti.lifetime = 15 * self.intensity
        confetti.lifetimeRange = 0
        confetti.color = color.cgColor
        confetti.velocity = CGFloat(350.0 * self.intensity)
        confetti.velocityRange = CGFloat(80.0 * self.intensity)
        confetti.emissionLongitude = CGFloat.pi
        confetti.emissionRange = CGFloat.pi / 4.0
        confetti.spin = CGFloat(3.5 * self.intensity)
        confetti.spinRange = CGFloat(4.0 * self.intensity)
        confetti.scale = 1.3
        confetti.scaleRange = CGFloat(self.intensity)
        confetti.scaleSpeed = CGFloat(-0.1 * self.intensity)
        confetti.contents = image.cgImage
        confetti.contentsScale = image.scale
        return confetti
    }

    var colors: [UIColor] = [ UIColor.white ]
    var images: [UIImage] = [UIImage(named: "default-avatar")!,
                             UIImage(named: "default-avatar")!
                       ]
    var intensity: Float = 0.65
    fileprivate(set) var isActive: Bool = false
    fileprivate(set) var emitterLayer: CAEmitterLayer!
}
