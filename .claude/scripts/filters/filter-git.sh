#!/usr/bin/env bash
# Filter git output: compact status, truncate diffs, one-line logs.
# Usage: git status 2>&1 | filter-git.sh status

set -uo pipefail

SUBCMD="${1:-status}"
SAVINGS_LOG="${HOME}/.local/share/claude-token-tracker/savings.jsonl"
input=$(cat)
original_chars=${#input}

filter_status() {
  local staged=0 modified=0 untracked=0 conflicts=0
  local staged_files="" modified_files="" untracked_files=""
  local branch=""

  local current_section=""

  while IFS= read -r line; do
    # Strip hint lines
    case "$line" in
      "(use "*)  continue ;;
      "  (use "*)  continue ;;
    esac

    # Branch info
    if [[ "$line" == "On branch "* ]]; then
      branch="${line#On branch }"
      continue
    fi

    # Track which section we're in
    case "$line" in
      "Changes to be committed"*)
        current_section="staged"
        continue ;;
      "Changes not staged"*)
        current_section="modified"
        continue ;;
      "Unmerged paths:"*)
        current_section="conflicts"
        continue ;;
      "Untracked files:"*)
        current_section="untracked"
        continue ;;
      "no changes"*|"nothing to commit"*|"nothing added"*)
        echo "clean"
        return ;;
    esac

    # Detect file states from porcelain-like patterns
    case "$line" in
      *"new file:"*|*"renamed:"*)
        staged=$((staged + 1))
        staged_files+="  ${line##*:}"$'\n'
        ;;
      *"modified:"*)
        modified=$((modified + 1))
        modified_files+="  ${line##*:}"$'\n'
        ;;
      *"deleted:"*)
        modified=$((modified + 1))
        modified_files+="  ${line##*:}"$'\n'
        ;;
      *"both modified:"*|*"both added:"*)
        conflicts=$((conflicts + 1))
        ;;
      "	"*)
        # Tab-prefixed = file in a section
        local fname="${line#	}"
        case "$current_section" in
          untracked)
            untracked=$((untracked + 1))
            untracked_files+="  $fname"$'\n'
            ;;
          staged)
            staged=$((staged + 1))
            staged_files+="  $fname"$'\n'
            ;;
          modified)
            modified=$((modified + 1))
            modified_files+="  $fname"$'\n'
            ;;
        esac
        ;;
    esac
  done <<< "$input"

  [[ -n "$branch" ]] && echo "* $branch"
  (( staged > 0 ))    && echo "+ Staged: $staged"
  (( modified > 0 ))  && echo "~ Modified: $modified"
  (( untracked > 0 )) && echo "? Untracked: $untracked"
  (( conflicts > 0 )) && echo "! Conflicts: $conflicts"

  # If we couldn't parse anything useful, fall back to compact original
  if (( staged + modified + untracked + conflicts == 0 )) && [[ -z "$branch" ]]; then
    echo "$input" | grep -v '^\s*$' | grep -v '^(use ' | head -50
  fi
}

filter_diff() {
  local line_count=0
  local hunk_lines=0
  local max_hunk=30
  local max_total=500
  local truncated=false
  local current_file=""

  while IFS= read -r line; do
    line_count=$((line_count + 1))
    if (( line_count > max_total )); then
      truncated=true
      break
    fi

    case "$line" in
      "diff --git"*)
        hunk_lines=0
        current_file="${line##*b/}"
        echo "--- $current_file ---"
        continue ;;
      "index "*|"--- a/"*|"+++ b/"*|"\ No newline"*)
        continue ;;
      "@@"*)
        hunk_lines=0
        echo "$line"
        continue ;;
      "+"*|"-"*)
        hunk_lines=$((hunk_lines + 1))
        if (( hunk_lines <= max_hunk )); then
          echo "$line"
        elif (( hunk_lines == max_hunk + 1 )); then
          echo "  ... (hunk truncated)"
        fi
        continue ;;
    esac

    # Context lines — only show if hunk is still within limit
    if (( hunk_lines <= max_hunk )); then
      echo "$line"
    fi
  done <<< "$input"

  if $truncated; then
    echo ""
    echo "... ($line_count+ lines total, showing first $max_total)"
  fi
}

filter_log() {
  local count=0
  local max=15

  while IFS= read -r line; do
    # Skip empty lines and noise
    [[ -z "$line" ]] && continue
    [[ "$line" == "commit "* ]] && continue
    [[ "$line" == "Merge:"* ]] && continue
    [[ "$line" == "Author:"* ]] && continue
    [[ "$line" == "Date:"* ]] && continue
    [[ "$line" == *"Co-authored-by:"* ]] && continue
    [[ "$line" == *"Signed-off-by:"* ]] && continue

    count=$((count + 1))
    if (( count <= max )); then
      echo "${line:0:120}"
    fi
  done <<< "$input"

  if (( count > max )); then
    echo "... +$((count - max)) more commits"
  fi
}

filter_show() {
  # Use diff filter for show output
  filter_diff
}

filter_add() {
  # Replace verbose output with compact confirmation
  if echo "$input" | grep -q "fatal\|error"; then
    echo "$input"
  else
    echo "ok"
  fi
}

filter_commit() {
  # Extract hash and message
  local hash=$(echo "$input" | grep -oE '[0-9a-f]{7,}' | head -1)
  if echo "$input" | grep -q "nothing to commit\|nothing added"; then
    echo "ok (nothing to commit)"
  elif [[ -n "$hash" ]]; then
    echo "ok $hash"
  else
    echo "$input" | head -5
  fi
}

filter_push() {
  if echo "$input" | grep -q "Everything up-to-date"; then
    echo "ok (up-to-date)"
  elif echo "$input" | grep -q "fatal\|error\|rejected"; then
    echo "$input"
  else
    local ref=$(echo "$input" | grep -oE '\S+\.\.\S+' | head -1)
    echo "ok ${ref:-pushed}"
  fi
}

# Run filter
case "$SUBCMD" in
  status) result=$(filter_status) ;;
  diff)   result=$(filter_diff) ;;
  log)    result=$(filter_log) ;;
  show)   result=$(filter_show) ;;
  add)    result=$(filter_add) ;;
  commit) result=$(filter_commit) ;;
  push)   result=$(filter_push) ;;
  *)      result="$input" ;;
esac

compressed_chars=${#result}
echo "$result"

# Log savings
if (( original_chars > 0 )); then
  saved=$((original_chars - compressed_chars))
  pct=$((saved * 100 / original_chars))
  mkdir -p "$(dirname "$SAVINGS_LOG")"
  jq -nc \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg type "git" \
    --arg runner "$SUBCMD" \
    --argjson original "$original_chars" \
    --argjson compressed "$compressed_chars" \
    --argjson saved "$saved" \
    --argjson pct "$pct" \
    '{timestamp:$ts, filter:$type, runner:$runner, original_chars:$original, compressed_chars:$compressed, saved_chars:$saved, reduction_pct:$pct}' \
    >> "$SAVINGS_LOG" 2>/dev/null || true
fi
