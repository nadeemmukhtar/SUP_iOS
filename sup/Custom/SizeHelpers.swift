//
//  SizeHelpers.swift
//  sayit
//
//  Created by Robert Malko on 12/15/19.
//  Copyright © 2019 Extra Visual. All rights reserved.
//

import UIKit

let screenSize = UIScreen.main.bounds.size
let screenHeight = UIScreen.main.bounds.height
let screenWidth = UIScreen.main.bounds.width
let screenCenter = CGPoint(x: screenWidth / 2.0, y: screenHeight / 2.0)
let screenRect = CGRect(origin: .zero, size: screenSize)

let height = UIScreen.main.nativeBounds.height
let isIPhoneX: Bool = height == 2436 || height == 2688 || height == 1792
let isIPhoneXMax: Bool = height == 2688
let isIPhoneXR: Bool = height == 1792
let isIPhoneSE: Bool = height == 1136
let isIPhonePlus: Bool = height == 2208
let isIPhone: Bool = height == 1334
let isIPad: Bool = height == 2048 || height == 2224 || height == 2732
let isIPadPro: Bool = height == 2732
let isIPadRegular: Bool = height == 2048 || height == 2224
