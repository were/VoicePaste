# VoicePasteApp

## Purpose

The main app entry point and state coordinator for VoicePaste. Manages the application lifecycle, UI elements, and state transitions across all components.

## Features

VoicePaste provides the following user-facing features:

- **Hotkey Recording:** Type and hold `Option+Space` to start recording
- **Automatic Transcription:** Audio is sent to OpenAI's Whisper model for transcription
- **Auto-Paste:** Transcribed text is automatically pasted into the active application
- **Menu Bar Indicator:** A mic icon in the menu bar confirms VoicePaste is running
- **Floating Timer:** A timer window shows recording duration in the top-right corner
- **Settings UI:** Configure API key in the menu bar settings panel
- **Local Storage:** API key is stored in Application Support directory

## App Lifecycle

VoicePasteApp manages the application lifecycle:

1. **Launch:** App initializes, loads API key if previously saved
2. **Setup:** Hotkey listener and other components are initialized
3. **Running:** App waits for user to press Option+Space to start recording
4. **Shutdown:** App gracefully closes, saves state if needed

### Startup Sequence

On app launch:

1. Create AppState (main state container)
2. Load API key from persistent storage
3. Initialize HotkeyManager to listen for Option+Space
4. Initialize AudioRecorder and OpenAITranscriber
5. Build menu bar UI
6. Show menu bar icon to indicate app is running

## State Coordination

VoicePasteApp uses an `AppState` observable object to coordinate state across all components:

```swift
class AppState: ObservableObject {
    @Published var isRecording: Bool
    @Published var isTranscribing: Bool
    @Published var recordingDuration: Int
    @Published var apiKey: String
    @Published var lastError: String?
}
```

All components (AudioRecorder, HotkeyManager, UI views) read/write to AppState to maintain synchronization.

## Observable Pattern

The app uses SwiftUI's `@ObservedObject` pattern to react to state changes:

- When `isRecording` changes, the timer window appears/disappears
- When `isTranscribing` changes, the UI updates to show progress
- When `apiKey` changes, the API client is updated
- When `lastError` changes, error dialogs are shown

## Menu Bar UI

VoicePasteApp builds a NSMenu for the menu bar:

- **Title:** "VoicePaste is running"
- **API Key Field:** Text input for entering/updating the API key
- **Save Button:** Saves the API key to persistent storage
- **Clear Button:** Deletes the stored API key
- **Quit Button:** Exits the application

The menu bar icon is always visible while the app is running.

## LSUIElement Configuration

VoicePasteApp configures the app as an agent application:

- **Info.plist:** `LSUIElement = YES`
- **Effect:** No Dock icon appears
- **Rationale:** VoicePaste is a utility with only a menu bar presence
- **Behavior:** App runs in background, only menu bar icon is visible

Users interact with the app solely through the menu bar, not through the Dock.

## Error Handling

VoicePasteApp maintains an error state:

- **Recording errors:** Displayed as error dialogs with troubleshooting tips
- **Transcription errors:** Shown in the menu bar or as alerts
- **Permission errors:** Provide links to System Settings for permission management
- **Network errors:** Display "Check your internet connection"

Errors are cleared when the user dismisses them or attempts a new recording.

## Permissions Overview

VoicePasteApp coordinates permission requests:

- **Microphone:** Requested on first recording, with dialog guidance
- **Accessibility:** Required for Cmd+V paste simulation
- **Input Monitoring:** Required for Option+Space hotkey detection

All permission prompts guide users to the appropriate System Settings pane.

## Mac App Store Limitation

Due to `CGEventTap` requirements, VoicePaste cannot be distributed via the Mac App Store. The app must run outside the App Sandbox and requires unrestricted system-level keyboard event access.

## Recording Workflow

The complete recording workflow is:

1. **User presses Option+Space** → HotkeyManager detects event → AppState.isRecording = true
2. **Timer window appears** → RecordingOverlayWindow is shown
3. **Audio is recorded** → AudioRecorder captures microphone input
4. **User releases keys** → HotkeyManager detects release → AppState.isRecording = false
5. **Timer window fades** → Recording overlay animates out
6. **Transcription starts** → AppState.isTranscribing = true → Overlay shows "Transcribing..."
7. **API call to Whisper** → OpenAITranscriber sends audio to API
8. **Transcription completes** → HotkeyManager simulates Cmd+V paste → Text appears in app
9. **Overlay fades** → AppState.isTranscribing = false

## State Transitions

AppState defines the valid state transitions:

- `idle` → `recording` (hotkey pressed)
- `recording` → `transcribing` (hotkey released)
- `transcribing` → `idle` (transcription complete or error)
- `idle` → `error` → `idle` (error handling)

Invalid transitions are prevented, maintaining consistent state.

## Threading Model

VoicePasteApp manages threading across components:

- **Main thread:** UI updates, menu bar rendering
- **Audio thread:** AudioRecorder runs on system audio thread
- **Event tap thread:** HotkeyManager detects events on system event thread
- **API thread:** OpenAITranscriber calls API on background thread

AppState uses thread-safe `@Published` properties to coordinate across threads.
