---
name: review
description: >
  Fix-first review pipeline. Code reviewer auto-fixes mechanical issues
  and only escalates judgment calls. Run on any branch without building.
  Use /review [specific focus area].
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

# Review — Fix-First Review Pipeline

## Overview

Runs the review pipeline with **fix-first** approach: the code reviewer
auto-fixes obvious mechanical issues (missing error handling, debug
statements, dead code, etc.) and only presents judgment calls for your
input. No SOW, no plan, no building — just review and fix.

## Step 1: Detect Changes

```bash
# Get the diff stats
git diff main...HEAD --stat
git diff main...HEAD --name-only
git log main..HEAD --oneline
```

If no changes compared to main:
> "No changes detected on this branch compared to main. Nothing to review."

## Step 2: Triage

Spawn **triage** (Haiku):
> "MODE: diff-triage. Summarize the git diff (main...HEAD) for this branch.
> Focus on: what changed, which files, what areas of the codebase.
> Note any security-relevant changes (auth, input handling, API, DB queries)."

If scanners are configured in `.claude/stack.md`:
```bash
bash ~/.claude/scripts/run-scanners.sh "/tmp/review-scans"
```

Spawn **triage** (Haiku):
> "MODE: scan-triage. Read reports in /tmp/review-scans/."

## Step 3: Code Review (Fix-First)

Spawn **code-reviewer** (Sonnet):
> "Review all changes on this branch (diff against main).
> Stack: read .claude/stack.md for language-specific checks.
> Triage summary: {paste diff-triage output}.
> $ARGUMENTS context: {user's focus area if provided}.
>
> **Fix-first mode:** Auto-fix all mechanical issues (missing error handling,
> debug statements, unused imports, dead code, obvious security fixes, etc.)
> with atomic commits. Report what you fixed and what needs human input.
>
> Save to /tmp/review-report.md."

## Step 4: DevSecOps — CONDITIONAL

**Skip if:** triage says SECURITY_RELEVANT = NO and scans clean.

Spawn **devsecops** (Sonnet) MODE 2:
> "Security review for branch changes. Triage: {scan-triage output}.
> Save to /tmp/security-review.md."

## Step 5: Present Results

> "**Review complete for branch `{current_branch}`**
>
> **Changes reviewed:** [N files, +X/-Y lines]
> **Auto-fixed:** [N issues] (mechanical fixes committed)
> **Needs your input:** [N issues] (judgment calls)
> **Security:** [CLEAN / N findings] (or skipped)
>
> **Auto-fixed items:**
> [list each: file:line — what was fixed — commit sha]
>
> **Needs input:**
> [for each ASK item: file:line — issue — options A/B/C — recommendation]
>
> [Show security findings if any]"

## Step 6: Apply User Decisions

If there are ASK items and the user responds:
- For items the user wants fixed → apply the recommended fix, commit
- For items the user skips → no action

If no ASK items remain (everything was auto-fixed):
> "All issues were mechanical and have been auto-fixed. You're good to ship."

---

## Notes

- This does NOT require a feature to be active. Works on any branch.
- Does NOT generate SOW, technical plan, or feature docs.
- Auto-fix commits use format: `fix(review): <what> at <file:line>`
- Good for: manual coding sessions, prototypes, other AI tool output,
  pre-PR sanity checks, code from new contributors.
- Stack profiles from `.claude/stack.md` are used if available.
