#!/usr/bin/env bash
# PreToolUse hook: blocks redundant Read calls within the same session.
# If a file was already read and hasn't been edited since, block the re-read.
#
# Install: add to PreToolUse hooks in settings.json with matcher "Read"

set -uo pipefail

SESSION_DIR="${HOME}/.local/share/claude-token-tracker/sessions"
mkdir -p "$SESSION_DIR"

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')

# Skip if no file path or session
if [[ -z "$file_path" ]] || [[ -z "$session_id" ]]; then
  exit 0
fi

# Session-specific tracking file
track_file="${SESSION_DIR}/${session_id}.reads"
edit_file="${SESSION_DIR}/${session_id}.edits"

# Check if this file was already read in this session
if [[ -f "$track_file" ]] && /usr/bin/grep -qF "$file_path" "$track_file" 2>/dev/null; then
  # Check if the file was edited since last read (allow re-read after edit)
  if [[ -f "$edit_file" ]] && /usr/bin/grep -qF "$file_path" "$edit_file" 2>/dev/null; then
    # File was edited — allow re-read, clear the edit marker
    sed -i '' "\|${file_path}|d" "$edit_file" 2>/dev/null || true
  else
    # File wasn't edited — block the duplicate read
    jq -nc \
      --arg path "$file_path" \
      '{
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "block",
          permissionDecisionReason: ("You already read " + $path + " in this session and it hasn'\''t been modified. Use the content from your previous read.")
        }
      }'
    exit 0
  fi
fi

# Record this read
echo "$file_path" >> "$track_file"

# Allow the read
exit 0
