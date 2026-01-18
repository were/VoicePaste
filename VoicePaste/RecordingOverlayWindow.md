# RecordingOverlayWindow

## Purpose

Manages the floating timer window that appears during audio recording. Uses NSPanel to create a borderless, always-visible window positioned in the screen's top-right corner.

## Window Configuration

RecordingOverlayWindow creates an NSPanel with specialized settings:

- **Type:** NSPanel (floating utility window)
- **Appearance:** Borderless, rounded corners
- **Behavior:** Always visible, does not take focus from other windows
- **Level:** Floating above normal windows but below alerts

### Panel Settings

The panel is configured with:

- `level = .floating` - Stays above most other windows
- `isFloatingPanel = true` - Behaves as a floating utility panel
- `canHide = true` - Can be hidden without closing
- `hidesOnDeactivate = false` - Remains visible when app is not active

## Positioning Strategy

The window automatically positions itself in the screen's **top-right corner**:

### Initial Positioning

On first display:

1. Get the current screen frame
2. Calculate top-right position with small margin (typically 16-20 points)
3. Position the panel with its top-right corner aligned to the screen edge

### Multi-Screen Support

VoicePaste supports multi-monitor setups:

- The window appears on the screen containing the mouse cursor or main display
- The window repositions if the app is moved to a different monitor

## Layout Refresh Behavior

RecordingOverlayWindow implements layout refresh to handle content changes:

### Content Transitions

When the displayed content changes:

- From timer duration (e.g., "00:15")
- To transcription status (e.g., "Transcribing...")

The window:

1. Re-measures the content size
2. Adjusts window dimensions if needed
3. May re-anchor to screen edge to avoid truncation

This prevents text from being cut off at screen edges.

## Focus Behavior

The floating window is designed to never steal focus:

- **First responder:** Window does not become key window
- **Click passthrough:** May allow clicks to pass through to windows below (configurable)
- **Active app:** App remains active but window doesn't steal focus

This preserves the user's active application context while showing the timer.

## Transparency and Styling

The window typically has:

- **Background:** Semi-transparent dark or light background
- **Alpha:** Slightly transparent for visual subtlety (typically 0.8-0.95)
- **Shadow:** Optional drop shadow for visual separation

These settings make the window visible while not dominating the screen.

## Content Hosting

RecordingOverlayWindow hosts the RecordingOverlayView SwiftUI view:

- **Root View:** RecordingOverlayView instance
- **Host Controller:** NSHostingController to bridge SwiftUI to AppKit
- **View Controller:** Manages the view lifecycle

## Fade Animation

When recording ends:

- The window fades out smoothly
- Duration is typically 300-500ms
- After fade completes, the window is hidden

This provides a smooth transition from "recording active" to "idle" states.

## Manual Verification Checklist

- [ ] Press Option+Space and confirm the timer window appears in the top-right corner
- [ ] Verify the timer starts at 00:00 and increments every second
- [ ] Confirm the current application retains focus (window does not steal focus)
- [ ] Release Option+Space and verify the final duration is displayed briefly
- [ ] Verify "Transcribing..." overlay is fully visible and not truncated at screen edge
- [ ] Confirm the timer window fades out and disappears after recording stops
- [ ] Test on multiple monitors (if available) - window should appear on the correct screen
- [ ] Verify the window remains visible even when other apps are in focus

## Positioning and Edge Cases

The window is anchored to the screen edge and handles:

- **Screen edge collision:** If content would extend beyond screen bounds, the window re-anchors
- **Multiple monitors:** Window appears on the screen containing the cursor or main display
- **Resolution changes:** Window repositions if screen resolution changes during recording
- **Dock location:** Window accounts for Dock position (bottom, left, or right)

Edge case handling ensures the timer is always visible and readable.
