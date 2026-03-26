---
name: switch
description: >
  Switch the active feature. All subsequent commands will use this feature's
  docs directory. Use /switch [feature-name]. Run /features to see all available features.
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Bash
---

# Switch Active Feature

## Input
Feature name: $ARGUMENTS (can be full path like `feature/my-thing` or short name like `my-thing`)

## Process

0. **If no arguments provided:** List all available features by scanning `.ai-team/*/`
   and `.ai-team/*/*/` for directories containing artifact files (sow.md, technical-plan.md,
   shared-context.md, findings.md, etc.). Show the full relative path for each.
   > "No feature name was provided. Available features:
   > - feature/fellow-order-tracking
   > - feature/lsq-sa-pipeline
   > - fix/login-bug
   >
   > Which feature would you like to switch to?"

1. **Find the feature directory.** Features may be at `.ai-team/$ARGUMENTS/` or nested
   under a prefix like `.ai-team/feature/$ARGUMENTS/` or `.ai-team/fix/$ARGUMENTS/`.
   Search in this order:
   - Exact match: `.ai-team/$ARGUMENTS/` (e.g., `/switch feature/my-thing`)
   - Short name match: search `.ai-team/*/` and `.ai-team/*/*/` for a directory named `$ARGUMENTS`
   - If multiple matches, list them and ask the user to be more specific
   - If no match found:
     > "Feature '$ARGUMENTS' not found. Run `/features` to see available features."

2. Use the **full relative path** (e.g., `feature/my-thing`) as the feature identifier.
   Update the active pointer:
   ```bash
   echo "$FEATURE_PATH" > .ai-team/.active
   ```

3. Read the feature's current state and report:

   Check which files exist in `.ai-team/$FEATURE_PATH/`:
   - sow.md → "SOW ✅"
   - technical-plan.md → "Plan ✅"
   - plan-approved.md → "Approved ✅ (gate open)"
   - qa-report.md → "QA report available"
   - project-summary.md → "Completed"

   > "🔀 Switched to **$FEATURE_PATH**
   >
   > Status: [list available artifacts]
   > Next step: [suggest appropriate action based on state]"

   Suggestions based on state:
   - Only sow.md → "Run SE planning or continue /scope pipeline"
   - sow.md + plan → "Awaiting PO approval or /approve-plan"
   - plan-approved → "Ready to build: /build-phase 1"
   - qa-report → "QA complete, run /validate for summary"
   - project-summary → "Feature complete"
