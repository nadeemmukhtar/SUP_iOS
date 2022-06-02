//
//  TapAndHoldPopover.swift
//  sup
//
//  Created by Justin Spraggins on 12/16/19.
//  Copyright © 2019 Episode 8, Inc. All rights reserved.
//

import SwiftUI

/// NOTES: This can be turned in to a more generic PulsatingPopover
/// View that takes in the text to display in the popover
struct TapAndHoldPopover: View {
    @ObservedObject var state: AppState
    @Binding var isRecording: Bool
    @State var pulsate = false

    let pulsateAnimation = Animation.easeInOut(duration: 1.5)
        .repeatForever(autoreverses: true).speed(1.5)

    var body: some View {
        ZStack {
            Image("record-hint")
        }
        .opacity(isRecording ? 0 : 1)
        .animation(.easeInOut(duration: 0.3))
        .scaleEffect(isRecording ? 0.01 : 1)
        .animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0))
        .padding(.bottom, -5)
    }
}
