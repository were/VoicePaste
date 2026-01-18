# HotkeyManager

## Purpose

Manages global hotkey detection and state transitions for VoicePaste. Implements the `Option+Space` hotkey listener to start and stop audio recording.

## Features

- Detects `Option+Space` key combination globally across all applications
- Initiates recording when the combination is pressed
- Stops recording when the combination is released
- Provides real-time state feedback for UI updates

## Core Architecture

### CGEventTap

HotkeyManager uses `CGEventTap` to monitor low-level keyboard events system-wide. This requires special permissions and makes the app incompatible with the Mac App Store sandbox.

The event tap:

- Monitors modifier keys (Option/Alt)
- Monitors spacebar key
- Detects both press and release events
- Runs on a separate thread to avoid blocking the main thread

### Option+Space State Machine

The hotkey manager maintains a state machine for Option+Space:

1. **Idle:** Waiting for user input
2. **Waiting for Space:** Option key is held, waiting for spacebar
3. **Recording:** Both keys are held, recording is active
4. **Released:** One or both keys released, recording stops

The state transitions enable precise recording start/stop timing.

## Accessibility Permissions

VoicePaste requires Accessibility permission to simulate keyboard events (Cmd+V for pasting). This permission must be granted via:

**System Settings → Privacy & Security → Accessibility → VoicePaste**

### Input Monitoring Permission

VoicePaste also requires Input Monitoring permission to detect the Option+Space hotkey:

**System Settings → Privacy & Security → Input Monitoring → VoicePaste**

Both permissions are required for full hotkey functionality.

## Paste Simulation

After transcription completes, HoiceyManager uses accessibility events to simulate `Cmd+V` paste, inserting the transcribed text into the active application.

### Known Limitations

Some applications may not respond to simulated Cmd+V events (rare edge case). In such cases, users can manually paste from the clipboard.

## Permission State

If Accessibility or Input Monitoring permissions are revoked while the app is running:

- The hotkey listener will stop working
- The app must be restarted to re-establish the event tap
- Users must re-grant permissions via System Settings

## Mac App Store Restrictions

Due to the requirement for `CGEventTap`, VoicePaste cannot be distributed via the Mac App Store and must run outside the App Sandbox. The CGEventTap architecture requires unrestricted access to system-wide keyboard events, which violates App Sandbox restrictions.

## Thread Safety

HotkeyManager maintains thread-safe state to prevent race conditions between:

- The event tap thread (detecting key events)
- The main UI thread (requesting recording state)

State transitions use atomic operations or locks as appropriate.
