#!/bin/bash
# Take a screenshot from connected Android device, resize to fit context window
# Usage: ./scripts/screenshot.sh [output_path] [max_dimension]

OUT="${1:-/tmp/screenshot.png}"
MAX_DIM="${2:-1000}"

adb exec-out screencap -p > "$OUT" 2>/dev/null
if [ $? -ne 0 ]; then
  echo "ERROR: adb screencap failed — is device connected?"
  exit 1
fi

# Resize on macOS using sips
sips -Z "$MAX_DIM" "$OUT" >/dev/null 2>&1

echo "$OUT"
