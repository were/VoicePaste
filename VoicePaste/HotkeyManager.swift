import AppKit
import CoreGraphics
import ApplicationServices
import os.lock

private enum KeyCode: Sendable {
    static let leftOption: Int64 = 58
    static let rightOption: Int64 = 61
    static let space: Int64 = 49
    static let v: UInt16 = 9
}

@MainActor
final class HotkeyManager {
    var onRecordingStart: (() -> Void)?
    var onRecordingStop: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // Thread-safe state using lock for access from event tap callback
    private let stateLock = OSAllocatedUnfairLock(initialState: (isOptionPressed: false, isRecording: false))

    func start() -> Bool {
        guard checkAccessibilityPermission() else {
            openAccessibilitySettings()
            return false
        }

        return setupEventTap()
    }

    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        stateLock.withLock { state in
            state.isOptionPressed = false
            state.isRecording = false
        }
    }

    func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        simulatePaste()
    }

    // MARK: - Private Methods

    private func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    private func setupEventTap() -> Bool {
        let eventMask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: refcon
        ) else {
            return false
        }

        eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        return true
    }

    private nonisolated func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        // Local constants to avoid MainActor isolation warnings
        let kLeftOption: Int64 = 58
        let kRightOption: Int64 = 61
        let kSpace: Int64 = 49

        if type == .flagsChanged {
            let flags = event.flags
            let optionPressed = flags.contains(.maskAlternate)
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

            let isOptionKey = keyCode == kLeftOption || keyCode == kRightOption

            if isOptionKey {
                // Update state synchronously with lock, then call handler on main actor
                let shouldStopRecording = stateLock.withLock { state -> Bool in
                    let wasOptionPressed = state.isOptionPressed
                    state.isOptionPressed = optionPressed

                    if wasOptionPressed && !optionPressed && state.isRecording {
                        // Option released while recording -> stop recording
                        state.isRecording = false
                        return true
                    }
                    return false
                }

                if shouldStopRecording {
                    Task { @MainActor in
                        self.onRecordingStop?()
                    }
                }
            }
        } else if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

            if keyCode == kSpace {
                // Check state synchronously with lock
                let shouldStartRecording = stateLock.withLock { state -> Bool in
                    if state.isOptionPressed && !state.isRecording {
                        // Option held + Space pressed -> start recording
                        state.isRecording = true
                        return true
                    }
                    return false
                }

                if shouldStartRecording {
                    Task { @MainActor in
                        self.onRecordingStart?()
                    }
                    // Suppress space key when starting recording
                    return nil
                }

                // Also suppress space if Option is held but already recording
                if event.flags.contains(.maskAlternate) {
                    return nil
                }
            }
        }

        return Unmanaged.passRetained(event)
    }

    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: KeyCode.v, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: KeyCode.v, keyDown: false) else {
            return
        }

        // Add Command modifier
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
