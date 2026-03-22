#!/usr/bin/env bash
# PostToolUse hook: check if written MD file exceeds size limits
# Reads JSON from stdin (Claude Code hook protocol)
set -euo pipefail

# Extract file path from hook input JSON
FILE_PATH=$(jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null)

# Skip if no file path or not a .md file
[[ -z "${FILE_PATH}" ]] && exit 0
[[ "${FILE_PATH}" != *.md ]] && exit 0
[[ ! -f "${FILE_PATH}" ]] && exit 0

LINES=$(wc -l < "${FILE_PATH}" | tr -d ' ')
BASENAME=$(basename "${FILE_PATH}")
DIR=$(dirname "${FILE_PATH}")

# Determine limit based on path pattern
LIMIT=0
LABEL=""

case "${DIR}" in
  *sections*)       LIMIT=300; LABEL="plan section" ;;
  *foundations*)     LIMIT=150; LABEL="architecture foundation" ;;
  *handoffs*)        LIMIT=100; LABEL="handoff" ;;
esac

case "${BASENAME}" in
  CLAUDE.md)              LIMIT=60;  LABEL="CLAUDE.md" ;;
  CURRENT.md)             LIMIT=60;  LABEL="CURRENT.md" ;;
  APP_ARCHITECTURE.md)    LIMIT=150; LABEL="index/hub" ;;
  index.md)               LIMIT=150; LABEL="index/hub" ;;
esac

if [[ "${LIMIT}" -gt 0 && "${LINES}" -gt "${LIMIT}" ]]; then
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"⚠️ ${LABEL} exceeds ${LIMIT}-line limit: ${FILE_PATH} is ${LINES} lines. Split into sub-files per .claude/rules/doc-size-limit.md."}}
EOF
  exit 1
fi

exit 0
