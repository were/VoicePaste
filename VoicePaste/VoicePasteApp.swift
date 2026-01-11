//
//  VoicePasteApp.swift
//  VoicePaste
//
//  Created by Jian Weng on 2026/1/11.
//

import SwiftUI
#if os(macOS)
import AppKit

@MainActor
@Observable
final class AppState {
    var isRecording = false
    var recordingStartTime: Date?
    var lastRecordingDuration: TimeInterval?
    var isShowingCompletion = false

    let hotkeyManager = HotkeyManager()
    private var isSetup = false
    private var overlayHideWorkItem: DispatchWorkItem?
    private var overlayWindow: RecordingOverlayWindow?

    func setup() {
        guard !isSetup else { return }
        isSetup = true
        overlayWindow = RecordingOverlayWindow(appState: self)
        hotkeyManager.onRecordingStart = { [weak self] in self?.handleRecordingStart() }
        hotkeyManager.onRecordingStop = { [weak self] in self?.handleRecordingStop() }
        _ = hotkeyManager.start()
    }

    private func handleRecordingStart() {
        // Cancel any pending hide operation
        overlayHideWorkItem?.cancel()
        overlayHideWorkItem = nil

        // Reset state and start recording
        isRecording = true
        recordingStartTime = Date()
        lastRecordingDuration = nil
        isShowingCompletion = false

        // Show overlay
        overlayWindow?.show()
    }

    private func handleRecordingStop() {
        // Calculate final duration
        if let startTime = recordingStartTime {
            lastRecordingDuration = Date().timeIntervalSince(startTime)
        }

        isRecording = false
        recordingStartTime = nil
        isShowingCompletion = true

        // Schedule hide after showing completion
        let workItem = DispatchWorkItem { [weak self] in
            self?.isShowingCompletion = false
            self?.overlayWindow?.hide()
        }
        overlayHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }
}

private let sharedAppState = AppState()
#endif

@main
struct VoicePasteApp: App {
    var body: some Scene {
        #if os(macOS)
        MenuBarExtra("VoicePaste", systemImage: sharedAppState.isRecording ? "mic.fill" : "mic") {
            MenuContent()
        }
        .menuBarExtraStyle(.window)
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}

#if os(macOS)
struct MenuContent: View {
    var body: some View {
        Text(sharedAppState.isRecording ? "Recording..." : "VoicePaste is running")
            .onAppear {
                sharedAppState.setup()
            }
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
#endif
