#!/usr/bin/env bash
# PreToolUse hook: rewrites Bash commands to pipe through output filters.
# Reduces token consumption by 60-90% on test, build, and git output.
#
# Install: add to PreToolUse hooks in settings.json with matcher "Bash"

set -euo pipefail

FILTER_DIR="${HOME}/.claude/scripts/filters"
SAVINGS_LOG="${HOME}/.local/share/claude-token-tracker/savings.jsonl"

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [[ -z "$command" ]]; then
  exit 0
fi

# Detect which filter to apply based on command pattern
filter=""
filter_type=""

case "$command" in
  # Test runners
  cargo\ test*|cargo\ nextest*)
    filter="$FILTER_DIR/filter-test.sh cargo"
    filter_type="test"
    ;;
  pytest*|python*-m\ pytest*)
    filter="$FILTER_DIR/filter-test.sh pytest"
    filter_type="test"
    ;;
  npm\ test*|npx\ vitest*|vitest*|npx\ jest*|jest*)
    filter="$FILTER_DIR/filter-test.sh js"
    filter_type="test"
    ;;
  go\ test*)
    filter="$FILTER_DIR/filter-test.sh go"
    filter_type="test"
    ;;

  # Build/lint
  cargo\ build*|cargo\ check*)
    filter="$FILTER_DIR/filter-build.sh cargo"
    filter_type="build"
    ;;
  cargo\ clippy*)
    filter="$FILTER_DIR/filter-build.sh clippy"
    filter_type="build"
    ;;
  tsc*|npx\ tsc*)
    filter="$FILTER_DIR/filter-build.sh tsc"
    filter_type="build"
    ;;
  eslint*|npx\ eslint*)
    filter="$FILTER_DIR/filter-build.sh eslint"
    filter_type="build"
    ;;
  ruff\ check*|ruff\ *.py*)
    filter="$FILTER_DIR/filter-build.sh ruff"
    filter_type="build"
    ;;
  mypy*)
    filter="$FILTER_DIR/filter-build.sh mypy"
    filter_type="build"
    ;;

  # Git — disabled for now. Claude needs full git output for commits/diffs.
  # Uncomment when git filters are refined to preserve commit workflow.
  # git\ status*)  filter="$FILTER_DIR/filter-git.sh status"; filter_type="git" ;;
  # git\ diff*)    filter="$FILTER_DIR/filter-git.sh diff"; filter_type="git" ;;
  # git\ log*)     filter="$FILTER_DIR/filter-git.sh log"; filter_type="git" ;;
  # git\ show*)    filter="$FILTER_DIR/filter-git.sh show"; filter_type="git" ;;
  # git\ add*)     filter="$FILTER_DIR/filter-git.sh add"; filter_type="git" ;;
  # git\ commit*)  filter="$FILTER_DIR/filter-git.sh commit"; filter_type="git" ;;
  # git\ push*)    filter="$FILTER_DIR/filter-git.sh push"; filter_type="git" ;;

  *)
    # No filter — pass through
    exit 0
    ;;
esac

# Rewrite command to pipe through filter, capturing both stdout and stderr
# The filter script handles savings logging internally
new_command="${command} 2>&1 | ${filter}"

jq -nc \
  --arg cmd "$new_command" \
  '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      permissionDecisionReason: "Output compression active",
      updatedInput: {
        command: $cmd
      }
    }
  }'
