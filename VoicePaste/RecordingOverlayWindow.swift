//
//  RecordingOverlayWindow.swift
//  VoicePaste
//
//  Created by Claude on 2026/1/11.
//

import AppKit
import SwiftUI

/// A non-activating floating window that displays the recording timer overlay.
/// Appears in the top-right corner without stealing focus from the current application.
@MainActor
final class RecordingOverlayWindow {
    private var panel: NSPanel?
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
    }

    /// Shows the overlay window in the top-right corner of the screen.
    func show() {
        if panel == nil {
            createPanel()
        }

        resizeToFitContent()
        updatePosition(preferredScreen: NSScreen.main)
        panel?.orderFrontRegardless()
    }

    /// Resizes the panel to fit the current content size.
    private func resizeToFitContent() {
        guard let panel = panel,
              let hostingView = panel.contentView as? NSHostingView<RecordingOverlayView> else { return }

        let fittingSize = hostingView.fittingSize
        let currentFrame = panel.frame

        // Resize keeping top-right corner position
        let newOrigin = NSPoint(
            x: currentFrame.maxX - fittingSize.width,
            y: currentFrame.maxY - fittingSize.height
        )
        panel.setFrame(NSRect(origin: newOrigin, size: fittingSize), display: true)
    }

    /// Hides the overlay window.
    func hide() {
        panel?.orderOut(nil)
    }

    /// Updates the window position to the top-right corner of the specified screen.
    func updatePosition(preferredScreen: NSScreen?) {
        guard let panel = panel else { return }

        // Use the screen containing the mouse cursor, falling back to main screen
        let screen = screenContainingMouse() ?? preferredScreen ?? NSScreen.main
        guard let screenFrame = screen?.visibleFrame else { return }

        let windowSize = panel.frame.size
        let padding: CGFloat = 20

        // Position in top-right corner
        let x = screenFrame.maxX - windowSize.width - padding
        let y = screenFrame.maxY - windowSize.height - padding

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func createPanel() {
        guard let appState = appState else { return }

        let contentView = RecordingOverlayView(appState: appState)
        let hostingView = NSHostingView(rootView: contentView)

        // Size to fit content
        let fittingSize = hostingView.fittingSize

        // Create a non-activating panel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: fittingSize.width, height: fittingSize.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Configure panel behavior
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false

        // Set content
        panel.contentView = hostingView

        self.panel = panel
    }

    private func screenContainingMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        }
    }
}
