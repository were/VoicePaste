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
    var isTranscribing = false
    var transcriptionError: String?

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

        // Reset state and start recording immediately (for UI responsiveness)
        isRecording = true
        recordingStartTime = Date()
        lastRecordingDuration = nil
        isShowingCompletion = false

        // Show overlay immediately
        overlayWindow?.show()

        // Request permission and start audio recording asynchronously
        Task {
            let hasPermission = await audioRecorder.requestPermission()
            guard hasPermission else {
                // Revert UI state on permission failure
                isRecording = false
                overlayWindow?.hide()
                showErrorAlert(message: "Microphone permission denied. Please grant access in System Settings.")
                return
            }

            do {
                lastRecordingURL = try audioRecorder.startRecording()
            } catch {
                // Revert UI state on recording failure
                isRecording = false
                overlayWindow?.hide()
                showErrorAlert(message: "Failed to start recording.")
                return
            }
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

        // Start transcription
        guard let recordingURL = lastRecordingURL else {
            isShowingCompletion = true
            scheduleOverlayHide()
            return
        }

        guard let apiKey = KeychainStore.loadAPIKey(), !apiKey.isEmpty else {
            showErrorAlert(message: "No API key configured. Please add your OpenAI API key in the menu bar settings.")
            scheduleOverlayHide()
            return
        }

        isTranscribing = true
        transcriptionError = nil

        Task {
            await performTranscription(fileURL: recordingURL, apiKey: apiKey)
        }
    }

    private func performTranscription(fileURL: URL, apiKey: String) async {
        let transcriber = OpenAITranscriber(apiKey: apiKey)

        do {
            let text = try await transcriber.transcribe(fileURL: fileURL)
            isTranscribing = false
            isShowingCompletion = true
            hotkeyManager.pasteText(text)
            scheduleOverlayHide()
        } catch {
            isTranscribing = false
            transcriptionError = errorMessage(for: error)
            showErrorAlert(message: transcriptionError ?? "Transcription failed.")
            scheduleOverlayHide()
        }
    }

    private func errorMessage(for error: Error) -> String {
        if let transcriptionError = error as? TranscriptionError {
            switch transcriptionError {
            case .fileTooLarge:
                return "Audio file exceeds 25MB limit."
            case .apiError(let message):
                return "API error: \(message)"
            case .networkError:
                return "Network error. Check your connection."
            case .invalidURL, .invalidResponse:
                return "Invalid response from server."
            }
        }
        return "Transcription failed: \(error.localizedDescription)"
    }

    private func scheduleOverlayHide() {
        let workItem = DispatchWorkItem { [weak self] in
            self?.isShowingCompletion = false
            self?.transcriptionError = nil
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
    @State private var apiKeyInput: String = ""
    @State private var hasAPIKey: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status
            Text(statusText)
                .foregroundColor(.secondary)

            Divider()

            // API Key Settings
            Text("OpenAI API Key")
                .font(.headline)

            SecureField("sk-...", text: $apiKeyInput)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Save") {
                    saveAPIKey()
                }
                .disabled(apiKeyInput.isEmpty)

                Button("Clear") {
                    clearAPIKey()
                }
                .disabled(!hasAPIKey)

                Spacer()

                if hasAPIKey {
                    Text("Saved")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 260)
        .onAppear {
            loadAPIKey()
        }
    }

    private var statusText: String {
        if sharedAppState.isTranscribing {
            return "Transcribing..."
        } else if sharedAppState.isRecording {
            return "Recording..."
        } else {
            return "VoicePaste is running"
        }
    }

    private func loadAPIKey() {
        if let key = KeychainStore.loadAPIKey(), !key.isEmpty {
            hasAPIKey = true
            // Don't show actual key, just indicate it's set
        } else {
            hasAPIKey = false
        }
    }

    private func saveAPIKey() {
        do {
            try KeychainStore.saveAPIKey(apiKeyInput)
            hasAPIKey = true
            apiKeyInput = ""
        } catch {
            print("[MenuContent] Failed to save API key: \(error)")
        }
    }

    private func clearAPIKey() {
        do {
            try KeychainStore.deleteAPIKey()
            hasAPIKey = false
            apiKeyInput = ""
        } catch {
            print("[MenuContent] Failed to clear API key: \(error)")
        }
    }
}
#endif
