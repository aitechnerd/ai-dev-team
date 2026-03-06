---
description: >
  Run validation pipeline on active feature. Haiku triages first,
  then conditionally runs review agents. Includes code health and ship prep.
  Use: /validate [optional: specific area to focus on]
---

# Validation Pipeline

## Input
Focus area (optional): $ARGUMENTS

## Pre-Check
Read `.ai-team/.active` for active feature. If none -> `/switch` first.
Let FEATURE_DIR = `.ai-team/{active_name}/`
Verify `$FEATURE_DIR/sow.md` exists. If not -> `/scope` first.

## Step 1: Run Scanners
```bash
bash ~/.claude/scripts/run-scanners.sh "$FEATURE_DIR/scans"
```

## Step 2: Haiku Triage

Spawn **triage** (Haiku):
> "MODE: scan-triage. Read $FEATURE_DIR/scans/."
> "MODE: diff-triage. Summarize git diff."
> "MODE: ac-check. Docs: $FEATURE_DIR."

## Step 3: Code Review
Spawn **code-reviewer** (Sonnet):
> "Review {active_name}. Triage: {paste triage output}.
> Focus: $ARGUMENTS. Save to $FEATURE_DIR/code-review.md."

If REQUEST CHANGES -> SE fixes autonomously, re-review once.

## Step 4: DevSecOps — CONDITIONAL
**Skip if:** scan-triage CLEAN AND diff-triage SECURITY_RELEVANT = NO.
**Run if:** findings or security-relevant changes.
Spawn **devsecops** (Sonnet) MODE 2.
If CRITICAL -> SE fixes autonomously.

## Step 4.5: MLOps — CONDITIONAL
**Only if** MLOps stack active AND feature touches ML.

## Step 5: QA Validation
Spawn **qa-engineer** (Sonnet):
> "Validate {active_name}. AC triage: {ac-check output}.
> Focus: $ARGUMENTS. Save to $FEATURE_DIR/qa-report.md."

If FAIL -> SE fixes -> re-validate -> max 2 rounds -> escalate.

## Step 6: Code Health
Spawn **code-health** (Sonnet) MODE 1:
> "Post-feature refactor for {active_name}. Save to $FEATURE_DIR/refactor-report.md."

## Step 7: PO Summary — CONDITIONAL
**Skip if:** small feature. **Run if:** 3+ phases or 4+ ACs.

## Step 8: Present Results

> "**Validation complete for `{active_name}`.**
> [pipeline results summary]
>
> Review the code and test it yourself.
> Run `/ship` when ready to create a draft PR."
