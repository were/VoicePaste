This project aims at providing a voice to text transcription
on MacOS using OpenAI's Whisper model.
Because Apple's voice to transcription is a trash, which is
neither accurate nor language-mixing-friendly.

## Features

- Type and hold `<Option> + <Space>` to start recording
- When released, the audio is sent to OpenAI's Whisper model for transcription
- Once transcribed, the text is automatically pasted into your current focused app
- Menu bar indicator shows VoicePaste is running (macOS only)
- Floating timer window shows recording duration in top-right corner
- Settings UI in menu bar for API key configuration
- Local file-based API key storage in Application Support

## Permissions

VoicePaste requires the following macOS permissions to function:

### Accessibility Permission
Required for simulating keyboard events (Cmd+V paste). Grant via:
**System Settings → Privacy & Security → Accessibility → VoicePaste**

### Input Monitoring Permission
Required for detecting Option+Space hotkey. Grant via:
**System Settings → Privacy & Security → Input Monitoring → VoicePaste**

### Microphone Permission
Required for voice recording. Grant via:
**System Settings → Privacy & Security → Microphone → VoicePaste**

The app will request microphone permission on your first recording attempt. If denied, an error alert will be shown.

**Note:** If permissions are not granted, VoicePaste will prompt you to open System Settings. You may need to restart the app after granting permissions.

## Known Limitations

- **Not available on Mac App Store**: Due to CGEventTap requirements, the app must run outside the App Sandbox and cannot be distributed via the Mac App Store.
- **Permission persistence**: If Accessibility or Input Monitoring permissions are revoked while the app is running, the hotkey listener will stop working. Restart the app after re-granting permissions.
- **Paste simulation**: Some apps may not respond to simulated Cmd+V events (rare). In such cases, manually paste from clipboard.

## API Key Setup

VoicePaste requires an OpenAI API key for transcription:

1. Get an API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Click the VoicePaste menu bar icon
3. Enter your API key in the settings field
4. Click "Save" to store locally

The API key is stored in a local file at `~/Library/Application Support/VoicePaste/api_key` with owner-only read/write permissions. You can clear the key at any time using the "Clear" button in settings.

**Security Note:** The API key is stored in plaintext on disk. This trade-off eliminates repeated Keychain permission prompts while maintaining a simple user experience. The file is protected with restrictive permissions (owner read/write only).

### Transcription Behavior

When you release Option+Space after recording:
1. The overlay shows "Transcribing..." with an animated progress indicator while processing
2. Audio is sent to OpenAI's Whisper API
3. On success: transcript is pasted to your active application
4. On failure: an error message is displayed

The animated indicator provides visual feedback that transcription is in progress, improving perceived latency during API calls.

**Common errors:**
- Missing API key: Configure your key in the menu bar settings
- Invalid API key: Check your key is correct and has available credits
- Network failure: Check your internet connection
- Audio too large: Whisper has a 25MB file size limit

## Menu Bar Indicator

On macOS, VoicePaste displays a mic icon in the menu bar to confirm the app is running. The app runs as an agent (no Dock icon) with a minimal menu containing status text and Quit option.

### Manual Verification Checklist

- [ ] Launch the macOS app and confirm a mic icon appears in the menu bar
- [ ] Confirm no Dock icon appears (LSUIElement enabled)
- [ ] Click the menu bar icon to open the menu
- [ ] Verify "VoicePaste is running" status text is displayed
- [ ] Verify API key input field is displayed
- [ ] Enter an API key and click Save
- [ ] Quit and relaunch app, verify key is persisted
- [ ] Click Clear to remove the API key
- [ ] Use Quit menu item to exit the app

## Audio Recording

VoicePaste records audio in a format optimized for OpenAI's Whisper transcription:
- **Format:** WAV (PCM)
- **Sample Rate:** 16kHz
- **Channels:** Mono
- **Bit Depth:** 16-bit

When you hold Option+Space, the app:
1. Requests microphone permission if not already granted
2. Starts recording to a temporary WAV file
3. Shows the recording overlay and timer
4. Stops recording when you release the keys
5. Saves the audio file for transcription

The temporary recording file is automatically replaced on each new recording.

## Floating Timer Window

When you press Option+Space to start recording, a floating timer window appears in the top-right corner of your screen. The timer displays the recording duration in mm:ss format and updates every second.

The window:
- Appears without stealing focus from your current application
- Shows real-time duration while recording
- Displays the final duration briefly when recording stops
- Fades out automatically after recording ends

### Manual Verification Checklist

- [ ] Press Option+Space and confirm the timer window appears in the top-right corner
- [ ] Verify the timer starts at 00:00 and increments every second
- [ ] Confirm the current application retains focus (window does not steal focus)
- [ ] Release Option+Space and verify the final duration is displayed briefly
- [ ] Confirm the timer window fades out and disappears after recording stops

## Future Work

### Streaming Transcription (Experimental)

Full real-time streaming transcription using OpenAI's Realtime API is considered experimental and gated on:

1. **Verified Documentation**: Official OpenAI Realtime transcription documentation must be confirmed
2. **Proof of Concept**: A minimal POC must demonstrate working streaming transcription before any integration

The current batch Whisper workflow provides reliable transcription with the animated progress indicator for feedback. Streaming integration would require significant changes (~850+ LOC) including AVAudioEngine, audio resampling, WebSocket handling, and delta event processing.
