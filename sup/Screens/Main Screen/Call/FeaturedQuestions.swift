//
//  FeaturedQuestions.swift
//  sup
//
//  Created by Justin Spraggins on 7/8/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct FeaturedQuestions: View {
    let question: Question
    var action: () -> Void

    var body: some View {
       Button(action: {
           impact(style: .medium)
           self.action()
       }) {
           ZStack {
               BackgroundBlurView(style: .systemThinMaterialLight)
                   .frame(width: screenWidth - 60, height: 130)
                   .clipShape(RoundedRectangle(cornerRadius: 26))
                   .overlay(
                       RoundedRectangle(cornerRadius: 26)
                           .stroke(Color.white.opacity(0.2), lineWidth: 2)
                           .frame(width: screenWidth - 58, height: 132)
               )

               VStack (spacing: 0) {
                Text(question.title.uppercased())
                    .modifier(TextModifier(size: 19, font: Font.textaAltHeavy, color: Color.backgroundColor))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .truncationMode(.tail)
                    .lineSpacing(0.2)
                    .padding(.horizontal, 40)
                    .frame(width: screenWidth - 50, height: 100)
                    .animation(nil)

//                Text("trending")
//                    .modifier(TextModifier(size: 15, font: Font.ttNormsBold, color: Color.backgroundColor.opacity(0.4)))
               }
               .frame(width: screenWidth - 50, height: 130)
           }
       }
       .buttonStyle(ButtonBounceHeavy())
    }
}
