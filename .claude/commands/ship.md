---
description: >
  Ship the active feature after you've reviewed and tested it.
  Generates a draft PR with description compiled from feature docs.
  Use: /ship
  Use: /ship [any additional notes for the PR]
---

# Ship — Create Draft PR

## Pre-Check

Read `.ai-team/.active` for active feature.
Let FEATURE_DIR = `.ai-team/{active_name}/`

Check that build is complete:
- `$FEATURE_DIR/qa-report.md` exists with PASS or CONDITIONAL PASS
- If not -> "Feature hasn't passed QA yet. Run `/validate` or `/build-phase all` first."

## Step 1: Compile PR Description

Read all feature docs to build the PR body:
- `$FEATURE_DIR/sow.md` -> what and why
- `$FEATURE_DIR/technical-plan.md` -> key architecture decisions
- `$FEATURE_DIR/qa-report.md` -> AC status, test results
- `$FEATURE_DIR/security-scan.md` -> security status (if exists)
- `$FEATURE_DIR/code-review.md` -> review status
- `$FEATURE_DIR/refactor-report.md` -> cleanup done (if exists)

Save to `$FEATURE_DIR/pr-description.md`:

```markdown
## What

[1-2 sentences from SOW executive summary]

## Why

[Problem statement from SOW]

## How

[Key architecture decisions, kept brief]

### Changes
- [file/module]: [what changed, one line each]

## Testing

- All acceptance criteria passing ([N] ACs)
- Test suite: [result]
- Security scan: [clean / findings addressed]
- Code review: [status]

## Notes

[User's $ARGUMENTS if provided, or "None"]

## Deferred to V2

[Items from SOW out-of-scope section]
```

## Step 2: Show PR Preview

Present the compiled description and branch stats:

```bash
git log main..HEAD --oneline
git diff main..HEAD --stat
```

> "**Draft PR for `{active_name}`:**
>
> **Branch:** `{current_branch}` -> `main`
> **Commits:** [N]
> **Files changed:** [N]
>
> PR description saved to `$FEATURE_DIR/pr-description.md`
>
> [show the PR description content]
>
> **Want me to:**
> 1. Create the draft PR with this description (via `gh pr create --draft`)
> 2. Modify the description first
> 3. Just use the saved file — you'll create the PR yourself"

## Step 3: Create Draft PR (if user says yes to option 1)

Only if the user confirms AND `gh` CLI is available:

```bash
gh pr create --draft \
  --title "[Feature] {active_name_humanized}" \
  --body-file "$FEATURE_DIR/pr-description.md" \
  --base main
```

If `gh` is not installed:
> "GitHub CLI (`gh`) not installed. You can create the PR manually using
> the description in `$FEATURE_DIR/pr-description.md`."

If user wants changes -> let them edit, then re-offer to create.
