# VoicePaste

This project provides voice-to-text transcription on macOS using OpenAI's Whisper model. VoicePaste is designed to be accurate and language-mixing-friendly, addressing limitations in Apple's built-in voice transcription.

## Features

- **Quick Recording:** Type and hold `Option+Space` to start recording
- **Instant Transcription:** Audio is automatically sent to OpenAI's Whisper model
- **Auto-Paste:** Transcribed text is automatically pasted into your active application
- **Menu Bar Indicator:** Mic icon in the menu bar confirms VoicePaste is running
- **Floating Timer:** Real-time duration display in top-right corner while recording
- **Settings UI:** Configure your API key through the menu bar
- **Local Storage:** API key is stored securely in Application Support

## Getting Started

### Installation

Build the macOS app using Xcode:

```bash
xcodebuild \
  -scheme VoicePaste \
  -configuration Release \
  -destination 'platform=macOS' \
  build
```

### Configuration

1. Get an API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Launch VoicePaste (no Dock icon, check the menu bar for the mic icon)
3. Click the menu bar mic icon
4. Enter your API key in the settings field
5. Click "Save"

### Usage

1. Press and hold `Option+Space` in any application
2. Speak your text (a floating timer shows the duration)
3. Release `Option+Space` when done
4. VoicePaste transcribes the audio and automatically pastes the result

## Permissions

VoicePaste requires three macOS permissions:

### Microphone Permission
**System Settings → Privacy & Security → Microphone → VoicePaste**

Required for voice recording. The app will request this permission on your first recording attempt.

### Accessibility Permission
**System Settings → Privacy & Security → Accessibility → VoicePaste**

Required for simulating the Cmd+V paste command to insert transcribed text into your active application.

### Input Monitoring Permission
**System Settings → Privacy & Security → Input Monitoring → VoicePaste**

Required for detecting the Option+Space hotkey globally across all applications.

## Architecture

VoicePaste is organized into distinct components, each with specific responsibilities:

### Core Components

| Component | Purpose |
|-----------|---------|
| [AudioRecorder](../VoicePaste/AudioRecorder.md) | Records audio in Whisper-optimized format (16kHz mono WAV) |
| [HotkeyManager](../VoicePaste/HotkeyManager.md) | Detects Option+Space globally, manages recording lifecycle |
| [OpenAITranscriber](../VoicePaste/OpenAITranscriber.md) | Sends audio to OpenAI's Whisper API, handles responses |
| [APIKeyStore](../VoicePaste/APIKeyStore.md) | Manages persistent API key storage in Application Support |

### UI Components

| Component | Purpose |
|-----------|---------|
| [RecordingOverlayView](../VoicePaste/RecordingOverlayView.md) | SwiftUI view displaying timer and transcription status |
| [RecordingOverlayWindow](../VoicePaste/RecordingOverlayWindow.md) | NSPanel floating window in top-right corner |
| [VoicePasteApp](../VoicePaste/VoicePasteApp.md) | Main app entry point, state coordination, menu bar UI |

## Known Limitations

- **Not available on Mac App Store:** Due to CGEventTap requirements for global hotkey detection, the app cannot run in the App Sandbox and is unavailable on the Mac App Store.

- **Permission persistence:** If Accessibility or Input Monitoring permissions are revoked while the app is running, the hotkey listener will stop working. Restart the app after re-granting permissions.

- **Paste simulation:** Some applications may not respond to simulated Cmd+V events (rare edge case). In such cases, manually paste from the clipboard.

- **Audio size limit:** The Whisper API has a 25MB file size limit. Typical recordings stay within this limit unless they exceed ~20 minutes at 16kHz.

## Security

The API key is stored as **plaintext in a local file** at:

```
~/Library/Application Support/VoicePaste/api_key
```

### Security Model

- **File permissions:** 0600 (owner read/write only) - other users cannot read the key
- **Plaintext rationale:** Eliminates repeated Keychain permission dialogs for a better user experience
- **User control:** You can clear or update the key anytime through the Settings UI

For detailed information, see [APIKeyStore](../VoicePaste/APIKeyStore.md).

## Troubleshooting

### Microphone Access Required

If you see a "Microphone Access Required" dialog:

1. Open System Settings → Privacy & Security → Microphone
2. Verify VoicePaste is in the list and enabled
3. If not listed, you may need to restart VoicePaste

### Hotkey Not Working

If Option+Space doesn't trigger recording:

1. Verify Input Monitoring permission is granted: System Settings → Privacy & Security → Input Monitoring
2. Verify Accessibility permission is granted: System Settings → Privacy & Security → Accessibility
3. Restart VoicePaste if permissions were recently changed
4. Try the hotkey in a different application

### Transcription Fails

If transcription doesn't work or returns errors:

1. **Missing or invalid API key:** Check your key in the menu bar settings
2. **Network connection:** Verify you have internet connectivity
3. **API credits:** Ensure your OpenAI account has available API credits
4. **Audio too large:** Ensure your recording is under ~20 minutes

For more details, see [OpenAITranscriber](../VoicePaste/OpenAITranscriber.md).

### Text Not Pasting

If the transcribed text doesn't automatically appear:

1. Verify Accessibility permission is granted
2. Some applications may not support automated paste (rare)
3. The text is always in your clipboard, so you can manually paste (Cmd+V) if needed

## Future Work

### Streaming Transcription

Real-time streaming transcription using OpenAI's Realtime API is planned but currently experimental. This would require significant architectural changes and additional dependencies. See [OpenAITranscriber](../VoicePaste/OpenAITranscriber.md) for details.

## Development

For developers working on VoicePaste, refer to the component documentation above for implementation details specific to each module.
