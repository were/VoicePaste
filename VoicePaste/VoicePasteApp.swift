//
//  VoicePasteApp.swift
//  VoicePaste
//
//  Created by Jian Weng on 2026/1/11.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct VoicePasteApp: App {
    var body: some Scene {
        #if os(macOS)
        MenuBarExtra("VoicePaste", systemImage: "mic.fill") {
            Text("VoicePaste is running")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.window)
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}
