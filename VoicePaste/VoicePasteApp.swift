//
//  VoicePasteApp.swift
//  VoicePaste
//
//  Created by Jian Weng on 2026/1/11.
//

import SwiftUI
#if os(macOS)
import AppKit
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        sharedAppState.setup()
    }
}

@MainActor
@Observable
final class AppState {
    var isRecording = false
    var recordingStartTime: Date?
    var lastRecordingDuration: TimeInterval?
    var isShowingCompletion = false
    var lastRecordingURL: URL?

    let hotkeyManager = HotkeyManager()
    let audioRecorder = AudioRecorder()
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

        // Request permission and start audio recording
        Task {
            let hasPermission = await audioRecorder.requestPermission()
            guard hasPermission else {
                showErrorAlert(message: "Microphone permission denied. Please grant access in System Settings.")
                return
            }

            do {
                lastRecordingURL = try audioRecorder.startRecording()
            } catch {
                showErrorAlert(message: "Failed to start recording.")
                return
            }

            // Reset state and start recording
            isRecording = true
            recordingStartTime = Date()
            lastRecordingDuration = nil
            isShowingCompletion = false

            // Show overlay
            overlayWindow?.show()
        }
    }

    private func handleRecordingStop() {
        // Stop audio recording
        do {
            lastRecordingURL = try audioRecorder.stopRecording()
        } catch {
            showErrorAlert(message: "Failed to stop recording.")
            isRecording = false
            overlayWindow?.hide()
            return
        }

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

    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "VoicePaste Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

private let sharedAppState = AppState()
#endif

@main
struct VoicePasteApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

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
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
#endif
