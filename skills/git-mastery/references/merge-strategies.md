# Merge Strategies & Conflict Resolution

## Merge vs Rebase

| Aspect | Merge | Rebase |
|--------|-------|--------|
| History | Preserves branch topology | Linear history |
| Safety | Safe for shared branches | Only for local branches |
| Conflicts | Resolve once | Resolve per-commit |
| Best for | Shared branches, PRs | Local cleanup before PR |

### When to merge
- Integrating a PR into main
- Pulling upstream changes into a long-lived branch
- When branch history matters (releases, audits)

### When to rebase
- Cleaning up local commits before opening a PR
- Keeping a feature branch up to date with main (if no one else has pulled it)
- Squashing WIP commits into logical units

### Golden rule
**Never rebase commits that others may have based work on.** If the branch has been pushed and someone might have pulled it, use merge.

## Conflict Resolution Patterns

### 1. Read Before Editing

Before touching a conflict, understand both sides:
```
<<<<<<< HEAD (yours)
  validate_user(params)
=======
  authenticate_user(params, session)
>>>>>>> feature/auth
```

Ask: *Why* did each side make this change? Often one supersedes the other.

### 2. Common Conflict Scenarios

**Both sides modified the same function:**
- If changes are to different parts → combine both
- If changes conflict logically → understand which behavior is correct
- If one refactored what the other modified → apply the modification to the refactored version

**Both sides added to the same list/config:**
- Usually both additions are wanted → keep both, check for duplicates

**One side deleted what the other modified:**
- Check if the deletion was intentional (refactor) or accidental
- If refactored away → apply the modification's intent to the new structure

**Lock files (package-lock.json, Cargo.lock, yarn.lock):**
- Accept either side, then regenerate: `npm install` / `cargo update` / `yarn install`

### 3. Resolution Workflow

```bash
# See which files conflict
git status

# For each conflicted file:
# 1. Open and understand both sides
# 2. Resolve the conflict
# 3. Stage the resolved file
git add <resolved-file>

# After all conflicts resolved:
git merge --continue   # or git rebase --continue

# Verify
git diff HEAD~1        # Review the merge result
npm test               # Run tests
```

### 4. Aborting

```bash
git merge --abort      # Undo a merge in progress
git rebase --abort     # Undo a rebase in progress
git cherry-pick --abort
```

## Merge Commit Messages

For merge commits, use:
```
Merge branch 'feature/auth' into main

Adds OAuth2 login flow with Google and GitHub providers.
Includes rate limiting on token endpoint.
```

## Strategies for Keeping Branches Current

### Short-lived branches (< 1 week)
```bash
# Rebase onto latest main before PR
git fetch origin main
git rebase origin/main
```

### Long-lived branches (> 1 week)
```bash
# Merge main periodically to avoid massive conflicts
git fetch origin main
git merge origin/main
```

### Stacked PRs
```bash
# PR1: feature/base
# PR2: feature/extension (based on PR1)
git checkout feature/base
git checkout -b feature/extension
# When PR1 merges, rebase PR2:
git rebase --onto main feature/base feature/extension
```
