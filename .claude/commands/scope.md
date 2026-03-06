---
description: >
  Smart entry point for any task. You describe what you need, and the system
  figures out the right approach: investigation, bug fix, or feature build.
  Use: /scope [describe what you want]
  Example: /scope why are only a few lab results returned when we sent many orders
  Example: /scope the search is returning wrong results for partial names
  Example: /scope Build a patient intake form with demographics
---

# Scope — Smart Task Router

## Input
Task description: $ARGUMENTS

## Step 0: Classify the Task

Read the description carefully. Consider:
- Is the user asking a question or trying to understand something? → **INVESTIGATION**
- Is something broken that needs fixing? → **BUG**
- Is the user asking to build, add, or create something new? → **FEATURE**

Use your judgment. Don't rely on keywords — understand the intent.

Examples that are INVESTIGATION (not bugs):
- "why are only a few lab results returned" — the user doesn't know what's wrong yet
- "check if our Snowflake queries are hitting the right tables"
- "how does the referral pipeline currently work"
- "confirm that patient data is encrypted at rest"
- "look into why the cron job takes 3 hours"

Examples that are BUG:
- "the search returns wrong results for partial names" — behavior is known, it's wrong
- "patients can't upload documents on mobile"
- "the nightly sync job has been failing since Tuesday"

Examples that are FEATURE:
- "add fuzzy search to patient lookup"
- "build a dashboard showing referral conversion rates"
- "set up automated lab result notifications"

**Tell the user what you detected:**
> "This looks like an **investigation** / **bug fix** / **new feature**. [one line why]"
>
> If the user disagrees, they can say so and you reclassify.

---

## INVESTIGATION PATH

For questions, audits, understanding how things work, data analysis, debugging.

### Setup

Derive a short kebab-case name.
```bash
mkdir -p .ai-team/$NAME
echo "$NAME" > .ai-team/.active
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
> Want me to dig deeper, or should we scope a fix for something?"

---

## BUG PATH

For known broken behavior that needs fixing.

### Setup

Derive a short kebab-case name. Prefix: `fix/`.
```bash
mkdir -p .ai-team/$NAME
echo "$NAME" > .ai-team/.active
```

Check git state, offer branch (`fix/$NAME` or stay on current).

### Understand the bug

Before planning a fix, make sure we understand the problem.
Read the relevant code. If the cause is unclear, investigate briefly
(like the investigation path) to understand root cause.

Show what you find:
> "I can see the issue: [explanation]. Here's my plan to fix it."

### Scope (lightweight)

Spawn **product-owner** (Opus):
> "MODE 1: Discovery & Requirements.
> This is a BUG FIX — keep it minimal.
> Bug: $DESCRIPTION
> Ask at most 1-2 clarifying questions if anything is ambiguous.
> Write a short SOW: Problem, Root Cause (if known), Fix Approach,
> Acceptance Criteria (how to verify the fix works).
> Save to .ai-team/$NAME/sow.md"

**PAUSE only if** PO has questions. If the bug is clear-cut, PO writes the SOW
immediately without asking questions.

### Plan (lightweight)

Spawn **software-engineer** (Opus) MODE 1:
> "BUG FIX: $NAME. Read .ai-team/$NAME/sow.md.
> Plan should be 1-2 phases max: fix + test.
> Save to .ai-team/$NAME/technical-plan.md."

**Skip** DevSecOps plan review and structure check for bug fixes.
Auto-approve: create `.ai-team/$NAME/plan-approved.md`.

> "Bug fix planned.
>
> [Show the fix approach + acceptance criteria]
>
> 1. `/build-phase all` — fix it now
> 2. Review the plan first: `.ai-team/$NAME/technical-plan.md`"

---

## FEATURE PATH

Full planning pipeline for new functionality.

### Step 0: Setup

Derive a short, descriptive kebab-case name from $ARGUMENTS (2-4 words).
Check `ls .ai-team/` for conflicts — append differentiator if needed.
Prefix: `feature/`.

```bash
mkdir -p .ai-team/$FEATURE_NAME
echo "$FEATURE_NAME" > .ai-team/.active
```

### Step 0.5: Git Branch

Check current git state:
```bash
git branch --show-current
git status --porcelain
git branch --list --sort=-committerdate | head -10
```

Offer to create a branch or stay on current.

### Step 1: Quick Context Scan

**SKIP if** user referenced specific files or gave very detailed context.

Otherwise, spawn **triage** (Haiku):
> "MODE: research.
> Feature description: $DESCRIPTION
> Budget: 5 file reads max. Be fast."

### Step 2: Product Owner — Discovery & Requirements

Spawn the **product-owner** (Opus):
> "MODE 1: Discovery & Requirements.
> Feature: $FEATURE_NAME — Description: $DESCRIPTION
> Feature directory: .ai-team/$FEATURE_NAME/
>
> Research context: {triage output or 'skipped — user provided detailed context'}
>
> Explore the codebase, ask focused questions (3-5 at a time),
> shape scope (must have / V2 / say no), then generate SOW.
> Save to .ai-team/$FEATURE_NAME/sow.md"

**PAUSE** — Wait for user to respond to PO's questions.

### Step 2.5: Quick Reviews on SOW (CONDITIONAL, parallel)

Before the SE writes a full technical plan, run quick reviews on the SOW.
These run in parallel when both apply.

**SE Feasibility Check** — always run for features:

Spawn **software-engineer** with **model: sonnet** (quick scan, not full planning):
> "MODE: feasibility-check. Read .ai-team/$FEATURE_NAME/sow.md.
> Quick scan of the codebase for relevant code. DON'T write a full plan yet.
> Flag:
> - Existing code/services that already do part of this
> - Dependencies or migrations that affect other features
> - Scope that's bigger (or smaller) than it sounds
> - Technical risks or blockers
> - Simpler alternatives the PO should consider
> Keep it brief — 5-10 bullet points max.
> Save to .ai-team/$FEATURE_NAME/feasibility-check.md"

**UX Scope Review** — only if the SOW includes UI/UX work (user-facing screens,
forms, components, dashboards, notifications). Skip for backend, data, API-only,
infrastructure, or investigation tasks.

Spawn **ux-designer** (Sonnet):
> "Review .ai-team/$FEATURE_NAME/sow.md for UX concerns.
> Check existing UI patterns in the codebase.
> Flag missing states, accessibility gaps, and user flow issues.
> Suggest any UX-specific acceptance criteria to add.
> Save to .ai-team/$FEATURE_NAME/ux-scope-review.md"

**Present findings to user:**

> "Before we plan, the team flagged a few things:
>
> **Technical:**
> [key points from feasibility-check.md]
>
> **UX:** (if applicable)
> [key points from ux-scope-review.md]
>
> Want to adjust the scope based on any of this?"

If user wants changes → ask PO to update the SOW.

### Step 3: Software Engineer — Technical Plan

Spawn **software-engineer** (Opus) MODE 1:
> "Feature: $FEATURE_NAME. Read .ai-team/$FEATURE_NAME/sow.md.
> Explore codebase. Create technical plan with implementation phases.
> Save to .ai-team/$FEATURE_NAME/technical-plan.md."

### Step 4: DevSecOps — Plan Review

Spawn **devsecops** (Sonnet) MODE 1:
> "Review .ai-team/$FEATURE_NAME/technical-plan.md against sow.md.
> Save to .ai-team/$FEATURE_NAME/devsecops-plan-review.md."

If BLOCKERS -> present them before PO review.

### Step 4.5: MLOps — Plan Review (CONDITIONAL)

**Only run if:** `.claude/stack.md` lists MLOps, OR the feature involves
ML training, inference, data pipelines, or experiment tracking.

Spawn **mlops** (Sonnet) MODE 1:
> "Review .ai-team/$FEATURE_NAME/technical-plan.md for ML-specific concerns.
> Save to .ai-team/$FEATURE_NAME/mlops-plan-review.md."

### Step 5: Plan Structure Check

Spawn **triage** (Haiku):
> "MODE: plan-structure-check. Feature: $FEATURE_NAME. Docs: .ai-team/$FEATURE_NAME/"

If INCOMPLETE -> send back to SE.
If STRUCTURALLY_COMPLETE -> proceed.

### Step 6: Product Owner — Plan Review

Spawn **product-owner** (Opus) MODE 2:
> "Review .ai-team/$FEATURE_NAME/technical-plan.md against sow.md.
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
