#!/bin/bash
# Test: Verify macOS build succeeds with menu bar indicator
# This test ensures the MenuBarExtra implementation compiles correctly

set -e
set -o pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_FILE="$PROJECT_DIR/VoicePaste.xcodeproj"

echo "=== Test: macOS Build Verification ==="
echo "Project: $PROJECT_FILE"

# Test 1: Build for macOS (Release configuration)
echo "Test 1: Building for macOS..."
BUILD_OUTPUT=$(xcodebuild -project "$PROJECT_FILE" \
    -scheme VoicePaste \
    -destination 'platform=macOS' \
    -configuration Release \
    build 2>&1) && BUILD_STATUS=$? || BUILD_STATUS=$?
echo "$BUILD_OUTPUT" | tail -20
if [ $BUILD_STATUS -eq 0 ]; then
    echo "Test 1: macOS build... PASS"
else
    echo "Test 1: macOS build... FAIL"
    exit 1
fi

# Test 2: Verify MenuBarExtra is present in source
echo -n "Test 2: MenuBarExtra implementation present... "
if grep -q "MenuBarExtra" "$PROJECT_DIR/VoicePaste/VoicePasteApp.swift"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 3: Verify entitlements file exists
echo -n "Test 3: Entitlements file exists... "
if [ -f "$PROJECT_DIR/VoicePaste/VoicePaste.entitlements" ]; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 4: Verify Info.plist exists
echo -n "Test 4: Info.plist file exists... "
if [ -f "$PROJECT_DIR/VoicePaste/Info.plist" ]; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 5: Verify HotkeyManager exists (when implemented)
echo -n "Test 5: HotkeyManager implementation present... "
if [ -f "$PROJECT_DIR/VoicePaste/HotkeyManager.swift" ]; then
    if grep -q "class HotkeyManager" "$PROJECT_DIR/VoicePaste/HotkeyManager.swift"; then
        echo "PASS"
    else
        echo "FAIL (file exists but missing class)"
        exit 1
    fi
else
    echo "SKIP (not yet implemented)"
fi

# Test 6: Verify sandbox is disabled in project
echo -n "Test 6: App sandbox disabled... "
if grep -q "ENABLE_APP_SANDBOX = NO" "$PROJECT_FILE/project.pbxproj"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 7: Verify RecordingOverlayWindow exists
echo -n "Test 7: RecordingOverlayWindow implementation present... "
if [ -f "$PROJECT_DIR/VoicePaste/RecordingOverlayWindow.swift" ]; then
    if grep -q "class RecordingOverlayWindow" "$PROJECT_DIR/VoicePaste/RecordingOverlayWindow.swift"; then
        echo "PASS"
    else
        echo "FAIL (file exists but missing class)"
        exit 1
    fi
else
    echo "FAIL (file not found)"
    exit 1
fi

# Test 8: Verify RecordingOverlayView exists
echo -n "Test 8: RecordingOverlayView implementation present... "
if [ -f "$PROJECT_DIR/VoicePaste/RecordingOverlayView.swift" ]; then
    if grep -q "struct RecordingOverlayView" "$PROJECT_DIR/VoicePaste/RecordingOverlayView.swift"; then
        echo "PASS"
    else
        echo "FAIL (file exists but missing struct)"
        exit 1
    fi
else
    echo "FAIL (file not found)"
    exit 1
fi

# Test 9: Verify RecordingOverlayWindow is wired in AppState
echo -n "Test 9: RecordingOverlayWindow integrated in AppState... "
if grep -q "RecordingOverlayWindow" "$PROJECT_DIR/VoicePaste/VoicePasteApp.swift"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

echo ""
echo "=== Build Verification Complete ==="
