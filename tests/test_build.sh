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

echo ""
echo "=== Build Verification Complete ==="
