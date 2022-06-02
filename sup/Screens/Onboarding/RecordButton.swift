//
//  RecordButton.swift
//  sup
//
//  Created by Justin Spraggins on 12/16/19.
//  Copyright © 2019 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct RecordButton: View {
    @ObservedObject var state: AppState
    @Binding var isRecording: Bool
    @Binding var audioRecorder: AudioRecorder
    var isRecordingIntro = true
    var maxSeconds = 15.0
    var onRecordingStart: (() -> Void)? = nil
    var onRecordingStop: (() -> Void)? = nil

    @State private var currentPosition: CGSize = .zero
    @State private var newPosition: CGSize = .zero
    @State private var isLongPressed: Bool? = false
    @State private var timer: Timer? = nil
    @State private var progress: CGFloat? = 0.0
    @State private var recordingTime: Float = 0.0
    @State private var label = "0.0s"
    @State private var recordPulsate = false

    let size: CGFloat = 70

    private func onDragStart() {
        isRecording = true
        startRecording()
    }

    private func onDragEnd() {
        self.timer?.invalidate()
        self.progress = 0.0
        self.recordingTime = 0.0
        self.label = "0.0s"
        self.isLongPressed = false
        self.currentPosition = .zero

        // This is a hack to turn off gesture
        self.newPosition = CGSize(
            width: Double.infinity,
            height: Double.infinity
        )

        if isRecording {
            isRecording = false
            stopRecording()
            onRecordingStop?()
        }
    }

    private func startRecording() {
        onRecordingStart?()
        if isRecordingIntro {
            self.audioRecorder.startRecordingIntro(userId: self.state.currentUser?.uid ?? "")
        } else {
            self.audioRecorder.startRecording(userId: self.state.currentUser?.uid ?? "")
        }

        self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            withAnimation() {
                self.progress = self.progress! + CGFloat(1 / (self.maxSeconds * 10))
                self.recordingTime += 0.1
                self.audioRecorder.recordingTime = self.recordingTime
            }
            self.label = String(format: "%.1fs", Float(self.recordingTime))
            if self.progress! >= 1.0 {
                self.onDragEnd()
            }
        }
    }

    private func stopRecording() {
        if isRecordingIntro {
            self.audioRecorder.stopRecordingIntro()
        } else {
            self.audioRecorder.stopRecording()
        }
    }

    var recordRedColor: Bool {
        self.isRecording || (self.state.isConnect && AppDelegate.isCaller)
      }

    var body: some View {
        ZStack {
            CircularProgressBar(
                circleProgress: self.$progress,
                label: Binding(self.$label),
                backgroundFill: Color.cellBackground,
                completedStroke: Color.primaryTextColor
            )
                .offset(x: 0, y: -size - 5)
                .opacity(isRecording ? 1 : 0)
                .animation(.easeInOut(duration: 0.2))
                .scaleEffect(self.isRecording ? 1 : 0.5)
                .animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0))

                BackgroundBlurView(style: .prominent)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(self.isRecording ? Color.white.opacity(0.4) : Color.white, lineWidth: self.isRecording ? 4 : 8))
                    .animation(.easeInOut(duration: 0.3))
                    .shadow(color: Color.shadowColor.opacity(0.1), radius: 10, x: 0, y: 15)
            .onTapGesture {
                impact(style: .soft)
                self.isRecording ? self.onDragEnd() : self.onDragStart()
            }
            .scaleEffect(self.isRecording ? 0.7 : 1)
            .animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 16, initialVelocity: 0))
        }
        .padding(.bottom, 10)
        .zIndex(100)
        .frame(height: 70)
    }
}
