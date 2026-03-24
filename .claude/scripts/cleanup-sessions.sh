#!/usr/bin/env bash
# Clean up stale session tracking files older than 24 hours.
# Called from session-start or standalone.

SESSION_DIR="${HOME}/.local/share/claude-token-tracker/sessions"
[[ -d "$SESSION_DIR" ]] || exit 0

find "$SESSION_DIR" -name "*.reads" -mtime +1 -delete 2>/dev/null || true
find "$SESSION_DIR" -name "*.edits" -mtime +1 -delete 2>/dev/null || true
