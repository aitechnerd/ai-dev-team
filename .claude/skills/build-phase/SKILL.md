---
name: build-phase
description: >
  Implement phases from the active feature's technical plan.
  Single phase: /build-phase 1
  Autonomous mode: /build-phase all — builds everything, validates, fixes, ships.
  In autonomous mode the AI team handles issues internally, only escalating
  truly blocked problems to you.
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

# Build Phase

## Input
Phase: $ARGUMENTS

## Pre-Check

1. Read `.ai-team/.active` for active feature.
   No active feature -> tell user to run `/scope` or `/switch`.
2. Let FEATURE_DIR = `.ai-team/{active_name}/`
3. Verify `$FEATURE_DIR/plan-approved.md` exists. If not -> approve plan first.
4. Read `$FEATURE_DIR/technical-plan.md` to identify all phases.

---

## SINGLE PHASE MODE ($ARGUMENTS is a number or phase name)

### Implement
Spawn **software-engineer** (Opus) MODE 2:
> "Implement Phase $ARGUMENTS for feature {active_name}.
> Docs: $FEATURE_DIR. Follow the plan. Write tests alongside code.
> Mark phase COMPLETE in technical-plan.md when done."

### After Implementation
If more phases remain -> report progress, suggest next phase or `/build-phase all`.
If all phases COMPLETE -> run validation pipeline (same as autonomous steps 2-5).

---

## AUTONOMOUS MODE ($ARGUMENTS is "all")

This is the full hands-off pipeline. The AI team builds, reviews, fixes, and
ships without user intervention. Only escalate if an issue can't be resolved
after 2 fix attempts.

### Step 1: Build All Phases

For each phase in order from the technical plan:

1. Spawn **software-engineer** (Opus) MODE 2:
   > "Implement Phase [N] for feature {active_name}.
   > Docs: $FEATURE_DIR. Follow the plan. Write tests alongside code.
   > Mark phase COMPLETE when done."

2. **Per-phase validation** — immediately after SE completes, run:
   ```bash
   # Stack test command from .claude/stack.md (e.g. cargo test, rspec, pytest)
   [stack_test_command]
   # Stack lint command (e.g. cargo clippy, rubocop, ruff)
   [stack_lint_command]
   ```
   If tests/lint fail:
   - SE fixes (up to 2 attempts per phase)
   - If still failing after 2 attempts -> STOP, report to user with details

3. **Auto-commit** after each successful phase:
   ```bash
   git add -A
   git commit -m "[{active_name}] Phase [N]: [phase title from plan]"
   ```

4. **Update progress** — mark the phase checkbox in technical-plan.md:
   `- [ ] Phase N: ...` → `- [x] Phase N: ...`
   This enables crash recovery: if interrupted, re-running `/build-phase all`
   skips phases already marked `[x]` and resumes from the first unchecked phase.

Report progress: "✅ Phase [N/total] complete. Committed. Moving to [next phase name]..."

### Step 2: Run Scanners + Triage

```bash
bash ~/.claude/scripts/run-scanners.sh "$FEATURE_DIR/scans"
```

Spawn **triage** (Haiku):
> "MODE: scan-triage. Read all reports in $FEATURE_DIR/scans/."
> "MODE: diff-triage. Summarize the git diff for this feature."

### Step 3: Code Review + DevSecOps (parallel where possible)

Run **code-reviewer** and **devsecops** assessment in parallel when both need to run:

Spawn **code-reviewer** (Sonnet):
> "Review feature {active_name}. Docs: $FEATURE_DIR.
> Triage summary: {paste triage output}.
> Save to $FEATURE_DIR/code-review.md."

**DevSecOps — CONDITIONAL** (runs in parallel with code review if needed):
Skip if triage RECOMMENDATION = CLEAN AND SECURITY_RELEVANT = NO.
Otherwise spawn **devsecops** (Sonnet) MODE 2:
> "Security scan for {active_name}. Triage: {scan-triage output}.
> Reports in $FEATURE_DIR/scans/. Save to $FEATURE_DIR/security-scan.md."

**If either requests changes** (autonomous handling):
- Spawn SE MODE 3 to fix issues from both reviews
- Auto-commit fixes
- If CRITICAL security findings persist -> STOP, escalate to user

### Step 4: MLOps — CONDITIONAL

**Only if** `.claude/stack.md` lists MLOps AND feature touches ML components.
Spawn **mlops** (Sonnet) MODE 2.

### Step 5: QA Validation

Spawn **triage** (Haiku):
> "MODE: ac-check. Feature: {active_name}. Docs: $FEATURE_DIR."

Spawn **qa-engineer** (Sonnet):
> "Validate {active_name}. AC triage: {paste ac-check output}.
> Save to $FEATURE_DIR/qa-report.md."

**If FAIL** (autonomous handling):
1. Spawn SE MODE 3 to fix critical/high issues
2. Auto-commit fixes
3. Re-run scanners + triage
4. Re-run QA
5. If still FAIL after 2 rounds -> STOP, escalate to user with details

**If CONDITIONAL PASS**: note the caveats, continue.
**If PASS**: continue.

### Step 6: Second-Pass Review (focused)

Quick sanity check on the fixes from steps 3-5. Fixes themselves can
introduce new issues — this catches them.

Spawn **code-reviewer** (Sonnet) with narrowed scope:
> "Second-pass review for {active_name}. Focus on CRITICAL and HIGH only.
> Only review changes since the first code review (fix commits).
> Skip style, documentation, minor issues. Save to $FEATURE_DIR/code-review-2.md."

If clean or minor-only -> continue.
If critical found -> SE fixes, auto-commit, no further review loops.

### Step 7: Code Health

Spawn **code-health** (Sonnet) MODE 1:
> "Post-feature refactor for {active_name}. Docs: $FEATURE_DIR.
> Review changed code, simplify, remove duplication.
> Run tests after changes. Save to $FEATURE_DIR/refactor-report.md."

Auto-commit any refactoring changes.

### Step 8: PO Summary — CONDITIONAL

**Skip if:** small feature (1-2 phases, <=3 ACs).
**Run if:** 3+ phases or 4+ ACs.
Spawn **product-owner** (Opus) MODE 3:
> "Completion summary for {active_name}. Save to $FEATURE_DIR/project-summary.md."

### Step 9: Final Report

Present everything to the user:

> "**Feature `{active_name}` — build complete. Ready for your review.**
>
> **Pipeline Results:**
> - Phases built: [N/N]
> - Code review: [APPROVED] (2-pass)
> - Security: [CLEAN / findings addressed]
> - QA: [PASS / CONDITIONAL PASS]
> - Refactoring: [N improvements made]
> - Commits: [N] (one per phase + fixes)
>
> **Files changed:** [N] | **Tests:** [passing count]
> **Branch:** `{current_branch}`
>
> Docs generated:
> - `$FEATURE_DIR/code-review.md`
> - `$FEATURE_DIR/code-review-2.md` (second pass)
> - `$FEATURE_DIR/security-scan.md` (if run)
> - `$FEATURE_DIR/qa-report.md`
> - `$FEATURE_DIR/refactor-report.md`
>
> **Next steps:**
> - Review the code and test it yourself
> - Ask me to make changes if anything needs adjustment
> - Run `/ship` when you're satisfied — creates a draft PR"

---

## Escalation Rules (Autonomous Mode)

The AI team handles issues internally EXCEPT:
- Tests fail after 2 fix attempts on a single phase -> STOP
- CRITICAL security findings persist after fix -> STOP
- QA FAIL persists after 2 fix rounds -> STOP
- Ambiguous requirements (AC unclear) -> STOP
- External dependency unavailable (API down, package missing) -> STOP

When stopped, provide: what was completed, what failed, specific error details,
and suggested next steps.
