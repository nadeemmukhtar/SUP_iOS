//
//  SupCaption.swift
//  sup
//
//  Created by Justin Spraggins on 3/6/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct SupCaption: View {
    @ObservedObject var state: AppState
    @Binding var titleText: String
    @Binding var isTyping: Bool
    @Binding var hidePlaceholder: Bool
    @State var showKeyboard = false
    @State var autoCap = true
    @State var autoCorrect = true
    @State var spellCheck = true
    let accentColor: Color

    var body: some View {
            ZStack(alignment: .leading) {
                if titleText.isEmpty {
                    Text("enter a title...")
                        .modifier(TextModifier(size: 22, font: Font.textaBold))
                        .padding(.top, 7)
                        .frame(minWidth: 0,
                               idealWidth: nil,
                               maxWidth: .infinity,
                               minHeight: 58,
                               idealHeight: nil,
                               maxHeight: 58,
                               alignment: .topLeading)
                        .opacity(hidePlaceholder ? 0 : 1)
                        .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 0)
                }
                TextView(isFirstResponder: showKeyboard,
                         returnKeyClosesKeyboard: true,
                         autoCap: autoCap,
                         autoCorrect: autoCorrect,
                         spellCheck: spellCheck,
                         text: $titleText,
                         didEditing: $isTyping,
                         blackText: true,
                         largeText: true)
                    .padding(.trailing, 20)
                    .frame(minWidth: 0,
                           idealWidth: nil,
                           maxWidth: .infinity,
                           minHeight: 58,
                           idealHeight: nil,
                           maxHeight: 58,
                           alignment: .topLeading)
                    .lineSpacing(0)
                    .accentColor(accentColor)
                    .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 0)
        }
            .frame(width: screenWidth - 44, height: 80)
    }
}
