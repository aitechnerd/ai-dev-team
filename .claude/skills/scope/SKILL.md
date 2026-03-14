---
name: scope
description: >
  Smart entry point for any task. Detects what you need and right-sizes the
  pipeline: investigation, bug fix, small feature, or large feature.
  Use /scope [describe what you want].
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
---

# Scope — Smart Task Router

## Input
Task description: $ARGUMENTS

## Step 0: Classify the Task

Read the description carefully. Classify by **intent** (use judgment, not keywords):

**INVESTIGATION** — user is asking a question or trying to understand something:
- "why are only a few lab results returned"
- "check if our Snowflake queries are hitting the right tables"
- "how does the referral pipeline currently work"
- "look into why the cron job takes 3 hours"

**BUG** — something specific is broken and needs fixing:
- "the search returns wrong results for partial names"
- "patients can't upload documents on mobile"
- "the nightly sync job has been failing since Tuesday"

**SMALL FEATURE** — 1-3 files, isolated change, no architecture decisions:
- "add a retry count column to the orders table"
- "add input validation to the patient form"
- "change the lookback window from 7 to 90 days"
- "add a health check endpoint"

**LARGE FEATURE** — new subsystem, multiple components, architecture decisions:
- "build a patient intake form with demographics"
- "add fuzzy search across all patient fields"
- "set up automated lab result notifications"
- "build a dashboard showing referral conversion rates"

**Tell the user what you detected and what pipeline you'll use:**
> "This looks like a **[type]**. I'll use the **[light/standard/full]** pipeline.
> Estimated cost: ~[N] agent calls ([model breakdown]).
> OK to proceed?"

If the user disagrees, reclassify.

### Pipeline Matrix

| Type | Pipeline | Agent Calls | Models Used |
|------|----------|-------------|-------------|
| Investigation | Direct | 0 subagents | Just you |
| Bug | Light | 2-3 | PO(Sonnet) + SE(Opus) |
| Small feature | Light | 3-4 | PO(Sonnet) + SE(Opus) + DevSecOps(Sonnet) |
| Large feature | Full | 6-8 | PO(Opus) + SE(Opus) + DevSecOps + UX + triage |

---

## INVESTIGATION PATH

For questions, audits, understanding how things work, data analysis, debugging.

### Setup

Derive a short kebab-case name.
```bash
mkdir -p .ai-team/$NAME
echo "$NAME" > .ai-team/.active
```

Initialize shared context:
```bash
cat > .ai-team/$NAME/shared-context.md << CTX
# Shared Context: $NAME
## Task
$DESCRIPTION

## Key Files
(populated as investigation progresses)

## Findings
(populated as investigation progresses)
CTX
```

### Do the work directly

**IMPORTANT: Do NOT spawn any subagents, Task agents, or Explore agents.**
**Do NOT use the Task tool or Explore tool. Work directly in this session.**
No SOW. No planning pipeline. Just investigate.

Read `.claude/stack.md` and `.claude/project-context.md` if they exist.
Read any files referenced in $ARGUMENTS.

**Save all generated files** (SQL queries, scripts, logs, exports) to `.ai-team/$NAME/`,
not to the project root. This keeps investigations contained and gitignored.

**Be interactive and incremental:**
- Investigate step by step. Don't generate a batch of queries to run later.
- For each diagnostic step: show the query/command FIRST, explain what it checks,
  then **ask the user if it's OK to run it** before executing.
- After each result, explain what you learned and what to check next.
- Build on what you find — let each step's results guide the next question.
- Print findings as you discover them — never go silent for more than 30 seconds.
- After every significant discovery, summarize the picture so far.
- Keep tool calls efficient — read what you need, don't explore broadly.

**Do NOT** generate a file with multiple queries and tell the user to run them.
**DO** run them yourself, one at a time, with the user's OK.

### Report

Save to `.ai-team/$NAME/findings.md`:

```markdown
# Investigation: [title]
Date: [today]

## Question
[What was asked]

## Findings
[What you found, with evidence]

## Data
[Key numbers, query results, code references]

## Recommendation
[What to do about it, if applicable]
```

Clean up: `rm .ai-team/.active`

> "Investigation complete. [Brief summary]
>
> Want me to dig deeper, or should we scope a fix?"

---

## BUG PATH (Light Pipeline)

For known broken behavior. Lightweight: 2-3 agent calls.

### Setup

Derive a short kebab-case name. Prefix: `fix/`.
```bash
mkdir -p .ai-team/$NAME
echo "$NAME" > .ai-team/.active
cat > .ai-team/$NAME/shared-context.md << CTX
# Shared Context: $NAME
## Task
BUG: $DESCRIPTION
## Key Files
(SE will populate)
## Decisions
(populated during scoping)
CTX
```

Check git state, offer branch (`fix/$NAME` or stay on current).

### Understand the bug

Before planning, read the relevant code to understand root cause.
If the cause is unclear, investigate briefly.

### Scope (PO on Sonnet — lightweight)

Spawn **product-owner** with **model: sonnet**:
> "MODE 1: Discovery & Requirements.
> This is a BUG FIX — keep it minimal.
> Bug: $DESCRIPTION
> Ask at most 1-2 clarifying questions if anything is ambiguous.
> Write a short SOW: Problem, Root Cause (if known), Fix Approach,
> Acceptance Criteria (how to verify the fix works).
> Save to .ai-team/$NAME/sow.md"

**PAUSE only if** PO has questions. If the bug is clear-cut, PO writes the SOW
immediately without asking questions.

### Plan (SE on Opus — lightweight)

Spawn **software-engineer** (Opus) MODE 1:
> "BUG FIX: $NAME. Read .ai-team/$NAME/sow.md.
> Plan should be 1-2 phases max: fix + test.
> Save to .ai-team/$NAME/technical-plan.md."

**Skip** feasibility check, UX review, DevSecOps plan review, structure check.
Auto-approve: create `.ai-team/$NAME/plan-approved.md`.

> "Bug fix planned. [Show the fix approach + ACs]
>
> 1. `/build-phase all` — fix it now
> 2. Review the plan first"

---

## SMALL FEATURE PATH (Light Pipeline)

For isolated changes: 1-3 files, no architecture decisions. 3-4 agent calls.

### Setup

Derive name. Prefix: `feature/`.
```bash
mkdir -p .ai-team/$FEATURE_NAME
echo "$FEATURE_NAME" > .ai-team/.active
cat > .ai-team/$FEATURE_NAME/shared-context.md << CTX
# Shared Context: $FEATURE_NAME
## Task
$DESCRIPTION
## Key Files
(populated by agents)
## Decisions
(populated during scoping)
CTX
```

Offer git branch.

### Scope (PO on Sonnet)

Spawn **product-owner** with **model: sonnet**:
> "MODE 1: Discovery & Requirements.
> This is a SMALL feature — keep scope tight, max 2-3 questions.
> Feature: $DESCRIPTION
> Write a focused SOW with clear ACs.
> Save to .ai-team/$FEATURE_NAME/sow.md"

**PAUSE** — wait for user if PO has questions.

### Plan (SE on Opus)

Spawn **software-engineer** (Opus) MODE 1:
> "Feature: $FEATURE_NAME. Read .ai-team/$FEATURE_NAME/sow.md.
> This is a small feature — plan should be 1-3 phases.
> Save to .ai-team/$FEATURE_NAME/technical-plan.md."

### Quick Review (DevSecOps on Sonnet — conditional)

**Only if** the change touches auth, user input, API endpoints, or data handling.
Otherwise skip.

Spawn **devsecops** (Sonnet) MODE 1:
> "Quick review of .ai-team/$FEATURE_NAME/technical-plan.md.
> Flag only CRITICAL security concerns. Keep it brief.
> Save to .ai-team/$FEATURE_NAME/devsecops-plan-review.md."

**Skip** feasibility check, UX review, triage structure check, PO plan approval.
Auto-approve: create `.ai-team/$FEATURE_NAME/plan-approved.md`.

> "Small feature planned. [Show phases + ACs]
>
> 1. `/build-phase all` — build it
> 2. Review the plan first"

---

## LARGE FEATURE PATH (Full Pipeline)

New subsystems, multi-component work, architecture decisions. 6-8 agent calls.

### Step 0: Setup

Derive a short, descriptive kebab-case name (2-4 words).
Check `ls .ai-team/` for conflicts. Prefix: `feature/`.

```bash
mkdir -p .ai-team/$FEATURE_NAME
echo "$FEATURE_NAME" > .ai-team/.active
cat > .ai-team/$FEATURE_NAME/shared-context.md << CTX
# Shared Context: $FEATURE_NAME
## Task
$DESCRIPTION
## Key Files
(populated by triage and agents)
## Codebase Patterns
(populated by SE during feasibility)
## Decisions
(populated during scoping)
## User Preferences
(populated from PO discovery)
CTX
```

### Step 0.5: Git Branch

Check git state, offer branch, show recent branches for context.

### Step 1: Quick Context Scan

**SKIP if** user referenced specific files or gave very detailed context.

Spawn **triage** (Haiku):
> "MODE: research.
> Feature description: $DESCRIPTION
> Budget: 5 file reads max. Be fast."

### Step 2: Product Owner — Discovery & Requirements

Spawn the **product-owner** (Opus):
> "MODE 1: Discovery & Requirements.
> Feature: $FEATURE_NAME — Description: $DESCRIPTION
> Feature directory: .ai-team/$FEATURE_NAME/
>
> Research context: {triage output or 'skipped'}
>
> Explore the codebase, ask focused questions (3-5 at a time),
> shape scope (must have / V2 / say no), then generate SOW.
> Save to .ai-team/$FEATURE_NAME/sow.md"

**PAUSE** — Wait for user.

### Step 2.5: Quick Reviews on SOW (parallel)

**SE Feasibility Check** (Sonnet):

Spawn **software-engineer** with **model: sonnet**:
> "MODE: feasibility-check. Read .ai-team/$FEATURE_NAME/sow.md.
> Quick scan of the codebase. DON'T write a full plan.
> Flag: existing code, dependencies, scope sizing, risks, simpler alternatives.
> 5-10 bullet points max.
> Save to .ai-team/$FEATURE_NAME/feasibility-check.md"

**UX Scope Review** (Sonnet) — only if the SOW includes UI work:

Spawn **ux-designer** (Sonnet):
> "Review .ai-team/$FEATURE_NAME/sow.md for UX concerns.
> Flag missing states, accessibility gaps, user flow issues.
> Save to .ai-team/$FEATURE_NAME/ux-scope-review.md"

Present findings, ask if user wants to adjust scope.

### Step 3: Software Engineer — Technical Plan

Spawn **software-engineer** (Opus) MODE 1:
> "Feature: $FEATURE_NAME. Read .ai-team/$FEATURE_NAME/sow.md.
> Also read feasibility-check.md and ux-scope-review.md if they exist.
> Explore codebase. Create technical plan with implementation phases.
> Save to .ai-team/$FEATURE_NAME/technical-plan.md."

### Step 4: DevSecOps — Plan Review

Spawn **devsecops** (Sonnet) MODE 1:
> "Review .ai-team/$FEATURE_NAME/technical-plan.md against sow.md.
> Save to .ai-team/$FEATURE_NAME/devsecops-plan-review.md."

If BLOCKERS -> present before PO review.

### Step 4.5: MLOps — Plan Review (CONDITIONAL)

**Only if** `.claude/stack.md` lists MLOps, OR feature involves ML.

Spawn **mlops** (Sonnet) MODE 1:
> "Review .ai-team/$FEATURE_NAME/technical-plan.md for ML concerns.
> Save to .ai-team/$FEATURE_NAME/mlops-plan-review.md."

### Step 5: Plan Structure Check

Spawn **triage** (Haiku):
> "MODE: plan-structure-check. Feature: $FEATURE_NAME. Docs: .ai-team/$FEATURE_NAME/"

If INCOMPLETE -> send back to SE.

### Step 6: Product Owner — Plan Approval

Spawn **product-owner** with **model: sonnet**:
> "MODE 2: Plan Review.
> Review .ai-team/$FEATURE_NAME/technical-plan.md against sow.md.
> If approved, create .ai-team/$FEATURE_NAME/plan-approved.md."

### Step 7: Present Results

**Approved:**
> "✅ **$FEATURE_NAME** — plan approved.
>
> 1. `/build-phase all` — AI team builds everything autonomously
> 2. `/build-phase 1` — Step-by-step, you review between phases
> 3. Review the plan first"

**Not approved:**
> "❌ PO requested changes. [feedback]
> Options: 1) Revise plan 2) /approve-plan to override 3) Discuss"
