---
name: features
description: List all feature plans and their current status. Shows which feature is active and the state of each.
allowed-tools:
  - Read
  - Bash
  - Glob
---

# List All Feature Plans

## Process

1. Read the active feature from `.ai-team/.active` (if it exists)

2. List all directories in `.ai-team/` (excluding .active file)

3. For each feature directory, check which artifacts exist and determine status:
   - Only directory exists → 🆕 Created (no SOW yet)
   - sow.md → 📝 Scoping (SOW written, no plan)
   - sow.md + technical-plan.md → 📐 Planned (awaiting approval)
   - sow.md + technical-plan.md + plan-approved.md → ✅ Approved (ready to build)
   - plan-approved.md + code-review.md → 🔍 In Review
   - plan-approved.md + qa-report.md → 🧪 QA Complete
   - project-summary.md → 🏁 Done

4. Present as a table:

> **Feature Plans**
>
> | Feature | Status | Next Step |
> |---------|--------|-----------|
> | **→ patient-intake** | ✅ Approved | /build-phase 1 |
> | auth-system | 📝 Scoping | Continue /scope pipeline |
> | reporting-dashboard | 🏁 Done | — |
>
> **→** = active feature
>
> Commands:
> - `/switch [name]` — switch active feature
> - `/scope [name] [description]` — start a new feature

If `.ai-team/` doesn't exist or is empty:
> "No features yet. Start with `/scope [feature-name] [description]`"
