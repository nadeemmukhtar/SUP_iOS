//
//  CircularProgressBar.swift
//  sayit
//
//  Created by Robert Malko on 12/18/19.
//  Copyright © 2019 Extra Visual. All rights reserved.
//

import SwiftUI

struct CircularProgressBar: View {
    @EnvironmentObject var audioPlayer: AudioPlayer

    @Binding var circleProgress: CGFloat?
    @Binding var label: String?

    var hasBackground = true
    var backgroundFill = Color.clear
    var completedStroke = Color.primaryTextColor
    var circleSize: CGFloat = 78
    var strokeWidth: CGFloat = 12

    @State private var progress: CGFloat = 0

    var body: some View {
        let strokeSize: CGFloat = circleSize + strokeWidth
        let strokeStyle = StrokeStyle(lineWidth: strokeWidth, lineCap: .round)

        return ZStack {
            // Background
            if hasBackground {
                BackgroundBlurView(style: .prominent)
                    .frame(width: circleSize, height: circleSize)
                    .clipShape(Circle())
            }
            // Optional incompleted stroke
            Circle()
                .stroke(Color.clear, lineWidth: strokeWidth)
                .frame(width: strokeSize, height: strokeSize)
            // Completed stroke
            Circle()
                .trim(from: 0.0, to: circleProgress ?? progress)
                .stroke(completedStroke, style: strokeStyle)
                .frame(width: strokeSize, height: strokeSize)
                .rotationEffect(Angle(degrees: -90))

            if label != nil {
                Text(label!)
                    .font(Font.custom(Font.textaAltBlack, size: 20))
                    .foregroundColor(completedStroke)
                    .frame(width: circleSize)
                    .animation(nil)
            }
        }.onReceive(self.audioPlayer.progressWillChange.eraseToAnyPublisher()) { changedProgress in
            self.progress = CGFloat(changedProgress)
        }
    }
}

struct CircularProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        CircularProgressBar(
            circleProgress: .constant(0.65),
            label: .constant("10.3")
        )
            .previewLayout(.sizeThatFits)
            .padding()
            .environment(\.colorScheme, .dark)
    }
}
