//
//  HappyHourHostCard.swift
//  sup
//
//  Created by Justin Spraggins on 7/25/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct HappyHourHostCard: View {
    var body: some View {
        VStack {
            Spacer().frame(height: isIPhoneX ? 50 : 27)
            VStack (spacing: 5) {
                Text("you're the host!!!")
                    .modifier(TextModifier(size: 20, font: Font.textaAltBlack, color: Color.white))
                    .padding(.bottom, 2)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: 180, height: 42)
                    .foregroundColor(Color.black)
                    .shadow(color: Color.black.opacity(0.3), radius: 20)
            )
            Spacer()
        }
        .frame(width: screenWidth, height: screenHeight)
        .transition(.move(edge: .top))
        .animation(Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0).speed(0.4))
    }
}
