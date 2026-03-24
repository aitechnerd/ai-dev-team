#!/usr/bin/env bash
# Filter test runner output: strip passing tests, keep failures + summary.
# Usage: cargo test 2>&1 | filter-test.sh cargo

set -uo pipefail

RUNNER="${1:-cargo}"
SAVINGS_LOG="${HOME}/.local/share/claude-token-tracker/savings.jsonl"
input=$(cat)
original_chars=${#input}

filter_cargo() {
  local output=""
  local failures=""
  local in_failure=false
  local failure_count=0
  local pass_count=0
  local fail_count=0
  local summary_lines=""

  while IFS= read -r line; do
    # Skip noise lines
    case "$line" in
      *Compiling*|*Downloading*|*Downloaded*|*Finished*|*Locking*|*Updating*)
        continue ;;
      "running "*)
        continue ;;
      "test result:"*)
        summary_lines+="$line"$'\n'
        # Parse counts
        if [[ "$line" =~ ([0-9]+)\ passed ]]; then
          pass_count=$((pass_count + ${BASH_REMATCH[1]}))
        fi
        if [[ "$line" =~ ([0-9]+)\ failed ]]; then
          fail_count=$((fail_count + ${BASH_REMATCH[1]}))
        fi
        in_failure=false
        continue ;;
      "test "*)
        if [[ "$line" == *"... ok" ]] || [[ "$line" == *"... ignored" ]]; then
          continue
        fi
        # Failed test
        in_failure=true
        failure_count=$((failure_count + 1))
        if (( failure_count <= 10 )); then
          failures+="$line"$'\n'
        fi
        continue ;;
      "---- "*)
        in_failure=true
        if (( failure_count <= 10 )); then
          failures+="$line"$'\n'
        fi
        continue ;;
      "")
        if $in_failure && (( failure_count <= 10 )); then
          failures+="$line"$'\n'
        fi
        continue ;;
    esac

    # Capture failure detail lines
    if $in_failure && (( failure_count <= 10 )); then
      failures+="$line"$'\n'
    fi
  done <<< "$input"

  if (( fail_count > 0 )); then
    echo "FAILED: ${fail_count} failed, ${pass_count} passed"
    echo ""
    echo "$failures"
    if (( failure_count > 10 )); then
      echo "... +$((failure_count - 10)) more failures"
    fi
  else
    echo "ok: ${pass_count} passed"
  fi
}

filter_pytest() {
  local failures=""
  local in_failure=false
  local failure_count=0
  local summary=""

  while IFS= read -r line; do
    # Skip banners and separators
    case "$line" in
      "==="*|"---"*|"platform "*|"rootdir:"*|"configfile:"*|"plugins:"*|"collected "*|"cachedir:"*)
        continue ;;
    esac

    # Summary line (e.g., "1 passed in 0.5s" or "2 failed, 3 passed in 1.2s")
    if [[ "$line" =~ ^[=\ ]*[0-9]+\ (passed|failed) ]]; then
      summary="$line"
      continue
    fi

    # Failure header
    if [[ "$line" == "FAILED "* ]] || [[ "$line" == "FAILURES"* ]] || [[ "$line" == "___"* ]]; then
      in_failure=true
      failure_count=$((failure_count + 1))
      if (( failure_count <= 5 )); then
        failures+="$line"$'\n'
      fi
      continue
    fi

    # Failure content (lines starting with > or E, or containing assert/Error)
    if $in_failure && (( failure_count <= 5 )); then
      case "$line" in
        ">"*|"E "*|*assert*|*Assert*|*Error*|*error*|*.py:*)
          failures+="${line:0:120}"$'\n' ;;
      esac
    fi
  done <<< "$input"

  if [[ -n "$failures" ]]; then
    echo "$summary"
    echo ""
    echo "$failures"
    if (( failure_count > 5 )); then
      echo "... +$((failure_count - 5)) more failures"
    fi
  elif [[ -n "$summary" ]]; then
    echo "ok: $summary"
  else
    # Fallback: couldn't parse, return truncated original
    echo "$input" | head -20
    local total_lines=$(echo "$input" | wc -l | tr -d ' ')
    if (( total_lines > 20 )); then
      echo "... ($total_lines lines total)"
    fi
  fi
}

filter_js() {
  local failures=""
  local summary=""
  local in_failure=false

  while IFS= read -r line; do
    # Skip noise
    case "$line" in
      *"PASS "*|*"✓ "*|*"✓"*|*"√ "*)
        continue ;;
      *"FAIL "*|*"✗ "*|*"✕ "*|*"× "*)
        in_failure=true
        failures+="$line"$'\n'
        continue ;;
      "Test Suites:"*|"Tests:"*|"Time:"*)
        summary+="$line"$'\n'
        continue ;;
    esac

    if $in_failure; then
      failures+="$line"$'\n'
    fi
  done <<< "$input"

  if [[ -n "$failures" ]]; then
    echo "$summary"
    echo "$failures" | head -30
  elif [[ -n "$summary" ]]; then
    echo "ok"
    echo "$summary"
  else
    echo "$input" | head -20
  fi
}

filter_go() {
  local failures=""
  local pass_count=0
  local fail_count=0

  while IFS= read -r line; do
    case "$line" in
      "ok "*)
        pass_count=$((pass_count + 1))
        continue ;;
      "--- PASS:"*|"=== RUN"*)
        continue ;;
      "--- FAIL:"*|"FAIL"*)
        fail_count=$((fail_count + 1))
        failures+="$line"$'\n'
        continue ;;
    esac

    if (( fail_count > 0 )); then
      failures+="$line"$'\n'
    fi
  done <<< "$input"

  if (( fail_count > 0 )); then
    echo "FAILED: ${fail_count} failed, ${pass_count} passed"
    echo ""
    echo "$failures" | head -30
  else
    echo "ok: ${pass_count} passed"
  fi
}

# Run the appropriate filter
case "$RUNNER" in
  cargo)  result=$(filter_cargo) ;;
  pytest) result=$(filter_pytest) ;;
  js)     result=$(filter_js) ;;
  go)     result=$(filter_go) ;;
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
    --arg type "test" \
    --arg runner "$RUNNER" \
    --argjson original "$original_chars" \
    --argjson compressed "$compressed_chars" \
    --argjson saved "$saved" \
    --argjson pct "$pct" \
    '{timestamp:$ts, filter:$type, runner:$runner, original_chars:$original, compressed_chars:$compressed, saved_chars:$saved, reduction_pct:$pct}' \
    >> "$SAVINGS_LOG" 2>/dev/null || true
fi
