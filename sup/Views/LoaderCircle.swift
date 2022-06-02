//
//  LoaderCircle.swift
//  sup
//
//  Created by Justin Spraggins on 2/21/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct LoaderCircle: View {
    @State var showWaves = false
    @State var pulsate = false
    var size = CGFloat(32)
    var innerSize = CGFloat(28)
    var isButton = false
    var tint: Color = Color.white

    var body: some View {
        ZStack {
            Circle() // Wave
                .stroke(lineWidth: 2)
                .frame(width: size, height: size)
                .foregroundColor(tint.opacity(0.8))
                .scaleEffect(self.showWaves && !isButton ? 2 : self.showWaves && isButton ? 2 : 1)
                .hueRotation(.degrees(self.showWaves ? 360 : 0))
                .opacity(self.showWaves ? 0 : 1)
                .animation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: false).speed(1))
                .onAppear() {
                    self.showWaves.toggle()
            }
            Circle() // Central
                .frame(width: innerSize, height: innerSize)
                .foregroundColor(tint.opacity(0.4))
                .hueRotation(.degrees(self.pulsate ? 360 : 0))
                .scaleEffect(self.showWaves && !isButton ? 2 : self.showWaves && isButton ? 0.8 : 1)
                .animation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true).speed(1))
                .onAppear() {
                    self.pulsate.toggle()
            }
        }
    }
}
