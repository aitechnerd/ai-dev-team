---
description: >
  Switch the active feature. All subsequent commands will use this feature's
  docs directory. Use: /switch [feature-name]
  Run /features to see all available features.
---

# Switch Active Feature

## Input
Feature name: $ARGUMENTS

## Process

1. Check if `.ai-team/$ARGUMENTS/` exists. If not:
   > "Feature '$ARGUMENTS' not found. Run `/features` to see available features."

2. Update the active pointer:
   ```bash
   echo "$ARGUMENTS" > .ai-team/.active
   ```

3. Read the feature's current state and report:

   Check which files exist in `.ai-team/$ARGUMENTS/`:
   - sow.md → "SOW ✅"
   - technical-plan.md → "Plan ✅"  
   - plan-approved.md → "Approved ✅ (gate open)"
   - qa-report.md → "QA report available"
   - project-summary.md → "Completed"

   > "🔀 Switched to **$ARGUMENTS**
   >
   > Status: [list available artifacts]
   > Next step: [suggest appropriate action based on state]"

   Suggestions based on state:
   - Only sow.md → "Run SE planning or continue /scope pipeline"
   - sow.md + plan → "Awaiting PO approval or /approve-plan"
   - plan-approved → "Ready to build: /build-phase 1"
   - qa-report → "QA complete, run /validate for summary"
   - project-summary → "Feature complete"
