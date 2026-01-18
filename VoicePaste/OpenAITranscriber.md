# OpenAITranscriber

## Purpose

Handles communication with OpenAI's Whisper API for audio transcription. Converts recorded audio files into text transcripts.

## Whisper API Integration

OpenAITranscriber sends recorded audio files to OpenAI's Whisper API endpoint and receives the transcribed text in response.

### Request Format

Audio is sent using multipart form-data encoding:

- **Endpoint:** OpenAI Whisper API
- **Method:** POST
- **Content-Type:** multipart/form-data
- **Parameters:**
  - `file`: The WAV audio file
  - `model`: `whisper-1` (Whisper model)

### File Size Limits

Whisper API has a maximum file size limit of **25MB**. If an audio file exceeds this limit, the API will reject the request. For typical audio recordings:

- 16kHz mono WAV format
- Recording times under ~20 minutes should stay within the limit

## Transcription Behavior

When the user releases `Option+Space` after recording:

1. The overlay shows "Transcribing..." with an animated progress indicator
2. The audio file is sent to OpenAI's Whisper API
3. On success: The transcript is pasted into the active application
4. On failure: An error message is displayed to the user

The animated progress indicator provides visual feedback during the API call, improving perceived latency.

## Error Handling

Common transcription errors include:

- **Missing API key:** No API key is configured in settings. User must enter a valid key.
- **Invalid API key:** The API key is incorrect, revoked, or lacks sufficient permissions. Check the key in OpenAI's dashboard.
- **Network failure:** Network connectivity issue preventing API communication. Verify internet connection.
- **Audio too large:** Recording exceeds the 25MB file size limit. Record shorter audio.
- **API service error:** OpenAI service is unavailable or returned a server error. Retry after a brief delay.
- **Invalid audio format:** The audio file is not a valid WAV file. This should not occur with AudioRecorder, but indicates an internal error.

Errors are displayed to the user in the recording overlay.

## TranscriptionService Protocol

OpenAITranscriber implements the `TranscriptionService` protocol, allowing different transcription implementations to be substituted:

```swift
protocol TranscriptionService {
    func transcribe(_ audioFileURL: URL) async throws -> String
}
```

This protocol enables:

- Testing with mock transcription services
- Future support for alternative transcription backends
- Dependency injection in AppState

## API Key Validation

Before transcription, the API key is verified to be non-empty. If the key is missing, transcription is not attempted and an error is displayed immediately.

## Streaming Transcription (Future)

Full real-time streaming transcription using OpenAI's Realtime API is considered experimental and gated on:

1. **Verified Documentation:** Official OpenAI Realtime transcription documentation must be confirmed
2. **Proof of Concept:** A minimal POC must demonstrate working streaming transcription before any integration

The current batch Whisper workflow provides reliable transcription with animated progress feedback. Streaming integration would require significant architectural changes (~850+ LOC) including AVAudioEngine, audio resampling, WebSocket handling, and delta event processing.
