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
    var transcriberFactory: (String, String?) -> TranscriptionService = { apiKey, prompt in
        OpenAITranscriber(apiKey: apiKey, prompt: prompt)
    }
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
            print("[AppState] Requesting microphone permission...")
            let hasPermission = await audioRecorder.requestPermission()
            print("[AppState] Microphone permission result: \(hasPermission)")

            guard hasPermission else {
                // Revert UI state on permission failure
                print("[AppState] Showing microphone access required dialog")
                isRecording = false
                overlayWindow?.hide()
                showErrorAlert(message: "Microphone permission denied. Please grant access in System Settings.")
                showErrorAlert(
                    message: "VoicePaste needs microphone access to record audio. Click 'Open System Settings' to grant permission.",
                    title: "Microphone Access Required",
                    actionButton: (title: "Open System Settings", handler: { [weak self] in
                        print("[AppState] Opening microphone settings")
                        self?.openMicrophoneSettings()
                    }),
                    cancelTitle: "Cancel"
                )
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

        guard let apiKey = APIKeyStore.loadAPIKey(), !apiKey.isEmpty else {
            showErrorAlert(message: "No API key configured. Please add your OpenAI API key in the menu bar settings.")
            scheduleOverlayHide()
            return
        }

        isTranscribing = true
        transcriptionError = nil

        // Re-anchor overlay on next run loop after SwiftUI layout updates
        DispatchQueue.main.async { [weak self] in
            self?.overlayWindow?.refreshLayout()
        }

        let prompt = APIKeyStore.loadPrompt()
        Task {
            await performTranscription(fileURL: recordingURL, apiKey: apiKey, prompt: prompt)
        }
    }

    private func performTranscription(fileURL: URL, apiKey: String, prompt: String?) async {
        let transcriber = transcriberFactory(apiKey, prompt)

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

    private func showErrorAlert(
        message: String,
        title: String = "VoicePaste Error",
        actionButton: (title: String, handler: () -> Void)? = nil,
        cancelTitle: String = "OK"
    ) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning

        if let action = actionButton {
            alert.addButton(withTitle: action.title)
            alert.addButton(withTitle: cancelTitle)
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                action.handler()
            }
        } else {
            alert.addButton(withTitle: cancelTitle)
            alert.runModal()
        }
    }

    private func openMicrophoneSettings() {
        // Try to open Microphone privacy pane directly
        let microphoneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!

        if NSWorkspace.shared.open(microphoneURL) {
            return
        }

        // Fallback to Privacy & Security pane
        let privacyURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
        NSWorkspace.shared.open(privacyURL)
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
        MenuBarExtra("VoicePaste", image: "MenuBarIcon") {
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
    @State private var transcriptionPrompt: String = ""
    @State private var savedPrompt: String = ""
    @State private var hasPrompt: Bool = false

    private var isPromptModified: Bool {
        transcriptionPrompt != savedPrompt
    }

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

            // Transcription Prompt Settings
            Text("Transcription Prompt")
                .font(.headline)

            ZStack(alignment: .topLeading) {
                if transcriptionPrompt.isEmpty {
                    Text("Names, terms to improve accuracy...")
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
                TextEditor(text: $transcriptionPrompt)
                    .font(.body)
                    .scrollContentBackground(.hidden)
            }
            .frame(minHeight: 60, maxHeight: 120)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )

            HStack {
                Button("Save") {
                    savePrompt()
                }
                .disabled(transcriptionPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasPrompt)

                Button("Clear") {
                    clearPrompt()
                }
                .disabled(!hasPrompt)

                Spacer()

                if isPromptModified {
                    Text("Modified")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if hasPrompt {
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
            loadPrompt()
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
        if let key = APIKeyStore.loadAPIKey(), !key.isEmpty {
            hasAPIKey = true
            // Don't show actual key, just indicate it's set
        } else {
            hasAPIKey = false
        }
    }

    private func saveAPIKey() {
        do {
            try APIKeyStore.saveAPIKey(apiKeyInput)
            hasAPIKey = true
            apiKeyInput = ""
        } catch {
            print("[MenuContent] Failed to save API key: \(error)")
        }
    }

    private func clearAPIKey() {
        do {
            try APIKeyStore.deleteAPIKey()
            hasAPIKey = false
            apiKeyInput = ""
        } catch {
            print("[MenuContent] Failed to clear API key: \(error)")
        }
    }

    private func loadPrompt() {
        if let prompt = APIKeyStore.loadPrompt(), !prompt.isEmpty {
            transcriptionPrompt = prompt
            savedPrompt = prompt
            hasPrompt = true
        } else {
            transcriptionPrompt = ""
            savedPrompt = ""
            hasPrompt = false
        }
    }

    private func savePrompt() {
        do {
            try APIKeyStore.savePrompt(transcriptionPrompt)
            savedPrompt = transcriptionPrompt
            hasPrompt = !transcriptionPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            print("[MenuContent] Failed to save prompt: \(error)")
        }
    }

    private func clearPrompt() {
        do {
            try APIKeyStore.deletePrompt()
            hasPrompt = false
            transcriptionPrompt = ""
            savedPrompt = ""
        } catch {
            print("[MenuContent] Failed to clear prompt: \(error)")
        }
    }
}
#endif
