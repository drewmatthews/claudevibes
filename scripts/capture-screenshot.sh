#!/bin/bash
#
# Capture a screenshot of ClaudeVibes for the website
# Usage: ./scripts/capture-screenshot.sh [output-path]
#
# The app captures its own window content internally for reliability.
#

set -e

# Configuration
APP_NAME="ClaudeVibes"
DEFAULT_OUTPUT="website/img/Screenshot.png"
OUTPUT_PATH="${1:-$DEFAULT_OUTPUT}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCREENSHOT_PATH_FILE="/tmp/claudevibes_screenshot_path"

# Convert to absolute path if relative
if [[ "$OUTPUT_PATH" != /* ]]; then
    OUTPUT_PATH="$PROJECT_DIR/$OUTPUT_PATH"
fi

# Find the built app
APP_PATH="$PROJECT_DIR/build/Build/Products/Release/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
    # Try DerivedData location
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "$APP_NAME.app" -path "*/Release/*" 2>/dev/null | head -1)
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "Error: Could not find $APP_NAME.app"
    echo "Please build the app in Release mode first:"
    echo "  xcodebuild -project ClaudeVibes.xcodeproj -scheme ClaudeUsageMenu -configuration Release build"
    exit 1
fi

echo "Using app: $APP_PATH"
echo "Output path: $OUTPUT_PATH"

# Clean up any previous files
rm -f "$SCREENSHOT_PATH_FILE"

# Kill any existing instance
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5

# Launch in screenshot mode with output path
# The app will capture its own window and save to the specified path
echo "Launching $APP_NAME in screenshot mode..."
"$APP_PATH/Contents/MacOS/$APP_NAME" --screenshot --output "$OUTPUT_PATH" &
APP_PID=$!

# Wait for the app to finish (it exits automatically after capturing)
echo "Waiting for screenshot capture..."
TIMEOUT=10
for i in $(seq 1 $TIMEOUT); do
    if ! kill -0 $APP_PID 2>/dev/null; then
        break
    fi
    sleep 1
done

# Kill if still running
kill $APP_PID 2>/dev/null || true

# Verify output
if [[ -f "$OUTPUT_PATH" ]]; then
    echo "Screenshot saved successfully!"
    file "$OUTPUT_PATH"
    ls -la "$OUTPUT_PATH"
else
    echo "Error: Screenshot was not saved to $OUTPUT_PATH"
    # Check if it was saved to temp location
    if [[ -f "$SCREENSHOT_PATH_FILE" ]]; then
        ACTUAL_PATH=$(cat "$SCREENSHOT_PATH_FILE")
        echo "Screenshot was saved to: $ACTUAL_PATH"
    fi
    exit 1
fi
