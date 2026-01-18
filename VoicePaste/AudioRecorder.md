# AudioRecorder

## Purpose

Handles audio recording functionality for VoicePaste. Records audio in a format optimized for OpenAI's Whisper transcription model.

## Audio Format

VoicePaste records audio with the following specifications:

- **Format:** WAV (PCM)
- **Sample Rate:** 16kHz
- **Channels:** Mono
- **Bit Depth:** 16-bit

This format is optimized for accurate transcription by the Whisper model.

## Recording Lifecycle

When the user holds `Option+Space`:

1. Microphone permission is requested if not already granted
2. Recording starts to a temporary WAV file
3. The recording overlay and timer window are displayed
4. Recording continues until the user releases the keys
5. The audio file is saved for transcription

The temporary recording file is automatically replaced on each new recording.

## Microphone Permission

VoicePaste requires microphone permission to record audio. The permission can be granted via:

**System Settings → Privacy & Security → Microphone → VoicePaste**

### Permission State Machine

The app implements a permission state machine:

- **First recording attempt:** If permission has not been requested, the app requests it from the system
- **Permission granted:** Recording proceeds normally
- **Permission denied:** A "Microphone Access Required" dialog appears with an "Open System Settings" button that navigates to the Microphone privacy pane (or Privacy & Security if unavailable)
- **Permission revoked while running:** The app will prompt to open System Settings on the next recording attempt

**Note:** Users may need to restart the app after granting permissions for changes to take effect.

## Temporary File Management

Audio is recorded to a temporary file during each recording session. The file path is managed internally and automatically replaced when a new recording begins.

## Error Handling

The following errors may occur during recording:

- **Audio engine setup failure:** The audio engine or recording session could not be initialized
- **Permission denied:** User denied microphone permission
- **Microphone unavailable:** No microphone device is available
- **File I/O error:** The temporary file could not be created or written

Errors are propagated to the app's error handling system for user display.
