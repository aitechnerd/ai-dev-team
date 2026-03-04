---
description: >
  Start scoping a new feature or bug fix. Auto-generates directory name,
  offers to create a git branch, researches best practices, then PO leads discovery.
  Use: /scope [description of what you want to build or fix]
  Example: /scope Build a patient intake form with demographics
  Example: /scope Fix the SSH connection timeout on slow networks
---

# Scope — PO-Led Planning Pipeline

## Input
Task description: $ARGUMENTS

## Step 0: Generate Feature Name & Set Up

Derive a short, descriptive kebab-case name from $ARGUMENTS (2-4 words).
Check `ls docs/features/` for conflicts — append differentiator if needed.

Detect type from description:
- Contains "fix", "bug", "broken", "crash", "error" -> type: **bugfix**, prefix: `fix/`
- Otherwise -> type: **feature**, prefix: `feature/`

Set variables:
- $FEATURE_NAME = generated kebab-case name
- $DESCRIPTION = full $ARGUMENTS text
- $BRANCH_NAME = `{prefix}{FEATURE_NAME}` (e.g. `feature/ssh-agent-forwarding` or `fix/connection-timeout`)

Create the feature directory:
```bash
mkdir -p docs/features/$FEATURE_NAME
echo "$FEATURE_NAME" > docs/features/.active
```

## Step 0.5: Git Branch

Check current git state:
```bash
git branch --show-current
git status --porcelain
git branch --list --sort=-committerdate | head -10
```

Present to user:
> "Feature **$FEATURE_NAME** created. Scoping: *$DESCRIPTION*
>
> **Git branch setup:**
> Current branch: `{current_branch}`
> Suggested branch: `$BRANCH_NAME`
>
> 1. **Create `$BRANCH_NAME`** from... which base?
>    - `{current_branch}` (current)
>    - `main`
>    - `develop`
>    - Other (specify)
> 2. **Stay on `{current_branch}`** — no new branch
> 3. **Custom branch name** — specify name and base"

If they want a branch:
- If uncommitted changes exist, ask: "Stash uncommitted changes first? (yes/no)"
  - If yes: `git stash`
- Create and switch: `git checkout -b $BRANCH_NAME {chosen_base}`
- If stashed: remind them changes are stashed

Show recent branches for context so they can pick the right base.

## Step 1: Haiku Research — Best Practices

Before the PO starts discovery, gather domain knowledge.

Spawn **triage** (Haiku):
> "MODE: research.
> Feature description: $DESCRIPTION
> Project context: [language/framework from codebase inspection]
> Research best practices, common pitfalls, similar implementations,
> and security considerations for this type of feature."

Save triage research output — it gets passed to PO in the next step.

## Step 2: Product Owner — Discovery & Requirements

Spawn the **product-owner** (Opus):
> "MODE 1: Discovery & Requirements.
> Feature: $FEATURE_NAME — Description: $DESCRIPTION
> Feature directory: docs/features/$FEATURE_NAME/
>
> Research context (from triage):
> {paste research output}
>
> Use the research to inform your discovery questions and scope decisions.
> Explore the codebase, ask focused questions (3-5 at a time),
> shape scope (must have / V2 / say no), then generate SOW.
> Save to docs/features/$FEATURE_NAME/sow.md"

**PAUSE** — Wait for user to respond to PO's questions and agree on scope.

## Step 3: Software Engineer — Technical Plan

Spawn **software-engineer** (Opus) MODE 1:
> "Feature: $FEATURE_NAME. Read docs/features/$FEATURE_NAME/sow.md.
> Explore codebase. Create technical plan with implementation phases.
> Save to docs/features/$FEATURE_NAME/technical-plan.md."

## Step 4: DevSecOps — Plan Review

Spawn **devsecops** (Sonnet) MODE 1:
> "Review docs/features/$FEATURE_NAME/technical-plan.md against sow.md.
> Save to docs/features/$FEATURE_NAME/devsecops-plan-review.md."

If BLOCKERS -> present them before PO review, ask how to proceed.

## Step 4.5: MLOps — Plan Review (CONDITIONAL)

**Only run if:** `.claude/stack.md` lists MLOps as active, OR the feature involves
model training, inference, data pipelines, or experiment tracking.

Spawn **mlops** (Sonnet) MODE 1:
> "Review docs/features/$FEATURE_NAME/technical-plan.md for ML-specific concerns.
> Save to docs/features/$FEATURE_NAME/mlops-plan-review.md."

## Step 5: Haiku — Plan Structure Check

Spawn **triage** (Haiku):
> "MODE: plan-structure-check. Feature: $FEATURE_NAME. Docs: docs/features/$FEATURE_NAME/"

If INCOMPLETE -> send back to SE to fix missing sections.
If STRUCTURALLY_COMPLETE -> proceed to PO review.

## Step 6: Product Owner — Plan Review

Spawn **product-owner** (Opus) MODE 2:
> "Review docs/features/$FEATURE_NAME/technical-plan.md against sow.md.
> Plan structure check: {paste triage output}.
> If approved, create docs/features/$FEATURE_NAME/plan-approved.md."

## Step 7: Present Results & Launch

**Approved:**
> "✅ **$FEATURE_NAME** — plan approved.
> Branch: `$BRANCH_NAME`
>
> **What's next?**
> 1. `/build-phase all` — **Autopilot**: AI team builds everything, reviews, tests,
>    fixes issues, and refactors. You review the result, then `/ship` when ready.
> 2. `/build-phase 1` — **Step-by-step**: build one phase at a time, you review between phases.
> 3. Review the plan first: `docs/features/$FEATURE_NAME/technical-plan.md`"

**Not approved:**
> "❌ PO requested changes. [feedback]
> Options: 1) Revise plan 2) /approve-plan to override 3) Discuss"
