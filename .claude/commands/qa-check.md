---
description: >
  Quick QA check on current changes without the full pipeline.
  Validates against ACs if a feature is active, or does general QA.
  Use: /qa-check
  Use: /qa-check [focus area]
---

# QA Check — Standalone Quality Validation

Lightweight QA pass on current changes. No /scope required.

## Step 1: Detect Context

```bash
git diff --stat HEAD~3..HEAD  # Recent changes
git diff --stat               # Unstaged changes
```

Check if a feature is active:
```bash
cat .ai-team/.active 2>/dev/null
```

If active feature exists → read its SOW for acceptance criteria.
If no feature → do general QA on the diff.

## Step 2: QA Review

Spawn **qa-engineer** (Sonnet):
> "MODE: standalone-check.
> Review the recent changes (last 3 commits + staged + unstaged).
> Stack: read `.claude/stack.md` if available.
> Project context: read `.claude/project-context.md` if available.
> $ARGUMENTS focus: {user's focus area if provided}.
>
> Check:
> 1. Does the code work? Run tests if they exist.
> 2. Edge cases: empty inputs, nulls, boundary values, error paths
> 3. If ACs exist (from active feature SOW): verify each one
> 4. If no ACs: check obvious correctness issues
>
> Output a brief report. Don't save to a file — just print results."

## Step 3: Show Results

> "**QA Check Results**
> [PASS / ISSUES FOUND]
>
> [findings]
>
> Want me to fix any issues?"

If user says yes → spawn SE to fix.
