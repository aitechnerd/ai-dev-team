---
description: >
  Revert a specific phase or the entire feature by logical unit.
  Uses auto-commits from /build-phase to cleanly undo work.
  Use: /revert phase 3
  Use: /revert feature
  Use: /revert last
---

# Revert — Semantic Undo by Logical Unit

## Overview

Reverts work by logical unit (phase, feature, or last commit), not by
hunting individual commits. Works because `/build-phase` auto-commits
with structured messages like `[feature-name] Phase 3: Add auth middleware`.

## Usage

### `/revert phase [N]`

Revert a specific phase's commits:

```bash
# Find commits for this phase
FEATURE=$(cat .ai-team/.active)
git log --oneline --grep="\[$FEATURE\] Phase $N"
```

Show the commits that will be reverted:
> "These commits will be reverted:
> - abc1234 [patient-search] Phase 3: Add fuzzy matching
> - def5678 [patient-search] Phase 3: fix test for fuzzy matching
>
> This will undo Phase 3 but keep Phases 1-2 intact.
> Proceed? (yes/no)"

If confirmed:
```bash
# Revert in reverse order (newest first)
git revert --no-commit <commits in reverse>
git commit -m "[{feature}] Revert Phase $N: [phase title]"
```

Update technical-plan.md: mark Phase N back to `- [ ]`.

### `/revert feature`

Revert the entire active feature:

```bash
FEATURE=$(cat .ai-team/.active)
# Find all commits for this feature
git log --oneline --grep="\[$FEATURE\]"
```

Show summary:
> "This will revert ALL commits for `{feature}` ([N] commits).
> The branch will remain but code returns to pre-feature state.
> Proceed? (yes/no)"

If confirmed:
```bash
git revert --no-commit <all feature commits in reverse>
git commit -m "[{feature}] Revert entire feature"
```

### `/revert last`

Revert just the most recent commit:

```bash
git log -1 --oneline
```

> "Revert this commit?
> - abc1234 [patient-search] Phase 2: Add search endpoint
> (yes/no)"

```bash
git revert HEAD --no-edit
```

## Safety

- Always shows what will be reverted BEFORE doing it
- Uses `git revert` (creates new commits), never `git reset` (preserves history)
- Updates technical-plan.md checkboxes to reflect reverted state
- Does NOT delete feature docs (SOW, plan, reviews remain for reference)
