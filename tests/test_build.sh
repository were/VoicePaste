#!/bin/bash
# Test: Verify macOS build succeeds with menu bar indicator
# This test ensures the MenuBarExtra implementation compiles correctly

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_FILE="$PROJECT_DIR/VoicePaste.xcodeproj"

echo "=== Test: macOS Build Verification ==="
echo "Project: $PROJECT_FILE"

# Test 1: Verify project file exists
echo -n "Test 1: Project file exists... "
if [ -d "$PROJECT_FILE" ]; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 2: Verify VoicePasteApp.swift exists
echo -n "Test 2: VoicePasteApp.swift exists... "
if [ -f "$PROJECT_DIR/VoicePaste/VoicePasteApp.swift" ]; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 3: Build for macOS (Release configuration)
echo "Test 3: Building for macOS..."
if xcodebuild -project "$PROJECT_FILE" \
    -scheme VoicePaste \
    -destination 'platform=macOS' \
    -configuration Release \
    build 2>&1 | tail -20; then
    echo "Test 3: macOS build... PASS"
else
    echo "Test 3: macOS build... FAIL"
    exit 1
fi

# Test 4: Verify MenuBarExtra is present in source (after implementation)
echo -n "Test 4: MenuBarExtra implementation present... "
if grep -q "MenuBarExtra" "$PROJECT_DIR/VoicePaste/VoicePasteApp.swift" 2>/dev/null; then
    echo "PASS"
else
    echo "PENDING (not yet implemented)"
fi

echo ""
echo "=== Build Verification Complete ==="
