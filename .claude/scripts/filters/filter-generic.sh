#!/usr/bin/env bash
# Filter noisy command output: truncate long listings, strip install progress.
# Usage: find . -name "*.rs" 2>&1 | filter-generic.sh find

set -uo pipefail

CMD="${1:-generic}"
SAVINGS_LOG="${HOME}/.local/share/claude-token-tracker/savings.jsonl"
input=$(cat)
original_chars=${#input}

filter_ls() {
  # Keep first 30 lines, add count
  local total_lines
  total_lines=$(echo "$input" | wc -l | tr -d ' ')
  if (( total_lines <= 30 )); then
    echo "$input"
  else
    echo "$input" | head -30
    echo "... ($total_lines entries total)"
  fi
}

filter_find() {
  # Keep first 40 results, add count
  local total_lines
  total_lines=$(echo "$input" | wc -l | tr -d ' ')
  if (( total_lines <= 40 )); then
    echo "$input"
  else
    echo "$input" | head -40
    echo "... ($total_lines files total)"
  fi
}

filter_pip() {
  local result=""
  local installed=0
  local already=0
  local errors=""

  while IFS= read -r line; do
    case "$line" in
      "Collecting "*|"Downloading "*|"  Downloading "*|"Using cached"*|"  Using cached"*)
        continue ;;
      "Installing collected"*|"Successfully installed"*)
        installed=$((installed + 1))
        result+="$line"$'\n' ;;
      "Requirement already satisfied"*)
        already=$((already + 1)) ;;
      "ERROR:"*|"error:"*|"WARNING:"*|"Could not"*)
        errors+="$line"$'\n' ;;
      *)
        # Skip progress bars and other noise
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^\[.*\] ]] && continue  # progress indicators
        ;;
    esac
  done <<< "$input"

  if [[ -n "$errors" ]]; then
    echo "$errors"
  fi
  if [[ -n "$result" ]]; then
    echo "$result"
  fi
  if (( already > 0 )); then
    echo "$already packages already satisfied"
  fi
  if [[ -z "$result" && -z "$errors" && already -eq 0 ]]; then
    echo "ok"
  fi
}

filter_npm() {
  local result=""
  local has_error=false

  while IFS= read -r line; do
    case "$line" in
      "npm warn"*|"npm WARN"*|"npm notice"*)
        continue ;;
      "npm error"*|"npm ERR!"*)
        has_error=true
        result+="$line"$'\n' ;;
      "added "*"packages"*|"removed "*"packages"*|"up to date"*|"audited"*)
        result+="$line"$'\n' ;;
      *"vulnerabilities"*)
        result+="$line"$'\n' ;;
    esac
  done <<< "$input"

  if [[ -n "$result" ]]; then
    echo "$result"
  else
    echo "ok"
  fi
}

filter_brew() {
  local result=""

  while IFS= read -r line; do
    case "$line" in
      "==> Downloading"*|"==> Pouring"*|"Already downloaded"*|"###"*)
        continue ;;
      "==> "*|"Error:"*|"Warning:"*|"🍺"*)
        result+="$line"$'\n' ;;
    esac
  done <<< "$input"

  if [[ -n "$result" ]]; then
    echo "$result"
  else
    echo "ok"
  fi
}

# Run filter
case "$CMD" in
  ls)    result=$(filter_ls) ;;
  find)  result=$(filter_find) ;;
  pip)   result=$(filter_pip) ;;
  npm)   result=$(filter_npm) ;;
  brew)  result=$(filter_brew) ;;
  *)     result="$input" ;;
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
    --arg type "generic" \
    --arg runner "$CMD" \
    --argjson original "$original_chars" \
    --argjson compressed "$compressed_chars" \
    --argjson saved "$saved" \
    --argjson pct "$pct" \
    '{timestamp:$ts, filter:$type, runner:$runner, original_chars:$original, compressed_chars:$compressed, saved_chars:$saved, reduction_pct:$pct}' \
    >> "$SAVINGS_LOG" 2>/dev/null || true
fi
