#!/usr/bin/env bash
# PostToolUse hook: records when files are edited so read-dedup allows re-reads.
# Companion to read-dedup.sh.
#
# Install: add to PostToolUse hooks in settings.json with matcher "Edit|Write|MultiEdit"

set -uo pipefail

SESSION_DIR="${HOME}/.local/share/claude-token-tracker/sessions"
mkdir -p "$SESSION_DIR"

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')

if [[ -z "$file_path" ]] || [[ -z "$session_id" ]]; then
  echo '{}'
  exit 0
fi

# Mark file as edited so read-dedup allows re-reading it
echo "$file_path" >> "${SESSION_DIR}/${session_id}.edits"

echo '{}'
