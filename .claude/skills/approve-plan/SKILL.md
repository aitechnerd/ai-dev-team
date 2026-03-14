---
name: approve-plan
description: Manually approve the active feature's technical plan. Use /approve-plan [optional notes].
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

# Manual Plan Approval

## Process

1. Read `.ai-team/.active` for active feature. If none, error.
   Let FEATURE_DIR = `.ai-team/{active_name}/`

2. Verify `$FEATURE_DIR/technical-plan.md` exists. If not:
   > "No technical plan for '{active_name}'. Run /scope first."

3. Briefly note the plan's phases and scope.

4. Create `$FEATURE_DIR/plan-approved.md`:
   ```markdown
   # Plan Approval

   **Feature:** {active_name}
   **Status:** ✅ APPROVED (manual override)
   **Approved by:** User
   **Date:** [current date]

   ## Notes
   $ARGUMENTS
   ```

5. Confirm:
   > "✅ Plan for **{active_name}** approved. Gate open.
   > Run `/build-phase 1` or `/build-phase all`."
