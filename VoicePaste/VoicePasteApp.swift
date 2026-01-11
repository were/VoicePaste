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
    let hotkeyManager = HotkeyManager()
    private var isSetup = false

    func setup() {
        guard !isSetup else { return }
        isSetup = true
        hotkeyManager.onRecordingStart = { [weak self] in self?.isRecording = true }
        hotkeyManager.onRecordingStop = { [weak self] in self?.isRecording = false }
        _ = hotkeyManager.start()
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
