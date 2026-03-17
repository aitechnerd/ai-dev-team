#!/usr/bin/env bash
# gen-skill-docs.sh — Generate SKILL.md from .tmpl files with partial substitution
#
# Usage:
#   ./gen-skill-docs.sh              # Generate all, overwrite SKILL.md files
#   ./gen-skill-docs.sh --dry-run    # Show what would change (for CI validation)
#   ./gen-skill-docs.sh --check      # Exit 1 if any SKILL.md is stale (for CI)
#
# Template format:
#   SKILL.md.tmpl files use {{PARTIAL_NAME}} placeholders.
#   Partials live in .claude/skills/_partials/{partial-name}.md
#   Placeholder name maps to filename: {{PLAYWRIGHT_CLI_SETUP}} -> playwright-cli-setup.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(cd "$SCRIPT_DIR/../skills" && pwd)"
PARTIALS_DIR="$SKILLS_DIR/_partials"

DRY_RUN=false
CHECK=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --check)   CHECK=true ;;
  esac
done

if [ ! -d "$PARTIALS_DIR" ]; then
  echo "Error: Partials directory not found: $PARTIALS_DIR" >&2
  exit 1
fi

stale_count=0
generated_count=0
skipped_count=0

# Find all .tmpl files
for tmpl in "$SKILLS_DIR"/*/SKILL.md.tmpl; do
  [ -f "$tmpl" ] || continue

  skill_dir="$(dirname "$tmpl")"
  skill_name="$(basename "$skill_dir")"
  output="$skill_dir/SKILL.md"

  # Use Python for reliable multi-line placeholder substitution
  generated=$(python3 -c "
import re, sys, os

partials_dir = '$PARTIALS_DIR'
with open('$tmpl') as f:
    content = f.read()

def replace_placeholder(match):
    name = match.group(1)
    filename = name.lower().replace('_', '-') + '.md'
    path = os.path.join(partials_dir, filename)
    if not os.path.exists(path):
        print(f'Warning: [{skill_name}] Partial not found: {filename}', file=sys.stderr)
        return match.group(0)  # leave placeholder as-is
    with open(path) as f:
        return f.read().rstrip('\n')

result = re.sub(r'\{\{([A-Z_]+)\}\}', replace_placeholder, content)
sys.stdout.write(result)
" 2>&1) || { echo "Error processing $skill_name" >&2; continue; }

  if $CHECK || $DRY_RUN; then
    if [ -f "$output" ]; then
      existing="$(cat "$output")"
      if [ "$generated" != "$existing" ]; then
        stale_count=$((stale_count + 1))
        if $DRY_RUN; then
          echo "STALE: $skill_name/SKILL.md"
          diff <(echo "$existing") <(echo "$generated") || true
          echo "---"
        else
          echo "STALE: $skill_name/SKILL.md"
        fi
      else
        skipped_count=$((skipped_count + 1))
      fi
    else
      stale_count=$((stale_count + 1))
      echo "NEW: $skill_name/SKILL.md (not yet generated)"
    fi
  else
    # Write the generated file
    printf '%s' "$generated" > "$output"
    generated_count=$((generated_count + 1))
    echo "Generated: $skill_name/SKILL.md"
  fi
done

if $CHECK; then
  if [ "$stale_count" -gt 0 ]; then
    echo ""
    echo "ERROR: $stale_count SKILL.md file(s) are stale. Run: bash .claude/scripts/gen-skill-docs.sh"
    exit 1
  else
    echo "OK: All templated SKILL.md files are up to date."
  fi
elif $DRY_RUN; then
  echo ""
  echo "Dry run complete: $stale_count stale, $skipped_count up-to-date."
elif [ "$generated_count" -gt 0 ]; then
  echo ""
  echo "Generated $generated_count SKILL.md file(s)."
else
  echo "No .tmpl files found. Nothing to generate."
fi
