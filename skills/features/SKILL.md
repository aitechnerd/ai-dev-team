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

2. Find all feature directories. Features can be at the top level (`.ai-team/my-thing/`)
   or nested under prefixes (`.ai-team/feature/my-thing/`, `.ai-team/fix/my-thing/`).
   A feature directory is any directory that contains at least one artifact file
   (`sow.md`, `technical-plan.md`, `plan-approved.md`, `shared-context.md`, `findings.md`,
   `qa-report.md`, `project-summary.md`) OR is referenced in `.ai-team/.active`.

   Scan both `.ai-team/*/` and `.ai-team/*/*/` for artifact files.
   Use the relative path from `.ai-team/` as the feature name (e.g., `feature/my-thing`).

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
> | **→ feature/patient-intake** | ✅ Approved | /build-phase 1 |
> | feature/auth-system | 📝 Scoping | Continue /scope pipeline |
> | fix/login-bug | 🏁 Done | — |
>
> **→** = active feature
>
> Commands:
> - `/switch [name]` — switch active feature
> - `/scope [name] [description]` — start a new feature

If `.ai-team/` doesn't exist or is empty:
> "No features yet. Start with `/scope [feature-name] [description]`"
