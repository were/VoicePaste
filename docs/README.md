This project aims at providing a voice to text transcription
on MacOS using OpenAI's Whisper model.
Because Apple's voice to transcription is a trash, which is
neither accurate nor language-mixing-friendly.

## Features

- Type and hold `<Option> + <Space>` to start recording
- When released, the audio is sent to OpenAI's Whisper model
- Once reponded, the transcript is injected to your pasteboard
- And it automatically `<Cmd> + <V>` to paste it to the current focused app
- Menu bar indicator shows VoicePaste is running (macOS only)
- Floating timer window shows recording duration in top-right corner

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

## Menu Bar Indicator

On macOS, VoicePaste displays a mic icon in the menu bar to confirm the app is running. The app runs as an agent (no Dock icon) with a minimal menu containing status text and Quit option.

### Manual Verification Checklist

- [ ] Launch the macOS app and confirm a mic icon appears in the menu bar
- [ ] Confirm no Dock icon appears (LSUIElement enabled)
- [ ] Click the menu bar icon to open the menu
- [ ] Verify "VoicePaste is running" status text is displayed
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
