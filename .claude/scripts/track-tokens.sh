#!/usr/bin/env bash
# Claude Code Token Tracker — PostToolUse hook (all tools)
#
# Logs every tool Claude uses with token estimates, categorization,
# and metadata (model, agents, skills, memory access, CLAUDE.md reads).
#
# Installed by: bash install.sh global
# View data:    ~/.claude/scripts/track-tokens.sh report

set -euo pipefail

LOG_DIR="${HOME}/.local/share/claude-token-tracker"
LOG_FILE="${LOG_DIR}/tool-usage.jsonl"
mkdir -p "$LOG_DIR"

# ============================================================
# CLI MODE — run directly for reports
# ============================================================

if [[ "${1:-}" != "" ]] && [[ ! "${1:-}" =~ ^\{ ]]; then
  cmd="${1:-report}"

  if [[ ! -f "$LOG_FILE" ]] || [[ ! -s "$LOG_FILE" ]]; then
    echo "No data yet. Use Claude Code with the hook enabled for a few sessions."
    exit 0
  fi

  case "$cmd" in

    report)
      echo "═══════════════════════════════════════════════════"
      echo "  Claude Code Token Tracker — Summary"
      echo "═══════════════════════════════════════════════════"
      echo ""

      total_calls=$(wc -l < "$LOG_FILE")
      total_tokens=$(jq -s '[.[].estimated_tokens] | add // 0' "$LOG_FILE")
      total_chars=$(jq -s '[.[].output_chars] | add // 0' "$LOG_FILE")
      first_ts=$(jq -r '.timestamp' "$LOG_FILE" | head -1)
      last_ts=$(jq -r '.timestamp' "$LOG_FILE" | tail -1)

      printf "  Period:           %s → %s\n" "$first_ts" "$last_ts"
      printf "  Total tool calls: %s\n" "$total_calls"
      printf "  Total tokens:     %s (~\$%.4f at \$3/M input)\n" "$total_tokens" "$(echo "$total_tokens * 3 / 1000000" | bc -l 2>/dev/null || echo 0)"
      printf "  Total chars:      %s\n" "$total_chars"
      echo ""

      # Quick breakdown by tool
      echo "  By tool:"
      jq -s '
        group_by(.tool) |
        map({tool: .[0].tool, count: length, tokens: ([.[].estimated_tokens] | add)}) |
        sort_by(-.tokens) | .[:10]
      ' "$LOG_FILE" | jq -r '.[] | "    \(.tool | . + " " * ([20 - length, 1] | max))  \(.count) calls   \(.tokens) tokens"'
      echo ""
      echo "  Run: top | tools | categories | agents | models | skills | memory | timeline | big | savings"
      ;;

    top)
      echo "═══════════════════════════════════════════════════"
      echo "  Top Operations by Token Consumption"
      echo "═══════════════════════════════════════════════════"
      echo ""
      jq -s '
        group_by(.operation_pattern) |
        map({
          pattern: .[0].operation_pattern,
          tool: .[0].tool,
          count: length,
          tokens: ([.[].estimated_tokens] | add),
          avg: (([.[].estimated_tokens] | add) / length | floor)
        }) |
        sort_by(-.tokens) | .[:25]
      ' "$LOG_FILE" | jq -r '.[] | "  \(.count)x  \(.tool):\(.pattern | .[0:45])  \(.tokens) tok  (avg \(.avg))"'
      ;;

    big)
      echo "═══════════════════════════════════════════════════"
      echo "  Biggest Individual Tool Outputs"
      echo "═══════════════════════════════════════════════════"
      echo ""
      jq -r '[.estimated_tokens, .tool, .operation_short, .timestamp] | @tsv' "$LOG_FILE" | \
        sort -rn | head -20 | while IFS=$'\t' read tokens tool op ts; do
          printf "  %6d tok  %-8s  %-50s  %s\n" "$tokens" "$tool" "$op" "$ts"
        done
      ;;

    tools)
      echo "═══════════════════════════════════════════════════"
      echo "  Token Consumption by Tool"
      echo "═══════════════════════════════════════════════════"
      echo ""
      jq -s '
        group_by(.tool) |
        map({
          tool: .[0].tool,
          count: length,
          total_tokens: ([.[].estimated_tokens] | add),
          avg_tokens: (([.[].estimated_tokens] | add) / length | floor),
          max_tokens: ([.[].estimated_tokens] | max)
        }) |
        sort_by(-.total_tokens)
      ' "$LOG_FILE" | jq -r '.[] | "  \(.tool | . + " " * ([16 - length, 1] | max))  \(.count) calls   \(.total_tokens) tok total   avg \(.avg_tokens)   max \(.max_tokens)"'
      ;;

    categories|cats)
      echo "═══════════════════════════════════════════════════"
      echo "  Token Consumption by Category"
      echo "═══════════════════════════════════════════════════"
      echo ""
      jq -s '
        group_by(.category) |
        map({
          cat: .[0].category,
          count: length,
          total_tokens: ([.[].estimated_tokens] | add),
          avg_tokens: (([.[].estimated_tokens] | add) / length | floor),
          max_tokens: ([.[].estimated_tokens] | max)
        }) |
        sort_by(-.total_tokens)
      ' "$LOG_FILE" | jq -r '.[] | "  \(.cat | . + " " * ([20 - length, 1] | max))  \(.count) calls   \(.total_tokens) tok total   avg \(.avg_tokens)   max \(.max_tokens)"'
      ;;

    agents)
      echo "═══════════════════════════════════════════════════"
      echo "  Agent Invocations"
      echo "═══════════════════════════════════════════════════"
      echo ""
      jq -s '
        [.[] | select(.category == "agent")] |
        if length == 0 then "  No agent calls recorded yet.\n" | halt_error
        else
          group_by(.agent_type) |
          map({
            type: .[0].agent_type,
            count: length,
            tokens: ([.[].estimated_tokens] | add),
            avg: (([.[].estimated_tokens] | add) / length | floor)
          }) |
          sort_by(-.tokens)
        end
      ' "$LOG_FILE" 2>/dev/null | jq -r '.[] | "  \(.type | . + " " * ([22 - length, 1] | max))  \(.count) calls   \(.tokens) tok total   avg \(.avg)"' 2>/dev/null || echo "  No agent calls recorded yet."
      ;;

    skills)
      echo "═══════════════════════════════════════════════════"
      echo "  Skill Invocations"
      echo "═══════════════════════════════════════════════════"
      echo ""
      jq -s '
        [.[] | select(.category == "skill")] |
        if length == 0 then empty
        else
          group_by(.skill_name) |
          map({
            skill: .[0].skill_name,
            count: length,
            tokens: ([.[].estimated_tokens] | add)
          }) |
          sort_by(-.tokens)
        end
      ' "$LOG_FILE" | jq -r '.[] | "  \(.skill | . + " " * ([25 - length, 1] | max))  \(.count) calls   \(.tokens) tok"' 2>/dev/null || echo "  No skill calls recorded yet."
      ;;

    memory)
      echo "═══════════════════════════════════════════════════"
      echo "  Memory & Context Access"
      echo "═══════════════════════════════════════════════════"
      echo ""
      echo "  CLAUDE.md reads:"
      jq -s '[.[] | select(.subcategory == "claude_md")] | length' "$LOG_FILE" | xargs -I{} printf "    %s reads\n" {}
      jq -s '[.[] | select(.subcategory == "claude_md") | .estimated_tokens] | add // 0' "$LOG_FILE" | xargs -I{} printf "    %s tokens\n" {}
      echo ""
      echo "  Memory file access:"
      jq -s '[.[] | select(.subcategory == "memory_read" or .subcategory == "memory_write")] | length' "$LOG_FILE" | xargs -I{} printf "    %s operations\n" {}
      jq -s '[.[] | select(.subcategory == "memory_read" or .subcategory == "memory_write") | .estimated_tokens] | add // 0' "$LOG_FILE" | xargs -I{} printf "    %s tokens\n" {}
      echo ""
      echo "  Skill/prompt loading:"
      jq -s '[.[] | select(.category == "skill")] | length' "$LOG_FILE" | xargs -I{} printf "    %s invocations\n" {}
      jq -s '[.[] | select(.category == "skill") | .estimated_tokens] | add // 0' "$LOG_FILE" | xargs -I{} printf "    %s tokens\n" {}
      echo ""
      echo "  Context files read (top 10):"
      jq -r 'select(.subcategory == "claude_md" or .subcategory == "memory_read" or .subcategory == "context_read") | .file_path // .operation_short' "$LOG_FILE" | \
        sort | uniq -c | sort -rn | head -10 | while read count path; do
          printf "    %3dx  %s\n" "$count" "$path"
        done
      ;;

    models)
      echo "═══════════════════════════════════════════════════"
      echo "  Usage by Model"
      echo "═══════════════════════════════════════════════════"
      echo ""
      jq -s '
        group_by(.model) |
        map({
          model: (.[0].model // "unknown"),
          count: length,
          tokens: ([.[].estimated_tokens] | add)
        }) |
        sort_by(-.tokens)
      ' "$LOG_FILE" | jq -r '.[] | "  \(.model | . + " " * ([35 - length, 1] | max))  \(.count) calls   \(.tokens) tokens"'
      ;;

    timeline|daily)
      echo "═══════════════════════════════════════════════════"
      echo "  Daily Token Consumption"
      echo "═══════════════════════════════════════════════════"
      echo ""
      jq -s '
        group_by(.timestamp[:10]) |
        map({
          date: .[0].timestamp[:10],
          calls: length,
          tokens: ([.[].estimated_tokens] | add)
        }) |
        sort_by(.date) | reverse | .[:14]
      ' "$LOG_FILE" | jq -r '.[] | "  \(.date)   \(.calls) calls   \(.tokens) tokens"'
      ;;

    savings)
      echo "═══════════════════════════════════════════════════"
      echo "  Estimated Savings Opportunities"
      echo "═══════════════════════════════════════════════════"
      echo ""
      echo "  Category breakdown with reduction potential:"
      echo ""

      for cat_info in \
        "bash_git:80:git operations (bash)" \
        "bash_test:90:test runner output" \
        "bash_build:80:build/lint output" \
        "file_read:40:file reads (Read tool)" \
        "claude_md:60:CLAUDE.md reads (often re-read)" \
        "memory_read:30:memory reads" \
        "search:50:search operations (Grep/Glob)" \
        "agent:20:agent invocations" \
        "skill:10:skill invocations" \
        "bash_other:50:other bash commands"; do

        IFS=: read cat pct desc <<< "$cat_info"
        tokens=$(jq -s --arg c "$cat" '[.[] | select(.category == $c or .subcategory == $c) | .estimated_tokens] | add // 0' "$LOG_FILE")
        if (( tokens > 0 )); then
          saveable=$((tokens * pct / 100))
          printf "  %-40s  %6d tokens  →  ~%d saveable (%d%%)\n" "$desc" "$tokens" "$saveable" "$pct"
        fi
      done

      echo ""
      total=$(jq -s '[.[].estimated_tokens] | add // 0' "$LOG_FILE")
      echo "  Total tracked: $total tokens"
      ;;

    codemap|codemap-impact)
      echo "═══════════════════════════════════════════════════"
      echo "  Codemap Impact Analysis"
      echo "═══════════════════════════════════════════════════"
      echo ""
      echo "  Compares sessions WITH codemap.md vs WITHOUT."
      echo "  Measures: exploration calls (Glob/Grep/Read) before first Edit/Write."
      echo ""

      # Group by session, classify each session
      jq -s '
        # Group events by session
        group_by(.session_id) |
        map(select(length > 3)) |   # skip tiny sessions

        map({
          session_id: .[0].session_id,
          total_calls: length,

          # Did this session read codemap.md?
          has_codemap: (map(select(.file_path != null and (.file_path | test("codemap\\.md$")))) | length > 0),

          # Count exploration calls (search + file_read) before first edit/write
          exploration_before_edit: (
            # Find index of first edit/write
            [to_entries[] | select(.value.category == "file_edit" or .value.category == "file_write") | .key] |
            if length > 0 then .[0] else length end
          ) as $first_edit |
          [.[:$first_edit] | .[] | select(.category == "search" or .category == "file_read")] | length,

          # Total exploration calls in session
          total_exploration: [.[] | select(.category == "search" or .category == "file_read")] | length,

          # Total exploration tokens
          exploration_tokens: ([.[] | select(.category == "search" or .category == "file_read") | .estimated_tokens] | add // 0),

          # Total tokens
          total_tokens: ([.[].estimated_tokens] | add // 0)
        }) |

        # Split into two groups
        {
          with_codemap: [.[] | select(.has_codemap)],
          without_codemap: [.[] | select(.has_codemap | not)]
        } |

        # Compute averages for each group
        {
          with_codemap: {
            sessions: (.with_codemap | length),
            avg_exploration_before_edit: (if (.with_codemap | length) > 0 then (.with_codemap | map(.exploration_before_edit) | add / length | . * 10 | round / 10) else 0 end),
            avg_total_exploration: (if (.with_codemap | length) > 0 then (.with_codemap | map(.total_exploration) | add / length | . * 10 | round / 10) else 0 end),
            avg_exploration_tokens: (if (.with_codemap | length) > 0 then (.with_codemap | map(.exploration_tokens) | add / length | round) else 0 end),
            avg_total_tokens: (if (.with_codemap | length) > 0 then (.with_codemap | map(.total_tokens) | add / length | round) else 0 end)
          },
          without_codemap: {
            sessions: (.without_codemap | length),
            avg_exploration_before_edit: (if (.without_codemap | length) > 0 then (.without_codemap | map(.exploration_before_edit) | add / length | . * 10 | round / 10) else 0 end),
            avg_total_exploration: (if (.without_codemap | length) > 0 then (.without_codemap | map(.total_exploration) | add / length | . * 10 | round / 10) else 0 end),
            avg_exploration_tokens: (if (.without_codemap | length) > 0 then (.without_codemap | map(.exploration_tokens) | add / length | round) else 0 end),
            avg_total_tokens: (if (.without_codemap | length) > 0 then (.without_codemap | map(.total_tokens) | add / length | round) else 0 end)
          }
        }
      ' "$LOG_FILE" | jq -r '
        "  WITH codemap.md (\(.with_codemap.sessions) sessions):",
        "    Avg exploration before first edit:  \(.with_codemap.avg_exploration_before_edit) calls",
        "    Avg total exploration calls:        \(.with_codemap.avg_total_exploration)",
        "    Avg exploration tokens:             \(.with_codemap.avg_exploration_tokens)",
        "    Avg total tokens:                   \(.with_codemap.avg_total_tokens)",
        "",
        "  WITHOUT codemap.md (\(.without_codemap.sessions) sessions):",
        "    Avg exploration before first edit:  \(.without_codemap.avg_exploration_before_edit) calls",
        "    Avg total exploration calls:        \(.without_codemap.avg_total_exploration)",
        "    Avg exploration tokens:             \(.without_codemap.avg_exploration_tokens)",
        "    Avg total tokens:                   \(.without_codemap.avg_total_tokens)",
        "",
        (if .with_codemap.sessions > 0 and .without_codemap.sessions > 0 then
          "  DELTA:",
          "    Exploration calls:  \( ((.without_codemap.avg_total_exploration - .with_codemap.avg_total_exploration) / .without_codemap.avg_total_exploration * 100) | . * 10 | round / 10 )% fewer with codemap",
          "    Exploration tokens: \( ((.without_codemap.avg_exploration_tokens - .with_codemap.avg_exploration_tokens) / (if .without_codemap.avg_exploration_tokens > 0 then .without_codemap.avg_exploration_tokens else 1 end) * 100) | . * 10 | round / 10 )% fewer with codemap",
          "    Total tokens:       \( ((.without_codemap.avg_total_tokens - .with_codemap.avg_total_tokens) / (if .without_codemap.avg_total_tokens > 0 then .without_codemap.avg_total_tokens else 1 end) * 100) | . * 10 | round / 10 )% fewer with codemap"
        else
          "  ⏳ Need sessions in both groups to compute delta.",
          "     Run some sessions WITH codemap.md and some WITHOUT."
        end)
      '
      echo ""
      echo "  Tip: Generate codemap for a project, work on it for a few sessions,"
      echo "  then run this report. Compare against projects without codemap."
      ;;

    reset)
      rm -f "$LOG_FILE"
      echo "Tracker data cleared."
      ;;

    export)
      cat "$LOG_FILE"
      ;;

    *)
      echo "Usage: track-tokens.sh [report|top|big|tools|categories|agents|skills|memory|models|timeline|savings|codemap|reset|export]"
      ;;
  esac
  exit 0
fi

# ============================================================
# HOOK MODE — called by Claude Code PostToolUse (all tools)
# ============================================================

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

if [[ -z "$tool_name" ]]; then
  echo '{}'
  exit 0
fi

# Extract common fields
session_id=$(echo "$input" | jq -r '.session_id // empty')

# Detect model from environment (Claude Code sets this)
model="${CLAUDE_MODEL:-${ANTHROPIC_MODEL:-unknown}}"

# ---- Measure output size ----
output_chars=0

case "$tool_name" in
  Bash)
    stdout=$(echo "$input" | jq -r '.tool_output.stdout // empty')
    stderr=$(echo "$input" | jq -r '.tool_output.stderr // empty')
    output_chars=$(( ${#stdout} + ${#stderr} ))
    ;;
  Read)
    content=$(echo "$input" | jq -r '.tool_output // empty')
    output_chars=${#content}
    ;;
  Grep|Glob)
    content=$(echo "$input" | jq -r '.tool_output // empty')
    output_chars=${#content}
    ;;
  Agent)
    content=$(echo "$input" | jq -r '.tool_output.result // .tool_output // empty')
    output_chars=${#content}
    ;;
  *)
    content=$(echo "$input" | jq -r '.tool_output // empty' 2>/dev/null)
    output_chars=${#content}
    ;;
esac

estimated_tokens=$((output_chars / 4))

# ---- Categorize ----
category=""
subcategory=""
file_path=""
agent_type=""
skill_name=""
operation_short=""
operation_pattern=""

case "$tool_name" in
  Bash)
    command=$(echo "$input" | jq -r '.tool_input.command // empty')
    operation_short="${command:0:80}"

    case "$command" in
      git\ *)                                          category="bash_git" ;;
      cargo\ test*|pytest*|python*-m\ pytest*)         category="bash_test" ;;
      npm\ test*|yarn\ test*|pnpm\ test*|vitest*)     category="bash_test" ;;
      cargo\ build*|cargo\ clippy*|cargo\ check*)     category="bash_build" ;;
      cargo\ fmt*|rustfmt*|ruff*|mypy*|pylint*)        category="bash_build" ;;
      tsc*|eslint*|prettier*)                          category="bash_build" ;;
      docker\ *|kubectl\ *|podman\ *)                  category="bash_docker" ;;
      pip\ *|cargo\ install*|npm\ install*|brew\ *)    category="bash_package" ;;
      curl\ *|wget\ *|http\ *)                         category="bash_network" ;;
      *)                                               category="bash_other" ;;
    esac

    operation_pattern=$(echo "$command" | sed -E '
      s|/[^ ]+/([^/ ]+\.[a-z]+)|\1|g
      s|"[^"]*"|"..."|g
    ')
    operation_pattern="${operation_pattern:0:60}"
    ;;

  Read)
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
    operation_short="$file_path"

    case "$file_path" in
      */CLAUDE.md|*/.claude/*.md)
        category="context"
        subcategory="claude_md"
        ;;
      */.claude/*/memory/*|*/memory/*.md|*/MEMORY.md)
        category="context"
        subcategory="memory_read"
        ;;
      */project-context.md|*/codemap.md|*/stack.md)
        category="context"
        subcategory="context_read"
        ;;
      */.ai-team/*)
        category="context"
        subcategory="feature_docs"
        ;;
      *)
        category="file_read"
        subcategory="code"
        ;;
    esac

    operation_pattern=$(basename "$file_path" 2>/dev/null || echo "$file_path")
    ;;

  Write)
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
    operation_short="$file_path"
    category="file_write"

    case "$file_path" in
      */.claude/*/memory/*|*/memory/*.md|*/MEMORY.md)
        subcategory="memory_write"
        ;;
      *)
        subcategory="code"
        ;;
    esac

    operation_pattern=$(basename "$file_path" 2>/dev/null || echo "$file_path")
    ;;

  Edit|MultiEdit)
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
    operation_short="$file_path"
    category="file_edit"
    operation_pattern=$(basename "$file_path" 2>/dev/null || echo "$file_path")
    ;;

  Grep)
    pattern=$(echo "$input" | jq -r '.tool_input.pattern // empty')
    operation_short="grep: ${pattern:0:60}"
    category="search"
    subcategory="grep"
    operation_pattern="grep:${pattern:0:40}"
    ;;

  Glob)
    pattern=$(echo "$input" | jq -r '.tool_input.pattern // empty')
    operation_short="glob: $pattern"
    category="search"
    subcategory="glob"
    operation_pattern="glob:$pattern"
    ;;

  Agent)
    agent_type=$(echo "$input" | jq -r '.tool_input.subagent_type // "general-purpose"')
    description=$(echo "$input" | jq -r '.tool_input.description // empty')
    agent_model=$(echo "$input" | jq -r '.tool_input.model // empty')
    operation_short="${agent_type}: ${description:0:60}"
    category="agent"
    subcategory="$agent_type"
    operation_pattern="agent:$agent_type"
    if [[ -n "$agent_model" ]]; then
      model="${agent_model} (agent)"
    fi
    ;;

  Skill)
    skill_name=$(echo "$input" | jq -r '.tool_input.skill // empty')
    operation_short="skill: $skill_name"
    category="skill"
    subcategory="$skill_name"
    operation_pattern="skill:$skill_name"
    ;;

  WebFetch)
    url=$(echo "$input" | jq -r '.tool_input.url // empty')
    operation_short="fetch: ${url:0:70}"
    category="web"
    subcategory="fetch"
    operation_pattern="web:fetch"
    ;;

  WebSearch)
    query=$(echo "$input" | jq -r '.tool_input.query // empty')
    operation_short="search: ${query:0:60}"
    category="web"
    subcategory="search"
    operation_pattern="web:search"
    ;;

  LSP)
    lsp_method=$(echo "$input" | jq -r '.tool_input.method // empty')
    operation_short="lsp: $lsp_method"
    category="lsp"
    operation_pattern="lsp:$lsp_method"
    ;;

  TaskCreate|TaskUpdate|TaskGet|TaskList|TaskStop|TaskOutput)
    operation_short="$tool_name"
    category="task_mgmt"
    operation_pattern="$tool_name"
    ;;

  NotebookEdit)
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
    operation_short="notebook: $file_path"
    category="file_edit"
    subcategory="notebook"
    operation_pattern="notebook"
    ;;

  *)
    operation_short="$tool_name"
    category="other"
    operation_pattern="$tool_name"
    ;;
esac

# ---- Log entry ----
jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg tool "$tool_name" \
  --arg cat "$category" \
  --arg subcat "$subcategory" \
  --arg op_short "$operation_short" \
  --arg op_pattern "$operation_pattern" \
  --arg file "$file_path" \
  --arg agent "$agent_type" \
  --arg skill "$skill_name" \
  --arg model "$model" \
  --arg session "$session_id" \
  --argjson output_chars "$output_chars" \
  --argjson estimated_tokens "$estimated_tokens" \
  '{
    timestamp: $ts,
    tool: $tool,
    category: $cat,
    subcategory: ($subcat | if . == "" then null else . end),
    operation_short: $op_short,
    operation_pattern: $op_pattern,
    file_path: ($file | if . == "" then null else . end),
    agent_type: ($agent | if . == "" then null else . end),
    skill_name: ($skill | if . == "" then null else . end),
    model: $model,
    session_id: ($session | if . == "" then null else . end),
    output_chars: $output_chars,
    estimated_tokens: $estimated_tokens
  }' >> "$LOG_FILE" 2>/dev/null || true

# Pass through — don't modify anything
echo '{}'
