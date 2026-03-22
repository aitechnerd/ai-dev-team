# Advanced Git Operations

## Git Bisect — Find the Commit That Broke Things

```bash
git bisect start
git bisect bad                  # Current commit is broken
git bisect good <known-good>    # Last known working commit

# Git checks out middle commits. For each:
# Run your test, then:
git bisect good    # or
git bisect bad

# When found:
git bisect reset
```

Automate with a test script:
```bash
git bisect run ./test-script.sh
# Exit 0 = good, exit 1 = bad
```

## Cherry-Pick — Apply Specific Commits

```bash
# Apply a single commit to current branch
git cherry-pick <commit-sha>

# Apply without committing (stage only)
git cherry-pick --no-commit <commit-sha>

# Apply a range
git cherry-pick <start>..<end>

# If conflicts arise
git cherry-pick --continue   # after resolving
git cherry-pick --abort      # to cancel
```

## Reflog Recovery — Undo Almost Anything

The reflog tracks every HEAD movement for 90 days:

```bash
# See recent HEAD positions
git reflog --date=relative

# Recover after bad reset
git reflog
git reset --hard HEAD@{2}     # Go back 2 reflog entries

# Recover deleted branch
git reflog | grep "checkout: moving from deleted-branch"
git checkout -b recovered-branch <sha>

# Recover dropped stash
git fsck --no-reflog | grep "dangling commit"
git stash apply <sha>
```

## Subtree — Include External Repos

```bash
# Add a subtree
git subtree add --prefix=vendor/lib https://github.com/org/lib.git main --squash

# Pull updates
git subtree pull --prefix=vendor/lib https://github.com/org/lib.git main --squash

# Push changes back upstream
git subtree push --prefix=vendor/lib https://github.com/org/lib.git feature-branch
```

## Stash — Save Work in Progress

```bash
# Stash with a description
git stash push -m "halfway through auth refactor"

# Stash including untracked files
git stash push -u -m "includes new test fixtures"

# Apply specific stash
git stash list
git stash apply stash@{2}

# Pop (apply and remove)
git stash pop

# Create branch from stash
git stash branch new-branch stash@{0}
```

## Rewriting History (Local Only)

```bash
# Amend last commit message
git commit --amend -m "new message"

# Add forgotten files to last commit
git add forgotten-file.txt
git commit --amend --no-edit

# Reorder/squash/edit commits
git rebase -i HEAD~5

# Filter-branch replacement (remove file from all history)
git filter-repo --path secrets.env --invert-paths
```

## Worktree Management

```bash
# List all worktrees
git worktree list

# Create linked worktree on existing branch
git worktree add ../hotfix-dir hotfix/urgent

# Create with new branch
git worktree add ../feature-dir -b feature/new-thing

# Lock worktree (prevent accidental removal)
git worktree lock ../feature-dir

# Prune stale worktree entries
git worktree prune
```

## Useful Diagnostic Commands

```bash
# Who changed this line last?
git blame -L 10,20 src/auth.py

# Find commits that changed a specific function
git log -p -S "def authenticate" -- "*.py"

# Show file at specific commit
git show HEAD~3:src/config.py

# Diff between branches (files only)
git diff main..feature --name-only

# Commits on feature not on main
git log main..feature --oneline

# Find large files in history
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | sort -k3 -n -r | head -20
```
