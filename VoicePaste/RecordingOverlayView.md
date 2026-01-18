# RecordingOverlayView

## Purpose

Provides the SwiftUI interface for the floating timer window shown during audio recording. Displays real-time recording duration and transcription status with smooth animations.

## Display Modes

RecordingOverlayView supports multiple display modes:

### Recording Mode

When actively recording:

- Displays the current recording duration in `mm:ss` format (e.g., "00:15")
- Updates every second as the timer increments
- Shows a visual indicator that recording is in progress

### Transcribing Mode

After the user releases the hotkey:

- Displays "Transcribing..." text
- Shows an animated progress indicator
- Indicates that audio is being processed by the Whisper API

### Idle Mode

When not recording:

- The view is hidden or minimal
- Transitions smoothly between states

## Timer Format

The timer displays recording duration as:

- **Format:** `mm:ss` (minutes:seconds)
- **Range:** 00:00 to 99:59
- **Update Frequency:** Every 1 second

### Timer Increments

The timer increments based on actual elapsed time, providing an accurate display of recording duration.

## Animated Progress Indicator

During transcription, an animated progress indicator provides visual feedback that the app is processing the audio:

- **Animation Style:** Continuous rotation or pulse
- **Duration:** Runs until transcription completes
- **Purpose:** Improves perceived latency during API calls

The animation helps users understand that their recording is being processed.

## SwiftUI State Binding

RecordingOverlayView uses SwiftUI's state binding to receive updates from AppState:

- **Recording duration:** Bound to the timer value
- **Display mode:** Bound to the current app state (recording/transcribing/idle)
- **Visibility:** Bound to whether the overlay should be shown

State changes automatically trigger view updates.

## Typography and Styling

The view uses system fonts and sizes optimized for readability in a small floating window:

- **Font:** System font (SF Pro Display or similar)
- **Size:** Large enough for quick glancing (typically 24-32pt)
- **Color:** Contrasting color for visibility on any background
- **Layout:** Centered within the window bounds

## Fade Animation

When recording ends and transitions to idle state:

- The view fades out smoothly over a short duration
- Avoids abrupt disappearance from screen
- Improves visual polish and user experience

## Layout Behavior

The view maintains a fixed size optimized for timer display:

- **Width:** Approximately 120-150 points
- **Height:** Approximately 80-100 points
- **Padding:** Small internal spacing for content

The parent window (RecordingOverlayWindow) handles positioning and anchoring to screen edges.

## Responsive Updates

The view automatically responds to state changes:

- Duration increments trigger a re-render
- Mode transitions trigger animation state updates
- Visibility changes trigger fade animations

Updates are driven by @State bindings from the parent AppState.
