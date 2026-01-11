This project aims at providing a voice to text transcription
on MacOS using OpenAI's Whisper model.
Because Apple's voice to transcription is a trash, which is
neither accurate nor language-mixing-friendly.

## Features

- Type and hold `<Option> + <Space>` to start recording
- When released, the audio is sent to OpenAI's Whisper model
- Once reponded, the transcript is injected to your pasteboard
- And it automatically `<Cmd> + <V>` to paste it to the current focused app
