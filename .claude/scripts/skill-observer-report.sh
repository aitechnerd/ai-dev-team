#!/usr/bin/env bash
# skill-observer-report.sh — View skill observation data
#
# Usage:
#   ./skill-observer-report.sh                # Overview
#   ./skill-observer-report.sh [skill-name]   # Detailed view for one skill
#   ./skill-observer-report.sh retries        # All retry events
#   ./skill-observer-report.sh feed           # Raw feed for /eval --improve

set -euo pipefail

OBS_DIR="${HOME}/.local/share/claude-skill-observer"
OBS_LOG="${OBS_DIR}/observations.jsonl"

if [[ ! -f "$OBS_LOG" ]] || [[ ! -s "$OBS_LOG" ]]; then
  echo "No observation data yet. Use skills for a few sessions."
  exit 0
fi

cmd="${1:-overview}"

case "$cmd" in

  overview)
    echo "═══════════════════════════════════════════════════"
    echo "  Skill Observer — Overview"
    echo "═══════════════════════════════════════════════════"
    echo ""

    total=$(wc -l < "$OBS_LOG" | tr -d ' ')
    invocations=$(jq -s '[.[] | select(.type == "skill_invocation")] | length' "$OBS_LOG")
    retries=$(jq -s '[.[] | select(.type == "skill_retry")] | length' "$OBS_LOG")
    successes=$(jq -s '[.[] | select(.type == "skill_success")] | length' "$OBS_LOG")
    manual_edits=$(jq -s '[.[] | select(.type == "post_skill_manual_edit")] | length' "$OBS_LOG")

    echo "  Total observations: $total"
    echo "  Skill invocations:  $invocations"
    echo "  Successes (inferred): $successes"
    echo "  Retries (failure signal): $retries"
    echo "  Post-skill manual edits: $manual_edits"
    echo ""

    if (( retries > 0 )); then
      retry_rate=$(echo "scale=1; $retries * 100 / ($invocations + $retries)" | bc -l 2>/dev/null || echo "?")
      echo "  Retry rate: ${retry_rate}%"
      echo ""
    fi

    echo "  Per-skill breakdown:"
    jq -s '
      [.[] | select(.type == "skill_invocation" or .type == "skill_retry")] |
      group_by(.skill) |
      map({
        skill: .[0].skill,
        total: length,
        retries: ([.[] | select(.type == "skill_retry")] | length)
      }) |
      sort_by(-.total)
    ' "$OBS_LOG" | jq -r '.[] |
      "    \(.skill | . + " " * ([25 - length, 1] | max))  \(.total) uses   \(.retries) retries" +
      (if .retries > 0 then "  ⚠️" else "" end)'
    echo ""
    echo "  Commands: [skill-name] | retries | feed"
    ;;

  retries)
    echo "═══════════════════════════════════════════════════"
    echo "  Retry Events (failure signals)"
    echo "═══════════════════════════════════════════════════"
    echo ""
    jq -r 'select(.type == "skill_retry") |
      "  \(.timestamp[:19])  \(.skill)  retry #\(.retry_count)  (\(.seconds_since_last)s after last)"
    ' "$OBS_LOG" | tail -20
    ;;

  feed)
    # Raw JSON feed for /eval --improve to consume
    jq -s '
      group_by(.skill) |
      map({
        skill: .[0].skill,
        invocations: ([.[] | select(.type == "skill_invocation")] | length),
        retries: ([.[] | select(.type == "skill_retry")] | length),
        successes: ([.[] | select(.type == "skill_success")] | length),
        manual_edits: ([.[] | select(.type == "post_skill_manual_edit")] | length),
        retry_rate: (
          ([.[] | select(.type == "skill_retry")] | length) as $r |
          ([.[] | select(.type == "skill_invocation")] | length) as $i |
          if ($r + $i) > 0 then ($r * 100 / ($r + $i)) else 0 end
        ),
        recent_retries: [
          .[] | select(.type == "skill_retry") |
          {timestamp: .timestamp, retry_count: .retry_count, seconds_since_last: .seconds_since_last}
        ] | .[-5:],
        recent_manual_edits: [
          .[] | select(.type == "post_skill_manual_edit") |
          {timestamp: .timestamp, file: .file, seconds_after_skill: .seconds_after_skill}
        ] | .[-5:]
      }) |
      sort_by(-.retry_rate)
    ' "$OBS_LOG"
    ;;

  *)
    # Treat as skill name
    skill="$cmd"
    skill_log="${OBS_DIR}/${skill}/outcomes.jsonl"

    if [[ ! -f "$skill_log" ]]; then
      echo "No data for skill: $skill"
      echo "Available: $(ls "$OBS_DIR" 2>/dev/null | grep -v '\.json' | grep -v '\.jsonl' | tr '\n' ' ')"
      exit 1
    fi

    echo "═══════════════════════════════════════════════════"
    echo "  Skill Observer — $skill"
    echo "═══════════════════════════════════════════════════"
    echo ""

    invocations=$(jq -s '[.[] | select(.type == "skill_invocation")] | length' "$skill_log")
    retries=$(jq -s '[.[] | select(.type == "skill_retry")] | length' "$skill_log")
    successes=$(jq -s '[.[] | select(.type == "skill_success")] | length' "$skill_log")
    manual_edits=$(jq -s '[.[] | select(.type == "post_skill_manual_edit")] | length' "$skill_log")

    echo "  Invocations: $invocations"
    echo "  Successes:   $successes"
    echo "  Retries:     $retries"
    echo "  Manual edits after: $manual_edits"
    echo ""

    echo "  Recent events:"
    jq -r '.timestamp[:19] + "  " + .type +
      (if .type == "skill_retry" then " (#" + (.retry_count | tostring) + ")" else "" end) +
      (if .type == "post_skill_manual_edit" then " → " + .file else "" end)
    ' "$skill_log" | tail -15
    ;;

esac
