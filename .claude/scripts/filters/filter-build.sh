#!/usr/bin/env bash
# Filter build/lint output: on success show "ok", on failure show errors only.
# Usage: cargo build 2>&1 | filter-build.sh cargo

set -uo pipefail

TOOL="${1:-cargo}"
SAVINGS_LOG="${HOME}/.local/share/claude-token-tracker/savings.jsonl"
input=$(cat)
original_chars=${#input}

filter_cargo() {
  local errors=""
  local warnings=""
  local warning_count=0
  local error_count=0
  local has_error=false

  while IFS= read -r line; do
    # Skip noise
    case "$line" in
      *Compiling*|*Checking*|*Downloading*|*Downloaded*|*Finished*|*Locking*|*Updating*|*Packaging*|*Fresh*)
        continue ;;
      "error: aborting"*|"error: could not compile"*|"error["*)
        has_error=true
        error_count=$((error_count + 1))
        errors+="$line"$'\n'
        continue ;;
      "error:"*|"error["*)
        has_error=true
        error_count=$((error_count + 1))
        errors+="$line"$'\n'
        continue ;;
      "warning:"*|"warning["*)
        warning_count=$((warning_count + 1))
        if (( warning_count <= 5 )); then
          warnings+="$line"$'\n'
        fi
        continue ;;
      *"generated "*" warning"*)
        continue ;;
    esac

    # Capture context lines for errors
    if $has_error; then
      errors+="$line"$'\n'
    fi
  done <<< "$input"

  if (( error_count > 0 )); then
    echo "ERRORS: ${error_count}"
    echo ""
    echo "$errors"
    if (( warning_count > 0 )); then
      echo "${warning_count} warnings (showing first 5):"
      echo "$warnings"
      if (( warning_count > 5 )); then
        echo "... +$((warning_count - 5)) more warnings"
      fi
    fi
  elif (( warning_count > 0 )); then
    echo "ok (${warning_count} warnings)"
    echo "$warnings"
    if (( warning_count > 5 )); then
      echo "... +$((warning_count - 5)) more warnings"
    fi
  else
    echo "ok"
  fi
}

filter_clippy() {
  local findings=""
  local finding_count=0
  local error_count=0

  while IFS= read -r line; do
    case "$line" in
      *Compiling*|*Checking*|*Downloading*|*Downloaded*|*Finished*|*Locking*|*Fresh*)
        continue ;;
      "warning:"*|"error:"*)
        finding_count=$((finding_count + 1))
        [[ "$line" == "error:"* ]] && error_count=$((error_count + 1))
        if (( finding_count <= 10 )); then
          findings+="$line"$'\n'
        fi
        continue ;;
      *"generated "*" warning"*|"error: aborting"*|"error: could not compile"*)
        continue ;;
    esac

    # Context for current finding
    if (( finding_count > 0 && finding_count <= 10 )); then
      case "$line" in
        "  --> "*|"   = help:"*|"   |"*)
          findings+="$line"$'\n' ;;
      esac
    fi
  done <<< "$input"

  if (( finding_count > 0 )); then
    echo "${finding_count} findings (${error_count} errors)"
    echo ""
    echo "$findings"
    if (( finding_count > 10 )); then
      echo "... +$((finding_count - 10)) more"
    fi
  else
    echo "ok"
  fi
}

filter_tsc() {
  local errors=""
  local error_count=0

  while IFS= read -r line; do
    if [[ "$line" =~ \.tsx?.*:\ error\ TS ]]; then
      error_count=$((error_count + 1))
      if (( error_count <= 15 )); then
        errors+="${line:0:150}"$'\n'
      fi
    fi
  done <<< "$input"

  if (( error_count > 0 )); then
    echo "ERRORS: ${error_count}"
    echo ""
    echo "$errors"
    if (( error_count > 15 )); then
      echo "... +$((error_count - 15)) more"
    fi
  else
    echo "ok"
  fi
}

filter_lint() {
  # Generic lint filter: group errors, cap output
  local error_count=0
  local output=""

  while IFS= read -r line; do
    case "$line" in
      ""|\~*|"All checks"*|"Found "*|*"no issues"*|*"0 error"*)
        output+="$line"$'\n'
        continue ;;
    esac
    error_count=$((error_count + 1))
    if (( error_count <= 15 )); then
      output+="${line:0:150}"$'\n'
    fi
  done <<< "$input"

  if (( error_count > 15 )); then
    echo "$output"
    echo "... +$((error_count - 15)) more issues"
  elif (( error_count == 0 )); then
    echo "ok"
  else
    echo "$output"
  fi
}

# Run filter
case "$TOOL" in
  cargo)          result=$(filter_cargo) ;;
  clippy)         result=$(filter_clippy) ;;
  tsc)            result=$(filter_tsc) ;;
  eslint|ruff|mypy) result=$(filter_lint) ;;
  *)              result="$input" ;;
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
    --arg type "build" \
    --arg runner "$TOOL" \
    --argjson original "$original_chars" \
    --argjson compressed "$compressed_chars" \
    --argjson saved "$saved" \
    --argjson pct "$pct" \
    '{timestamp:$ts, filter:$type, runner:$runner, original_chars:$original, compressed_chars:$compressed, saved_chars:$saved, reduction_pct:$pct}' \
    >> "$SAVINGS_LOG" 2>/dev/null || true
fi
