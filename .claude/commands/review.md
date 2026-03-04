---
description: >
  Run the review pipeline on the current branch without building anything.
  Useful when you coded manually or used default Claude Code and want
  the AI team to review your work.
  Use: /review
  Use: /review [specific focus area]
---

# Review — Review-Only Mode

## Overview

Runs the full review pipeline (code review, security, QA) on whatever
changes exist on the current branch compared to main. No SOW, no plan,
no building — just the review agents.

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

## Step 3: Code Review

Spawn **code-reviewer** (Sonnet):
> "Review all changes on this branch (diff against main).
> Stack: read .claude/stack.md for language-specific checks.
> Triage summary: {paste diff-triage output}.
> $ARGUMENTS context: {user's focus area if provided}.
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
> **Code review:** [APPROVED / REQUEST CHANGES — N issues]
> **Security:** [CLEAN / N findings] (or skipped)
>
> [Show key findings from code-review.md]
> [Show key findings from security-review.md if run]
>
> **Want me to fix the issues found?** I can address them now."

If user says yes -> spawn SE to fix, re-run review once.

---

## Notes

- This does NOT require a feature to be active. Works on any branch.
- Does NOT generate SOW, technical plan, or feature docs.
- Good for: manual coding sessions, prototypes, other AI tool output,
  pre-PR sanity checks, code from new contributors.
- Stack profiles from `.claude/stack.md` are used if available.
