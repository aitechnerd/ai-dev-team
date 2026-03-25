#!/usr/bin/env bash
# PreToolUse hook: blocks redundant Read calls within the same session.
# If a file was already read and hasn't been edited since, block the re-read.
#
# Two dedup layers:
#   1. Session-based: blocks re-reads within same session (original behavior)
#   2. Time-based cache for stable files (SKILL.md, CLAUDE.md, memory): blocks
#      re-reads across agent boundaries for files that don't change mid-session.
#      Cache TTL: 30 minutes (covers typical multi-agent pipeline runs).
#
# Install: add to PreToolUse hooks in settings.json with matcher "Read"

set -uo pipefail

SESSION_DIR="${HOME}/.local/share/claude-token-tracker/sessions"
CACHE_DIR="${SESSION_DIR}/read-cache"
mkdir -p "$SESSION_DIR" "$CACHE_DIR"

# Cache TTL in seconds (30 minutes — covers full pipeline runs)
CACHE_TTL=1800

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')

# Skip if no file path or session
if [[ -z "$file_path" ]] || [[ -z "$session_id" ]]; then
  exit 0
fi

# ---- Layer 2: Time-based cache for stable files ----
# These files don't change during a session, so cache across agent boundaries.
is_stable=false
case "$file_path" in
  */SKILL.md|*/CLAUDE.md|*/MEMORY.md|*/ai-team.md)
    is_stable=true ;;
  */.claude/*/memory/*|*/memory/*.md)
    is_stable=true ;;
  */codemap.md|*/stack.md|*/project-context.md)
    is_stable=true ;;
esac

if $is_stable; then
  # Use md5 hash of path as cache key (safe filename)
  cache_key=$(echo -n "$file_path" | md5 2>/dev/null || echo -n "$file_path" | md5sum 2>/dev/null | cut -d' ' -f1)
  cache_file="${CACHE_DIR}/${cache_key}"

  if [[ -f "$cache_file" ]]; then
    # Check if cache is still fresh
    cache_age=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
    if (( cache_age < CACHE_TTL )); then
      jq -nc \
        --arg path "$file_path" \
        --argjson age "$cache_age" \
        '{
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "block",
            permissionDecisionReason: ("Cached: " + $path + " was read " + ($age | tostring) + "s ago and hasn'\''t changed. Use previous content.")
          }
        }'
      exit 0
    fi
  fi

  # Create/touch cache marker
  echo "$file_path" > "$cache_file"
fi

# ---- Layer 1: Session-based dedup (original) ----
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
