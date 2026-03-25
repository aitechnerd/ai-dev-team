#!/usr/bin/env bash
# Static validation for all skills — runs all checks in one process.
# Returns compact report instead of requiring Claude to read each SKILL.md.
# Saves ~42K tokens per /eval --static run.
#
# Usage: bash eval-static.sh [SKILLS_DIR]

set -uo pipefail

SKILLS_DIR="${1:-$HOME/.claude/skills}"
total_skills=0
total_pass=0
total_fail=0
failures=""

for skill_dir in "$SKILLS_DIR"/*/; do
  [[ ! -d "$skill_dir" ]] && continue
  skill_file="$skill_dir/SKILL.md"
  [[ ! -f "$skill_file" ]] && continue

  dir_name=$(basename "$skill_dir")
  total_skills=$((total_skills + 1))
  skill_pass=0
  skill_total=0
  skill_issues=""

  # Read frontmatter (between --- markers)
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_file" | sed '1d;$d')
  body=$(sed -n '/^---$/,/^---$/d;p' "$skill_file")

  # === 1.1 Frontmatter Check ===

  # Has name field
  skill_total=$((skill_total + 1))
  fm_name=$(echo "$frontmatter" | grep -E '^name:' | sed 's/^name:\s*//' | tr -d ' ')
  if [[ -n "$fm_name" ]]; then
    skill_pass=$((skill_pass + 1))
  else
    skill_issues+="  FAIL: missing name field\n"
  fi

  # Name matches directory
  skill_total=$((skill_total + 1))
  if [[ "$fm_name" == "$dir_name" ]]; then
    skill_pass=$((skill_pass + 1))
  else
    skill_issues+="  FAIL: name '$fm_name' != dir '$dir_name'\n"
  fi

  # Has description (>20 chars)
  skill_total=$((skill_total + 1))
  # Extract description — may be multi-line with | or >
  desc_line=$(echo "$frontmatter" | grep -E '^description:' | sed 's/^description:[[:space:]]*//')
  if [[ "$desc_line" == "|" ]] || [[ "$desc_line" == ">" ]]; then
    # Multi-line: grab all indented lines after description:
    desc_text=$(echo "$frontmatter" | sed -n '/^description:/,/^[a-zA-Z_-]*:/p' | sed '1d;/^[a-zA-Z_-]*:/d' | tr '\n' ' ' | sed 's/^[[:space:]]*//')
  else
    desc_text="$desc_line"
  fi
  if [[ ${#desc_text} -gt 20 ]]; then
    skill_pass=$((skill_pass + 1))
  else
    skill_issues+="  FAIL: description too short (${#desc_text} chars)\n"
  fi

  # allowed-tools is a list (if present)
  skill_total=$((skill_total + 1))
  has_tools=$(echo "$frontmatter" | grep -c '^allowed-tools:' || true)
  if [[ "$has_tools" -gt 0 ]]; then
    tool_items=$(echo "$frontmatter" | sed -n '/^allowed-tools:/,/^[a-z]/p' | grep -c '^\s*-' || true)
    if [[ "$tool_items" -gt 0 ]]; then
      skill_pass=$((skill_pass + 1))
    else
      skill_issues+="  FAIL: allowed-tools is not a list\n"
    fi
  else
    skill_pass=$((skill_pass + 1))  # Optional field, pass if absent
  fi

  # === 1.2 Reference Integrity ===
  skill_total=$((skill_total + 1))
  ref_ok=true
  # Find file references in body (paths like scripts/foo.sh, templates/bar.md)
  refs=$(echo "$body" | grep -oE '[a-zA-Z0-9_/-]+\.(sh|py|md|json|yaml|yml|tmpl|toml)' | sort -u)
  for ref in $refs; do
    # Skip URLs, code examples, template vars, and obvious non-paths
    [[ "$ref" == *"http"* ]] && continue
    [[ "$ref" == *"example"* ]] && continue
    [[ "$ref" =~ ^[0-9] ]] && continue
    [[ "$ref" == *"FEATURE_DIR"* ]] && continue
    [[ "$ref" == *"FEATURE_NAME"* ]] && continue
    [[ "$ref" == *"NAME/"* ]] && continue
    [[ "$ref" == *"/tmp/"* ]] && continue
    # Check relative to skill dir and home
    if [[ -f "${skill_dir}${ref}" ]] || [[ -f "${HOME}/.claude/${ref}" ]] || [[ -f "${HOME}/.claude/scripts/${ref}" ]]; then
      continue
    fi
    # Only flag if it looks like a real path (has a slash)
    if [[ "$ref" == *"/"* ]]; then
      ref_ok=false
      skill_issues+="  WARN: ref '$ref' not found\n"
    fi
  done
  $ref_ok && skill_pass=$((skill_pass + 1))

  # === 1.3 Command Consistency ===
  skill_total=$((skill_total + 1))
  cmd_ok=true
  allowed_tools_text=$(echo "$frontmatter" | sed -n '/^allowed-tools:/,/^[a-z]/p')

  # Check playwright-cli usage
  if echo "$body" | grep -q 'playwright-cli\|playwright cli'; then
    if ! echo "$allowed_tools_text" | grep -q 'playwright-cli'; then
      cmd_ok=false
      skill_issues+="  FAIL: uses playwright-cli but missing Bash(playwright-cli:*)\n"
    fi
  fi

  # Check git usage
  if echo "$body" | grep -qE 'git (status|diff|log|commit|push|pull|add|checkout|branch|merge|rebase|stash|tag)'; then
    if ! echo "$allowed_tools_text" | grep -qE 'Bash\(git|Bash$'; then
      # Only flag if Bash is restricted (has specific patterns)
      if echo "$allowed_tools_text" | grep -q 'Bash('; then
        cmd_ok=false
        skill_issues+="  WARN: uses git commands but may be missing Bash(git:*)\n"
      fi
    fi
  fi

  $cmd_ok && skill_pass=$((skill_pass + 1))

  # === 1.5 Description Trigger Quality ===
  skill_total=$((skill_total + 1))
  trigger_ok=true
  if echo "$desc_text" | grep -qiE 'use for anything|general purpose$|do everything'; then
    trigger_ok=false
    skill_issues+="  FAIL: description is too generic\n"
  fi
  $trigger_ok && skill_pass=$((skill_pass + 1))

  # === Score ===
  score=$((skill_pass * 100 / skill_total))

  if [[ -n "$skill_issues" ]]; then
    total_fail=$((total_fail + 1))
    failures+="$dir_name ($score%): $skill_pass/$skill_total\n$(echo -e "$skill_issues")\n"
  else
    total_pass=$((total_pass + 1))
  fi

  printf "  %-28s %3d%%  (%d/%d)\n" "$dir_name" "$score" "$skill_pass" "$skill_total"
done

echo ""
echo "═══════════════════════════════════════════"
echo "  $total_skills skills: $total_pass passed, $total_fail with issues"
echo "═══════════════════════════════════════════"

if [[ -n "$failures" ]]; then
  echo ""
  echo "Issues:"
  echo -e "$failures"
fi
