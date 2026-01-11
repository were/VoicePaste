//
//  RecordingOverlayView.swift
//  VoicePaste
//
//  Created by Claude on 2026/1/11.
//

import SwiftUI
import Combine

/// A SwiftUI view that displays the recording timer with fade animation.
struct RecordingOverlayView: View {
    let appState: AppState

    @State private var currentTime: TimeInterval = 0
    @State private var opacity: Double = 1.0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 8) {
            if appState.isTranscribing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
                    .colorInvert()
            }
            Text(displayText)
                .font(.system(size: 24, weight: .medium, design: appState.isTranscribing ? .default : .monospaced))
                .foregroundColor(.white)
        }
        .frame(minWidth: 140)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.75))
        )
        .fixedSize()
        .opacity(opacity)
        .onReceive(timer) { _ in
            updateTimer()
        }
        .onChange(of: appState.isRecording) { _, isRecording in
            handleRecordingChange(isRecording: isRecording)
        }
        .onChange(of: appState.isTranscribing) { _, isTranscribing in
            handleTranscribingChange(isTranscribing: isTranscribing)
        }
        .onChange(of: appState.isShowingCompletion) { _, isShowingCompletion in
            handleCompletionChange(isShowingCompletion: isShowingCompletion)
        }
    }

    private var displayText: String {
        if appState.isTranscribing {
            return "Transcribing..."
        }
        return formattedTime
    }

    private var formattedTime: String {
        let displayTime: TimeInterval
        if appState.isRecording {
            displayTime = currentTime
        } else if let lastDuration = appState.lastRecordingDuration {
            displayTime = lastDuration
        } else {
            displayTime = 0
        }

        let minutes = Int(displayTime) / 60
        let seconds = Int(displayTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func updateTimer() {
        guard appState.isRecording, let startTime = appState.recordingStartTime else {
            return
        }
        currentTime = Date().timeIntervalSince(startTime)
    }

    private func handleRecordingChange(isRecording: Bool) {
        if isRecording {
            // Reset timer when recording starts
            currentTime = 0
            opacity = 1.0
        }
    }

    private func handleTranscribingChange(isTranscribing: Bool) {
        if isTranscribing {
            // Keep visible during transcription
            opacity = 1.0
        }
    }

    private func handleCompletionChange(isShowingCompletion: Bool) {
        if !isShowingCompletion && !appState.isRecording && !appState.isTranscribing {
            // Fade out when completion display ends
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0.0
            }
        }
    }
}
