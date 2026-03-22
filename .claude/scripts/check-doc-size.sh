#!/bin/bash
# PostToolUse hook: check if written MD file exceeds size limits
# Usage: check-doc-size.sh <file_path>

FILE="$1"
[[ ! -f "$FILE" ]] && exit 0
[[ "$FILE" != *.md ]] && exit 0

LINES=$(wc -l < "$FILE" | tr -d ' ')
BASENAME=$(basename "$FILE")
DIR=$(dirname "$FILE")

# Determine limit based on path pattern
LIMIT=0
LABEL=""

if [[ "$DIR" == *"plans/*/sections"* || "$DIR" == *"/sections" ]]; then
  LIMIT=300; LABEL="plan section"
elif [[ "$BASENAME" == "CLAUDE.md" ]]; then
  LIMIT=60; LABEL="CLAUDE.md"
elif [[ "$BASENAME" == "CURRENT.md" ]]; then
  LIMIT=60; LABEL="CURRENT.md"
elif [[ "$DIR" == *"handoffs"* ]]; then
  LIMIT=100; LABEL="handoff"
elif [[ "$DIR" == *"foundations"* ]]; then
  LIMIT=150; LABEL="architecture foundation"
elif [[ "$BASENAME" == "APP_ARCHITECTURE.md" || "$BASENAME" == "index.md" ]]; then
  LIMIT=150; LABEL="index/hub"
fi

if [[ "$LIMIT" -gt 0 && "$LINES" -gt "$LIMIT" ]]; then
  echo "⚠️ ${LABEL} exceeds ${LIMIT}-line limit: ${FILE} is ${LINES} lines. Split into sub-files."
  exit 1
fi

exit 0
