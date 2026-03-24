---
name: eval
description: |
  Evaluate and improve AI Dev Team skills. Three tiers: static validation (free),
  LLM-judge quality scoring, E2E testing via claude -p. All LLM calls use your
  Claude Code subscription (no API key needed, no extra charges).
  Tracks results over time, detects regressions, suggests improvements.
  Use: /eval [skill-name]        — run all tiers on a skill
  Use: /eval --static            — quick structural check on all skills
  Use: /eval --improve [skill]   — analyze failures and suggest edits
  Use: /eval --compare A B       — blind A/B comparison of two skill versions
  Use: /eval --history [skill]   — show eval score history
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

# /eval: Skill Evaluation & Self-Improvement

Evaluate skills across three tiers, track quality over time, and suggest improvements
based on failure analysis. The goal: skills that get better with every iteration.

## Parse Arguments

```
/eval [skill-name]            → Run all tiers on the named skill
/eval --static                → Tier 1 only, all skills (fast, free)
/eval --judge [skill-name]    → Tier 2: LLM quality scoring
/eval --e2e [skill-name]      → Tier 3: E2E test via claude -p
/eval --improve [skill-name]  → Analyze failures, suggest edits
/eval --compare A B           → Blind A/B comparison
/eval --history [skill-name]  → Show score history
/eval --regression            → Compare latest scores against baseline
```

## Output Directory

```bash
mkdir -p .ai-team/evals
```

All eval results go to `.ai-team/evals/`:
```
.ai-team/evals/
├── history.jsonl                    # Append-only score log
├── baseline.json                    # Baseline scores for regression detection
├── browse/
│   ├── eval-2026-03-17.json         # Full eval result
│   ├── eval-2026-03-17-improve.md   # Improvement suggestions
│   └── test-cases.md                # Eval definitions
├── qa-browser/
│   └── ...
└── review/
    └── ...
```

---

## Tier 1: Static Validation (free, <5s)

Structural checks — no LLM calls. **Token-efficient: use Bash to parse files
instead of reading each SKILL.md into context.**

Determine the skills directory to operate on:
```bash
SOURCE_REPO=$(cat ~/.claude/.ai-team-source 2>/dev/null)
if [ -n "$SOURCE_REPO" ] && [ -d "$SOURCE_REPO/skills" ]; then
  SKILLS_DIR="$SOURCE_REPO/skills"    # Edit source repo directly
else
  SKILLS_DIR="$HOME/.claude/skills"   # Fallback to installed copies
fi
```

### Run static checks via script (DO NOT read each SKILL.md individually)

Run the static validator script which checks all skills in a single Bash call
and returns a compact report. This avoids reading 30+ SKILL.md files into context
(~42K tokens). Only read individual SKILL.md files if a skill FAILS and you need
to investigate or fix it.

```bash
bash ~/.claude/scripts/eval-static.sh "$SKILLS_DIR"
```

The script checks each `$SKILLS_DIR/*/SKILL.md`:

### 1.1 Frontmatter Check
- Has `name` field
- Has `description` field (non-empty, >20 chars)
- `allowed-tools` is a list (if present)
- `name` matches directory name

### 1.2 Reference Integrity
- All file references in the SKILL.md actually exist
- No broken relative paths

### 1.3 Command Consistency
- If skill references `playwright-cli`, it has `Bash(playwright-cli:*)` in allowed-tools
- If skill references `git` commands, it has `Bash(git:*)` in allowed-tools
- Tool references in the body match allowed-tools declarations

### 1.4 Template Freshness (if .tmpl exists)
```bash
bash ~/.claude/scripts/gen-skill-docs.sh --check
```

### 1.5 Description Trigger Quality
- Description is specific enough to distinguish this skill from others
- No overly generic phrases ("use for anything", "general purpose" without specifics)
- Contains concrete trigger keywords/phrases

### Static Score
Each check: PASS (1) or FAIL (0). Score = passes / total checks * 100.

---

## Tier 2: LLM-Judge Quality Scoring (uses Claude Code subscription)

Use `claude -p` to score the skill document on five dimensions. This runs through
your Claude Code subscription — no API key or extra charges needed.

```bash
cat $SKILLS_DIR/{skill}/SKILL.md | claude -p "You are evaluating the quality of an AI agent skill document.
Score each dimension 1-5 (1=poor, 5=excellent). Be critical — 3 is average.

Dimensions:
1. Clarity — Is the skill easy to understand? Are instructions unambiguous?
2. Completeness — Does it cover all cases? Edge cases? Error handling?
3. Actionability — Can an agent follow this without guessing? Are examples concrete?
4. Efficiency — Is it concise? No redundancy? Good information density?
5. Trigger precision — Will the description correctly match intended use cases
   without false positives or false negatives?

Output JSON only:
{\"clarity\": N, \"clarity_note\": \"...\",
 \"completeness\": N, \"completeness_note\": \"...\",
 \"actionability\": N, \"actionability_note\": \"...\",
 \"efficiency\": N, \"efficiency_note\": \"...\",
 \"trigger_precision\": N, \"trigger_note\": \"...\",
 \"overall\": N,
 \"top_issue\": \"the single most impactful improvement\",
 \"suggestions\": [\"...\", \"...\", \"...\"]}" > .ai-team/evals/{skill}/judge-{date}.json
```

### Judge Score
Overall = average of 5 dimensions. Scale: 1.0-5.0.

---

## Tier 3: E2E Testing (uses Claude Code subscription)

Spawn a real Claude Code session via `claude -p` and verify the skill works end-to-end.
All runs use your subscription — no API costs.

### 3.1 Load or Create Test Cases

Check `.ai-team/evals/{skill}/test-cases.md`. If it doesn't exist, generate it:

For each skill, create 3-5 test cases:
```markdown
# Test Cases: {skill_name}

## TC-1: {scenario name}
**Prompt:** "{the prompt a user would type to invoke this skill}"
**Setup:** {any files/state needed, or "none"}
**Success criteria:**
- [ ] Skill was triggered (not another skill)
- [ ] {expected behavior 1}
- [ ] {expected behavior 2}
- [ ] No errors in output
**Timeout:** 120s

## TC-2: ...
```

Test case types:
- **Happy path** — standard use case
- **Edge case** — unusual input, empty state, missing files
- **Trigger test** — verify the skill fires (and doesn't fire for unrelated prompts)

### 3.2 Run Tests

For each test case:
```bash
# Create a temp directory with any required setup files
TMPDIR=$(mktemp -d)
# ... copy setup files ...

# Run via claude -p with streaming JSON for observability
cd "$TMPDIR" && echo "$PROMPT" | claude -p --output-format stream-json --verbose 2>&1
```

Parse the NDJSON output to extract:
- Did the skill trigger? (look for skill name in tool calls)
- Did it complete without errors?
- Token count and elapsed time
- Final output text

### 3.3 Evaluate Results

For each test case, check success criteria. If criteria require judgment
(not just pass/fail), use Haiku to score the output.

### E2E Score
Pass rate: passed_tests / total_tests * 100.

---

## Scoring & History

### Composite Score

```
composite = (static * 0.2) + (judge * 0.4) + (e2e * 0.4)
```

Normalize all to 0-100 scale (judge scores: multiply by 20).

### Save to History

Append to `.ai-team/evals/history.jsonl`:
```json
{
  "date": "2026-03-17T10:30:00Z",
  "skill": "browse",
  "static": 95,
  "judge": 82,
  "e2e": 100,
  "composite": 91.4,
  "model": "claude-sonnet-4-6",
  "notes": ""
}
```

Save detailed results to `.ai-team/evals/{skill}/eval-{date}.json`.

---

## --improve: Self-Improvement Loop

The key feature: analyze eval failures and suggest concrete edits to the skill.

### Process

1. Load the latest eval results for the skill
2. Load **observation data** from the skill observer (real usage signals):
   ```bash
   # Get usage stats: invocations, retries, manual edits after skill
   bash ~/.claude/scripts/skill-observer-report.sh {skill}

   # Get structured feed for analysis
   bash ~/.claude/scripts/skill-observer-report.sh feed
   ```
3. Identify failures, low scores, AND real-world signals:
   - High retry rate = users re-invoking because output was wrong
   - Manual edits after skill = skill missed something the user had to fix
   - Low invocation count = trigger description may not match how users think
4. For each issue, propose a specific edit:

Pipe the skill content + eval results + observation data into `claude -p` (uses your subscription):

```bash
cat <<EOF | claude -p "You are improving an AI agent skill based on eval results AND real usage data.

For each issue:
1. Diagnose the root cause (ambiguous instruction? missing example? wrong trigger?)
2. Propose a SPECIFIC edit (not vague advice — actual text changes)
3. Explain why this edit fixes the issue

Prioritize issues with STRONG signals (retries, manual edits) over weak signals.
Output as a structured improvement plan in markdown."

SKILL CONTENT:
$(cat $SKILLS_DIR/{skill}/SKILL.md)

EVAL RESULTS:
$(cat .ai-team/evals/{skill}/eval-{date}.json)

JUDGE FEEDBACK:
$(cat .ai-team/evals/{skill}/judge-{date}.json)

USAGE OBSERVATIONS:
$(bash ~/.claude/scripts/skill-observer-report.sh feed | jq '.[] | select(.skill == "{skill}")')
EOF
```

Expected output format:
```markdown
> # Improvement Plan: {skill_name}
> **Current score:** {composite}
> **Target score:** {estimated after fixes}
>
> ## Fix 1: {issue}
> **Root cause:** ...
> **Edit:** Replace [old text] with [new text] in SKILL.md line N
> **Expected impact:** +N points on {dimension}
>
> ## Fix 2: ...
> ```
>
> Prioritize: trigger precision > actionability > completeness > clarity > efficiency.
> Focus on fixes that improve eval pass rates, not cosmetic changes."

Save to `.ai-team/evals/{skill}/eval-{date}-improve.md`.

### Apply Improvements

Ask the user:
> "Improvement plan for **{skill}** (current score: {N}/100):
>
> 1. {fix 1 summary} — est. +{N} points
> 2. {fix 2 summary} — est. +{N} points
> 3. {fix 3 summary} — est. +{N} points
>
> A) Apply all  B) Apply selectively  C) Review plan first  D) Skip"

If applying:

1. Edit `$SKILLS_DIR/{skill}/SKILL.md` (this is the source repo if available, otherwise `~/.claude/skills/`)
2. If `$SKILLS_DIR` points to the source repo, also copy the edited file to `~/.claude/skills/{skill}/SKILL.md` so the active install is updated immediately.
3. Re-run Tier 1+2 to verify improvement.

---

## --compare: Blind A/B Comparison

Compare two versions of a skill (or skill vs no-skill).

### Process

1. Run the same test cases against both versions
2. Collect outputs without labeling which is A or B
3. Send paired outputs to Haiku for blind comparison:

> "Two agents produced these outputs for the same task.
> You don't know which is which. Score each 1-5 on:
> correctness, completeness, clarity, efficiency.
> Then pick a winner (A or B) and explain why."

4. Tally results across all test cases
5. Report which version won and by how much

---

## --regression: Regression Detection

Compare current scores against baseline.

```bash
# Set baseline (usually after a good eval run)
cp .ai-team/evals/history.jsonl .ai-team/evals/baseline.json
# (actually: extract latest score per skill as the baseline)
```

Report:
- Skills that improved (score up >5 points)
- Skills that regressed (score down >5 points)
- Skills that are stable

Flag regressions loudly — these need immediate attention.

---

## Evolution: How Skills Get Better Over Time

The self-improvement cycle:

```
1. /eval browse              → Score: 72/100
2. /eval --improve browse    → 3 fixes identified
3. Apply fixes               → SKILL.md updated
4. /eval browse              → Score: 85/100  ✓ improved
5. Results saved to history  → Trend: 72 → 85
6. Set as new baseline       → Future regressions detected against 85
```

Over many iterations:
- Test cases accumulate (each failure becomes a new test case)
- Trigger descriptions sharpen (fewer false positives/negatives)
- Instructions become more precise (fewer ambiguous outcomes)
- Edge cases get covered (from real-world failures)

### Auto-Accumulating Test Cases

When a skill fails in production (user reports issue, QA finds bug), add a test case:
```markdown
## TC-N: {failure scenario}
**Prompt:** "{the prompt that caused the failure}"
**Setup:** {reproduce the state}
**Success criteria:**
- [ ] {the correct behavior that was missing}
**Source:** Production failure on {date}
```

This ensures the same failure never happens twice.

---

## Important Rules

1. **Never modify skills during evaluation.** Evaluate the current state, then improve separately.
2. **Always use `$SKILLS_DIR` for reads and writes.** This points to the source repo when available (via `~/.claude/.ai-team-source`), falling back to `~/.claude/skills/`. When editing source repo files, also copy to `~/.claude/skills/` so the active install stays current.
3. **E2E tests are expensive.** Use Tier 1+2 for rapid iteration, Tier 3 for validation.
4. **Test cases are permanent.** Never delete a test case — only add. Failed tests become regression guards.
5. **Blind comparisons must be blind.** Never reveal which version is A or B to the judge.
6. **Track everything.** Every eval run gets saved to history. Data enables trend analysis.
7. **Improvement suggestions are suggestions.** Always ask before applying edits.
8. **One change at a time.** When improving, make one edit, re-eval, then decide on the next.
