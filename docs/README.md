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

## Permissions

VoicePaste requires the following macOS permissions to function:

### Accessibility Permission
Required for simulating keyboard events (Cmd+V paste). Grant via:
**System Settings → Privacy & Security → Accessibility → VoicePaste**

### Input Monitoring Permission
Required for detecting Option+Space hotkey. Grant via:
**System Settings → Privacy & Security → Input Monitoring → VoicePaste**

### Microphone Permission
Required for voice recording (future feature). Grant via:
**System Settings → Privacy & Security → Microphone → VoicePaste**

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
