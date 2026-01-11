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

## Menu Bar Indicator

On macOS, VoicePaste displays a mic icon in the menu bar to confirm the app is running. The app runs as an agent (no Dock icon) with a minimal menu containing status text and Quit option.

### Manual Verification Checklist

- [ ] Launch the macOS app and confirm a mic icon appears in the menu bar
- [ ] Confirm no Dock icon appears (LSUIElement enabled)
- [ ] Click the menu bar icon to open the menu
- [ ] Verify "VoicePaste is running" status text is displayed
- [ ] Use Quit menu item to exit the app
