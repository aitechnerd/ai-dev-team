---
name: git-mastery
description: >
  Git workflows, commit conventions, branching strategies, and safe operations.
  Use when working with git: committing, branching, merging, rebasing, resolving
  conflicts, writing commit messages, managing worktrees, or reviewing history.
  Invoke for git, commit, branch, merge, rebase, conflict, worktree, cherry-pick,
  bisect, stash, reset, reflog, tag.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# Git Mastery

## Core Principles

1. **Measure twice, cut once.** Before any destructive operation (reset --hard, push --force, branch -D), verify what will be affected.
2. **Atomic commits.** Each commit should represent one logical change that compiles and passes tests.
3. **Never rewrite shared history.** Do not force-push to main/master or any branch others may have pulled.
4. **Commit messages explain why, not what.** The diff shows what changed; the message explains the motivation.

## Commit Messages

Use conventional format:

```
<type>: <concise description>

<optional body explaining why, not what>
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `ci`, `style`

Good examples:
```
feat: add retry logic for failed API calls

Upstream service returns 503 during deployments. Exponential backoff
with 3 retries prevents cascading failures in the order pipeline.
```

```
fix: prevent duplicate webhook deliveries

Race condition in the queue consumer allowed two workers to process
the same event. Added advisory lock on event_id.
```

Bad examples:
```
# Too vague
fix: fix bug

# Describes what, not why
refactor: rename variable from x to user_count

# Too long for subject line
feat: add new endpoint for user management that handles creation, update, deletion and also validates input
```

## Branching Strategy

```
main (or master)
 ├── feature/auth-login      ← feature work
 ├── fix/duplicate-webhook   ← bug fixes
 └── chore/upgrade-deps      ← maintenance
```

**Branch naming:** `<type>/<short-description>` using kebab-case.

## Safe Operations Checklist

### Before destructive operations
```bash
# Check what you're about to affect
git status                    # Working tree state
git stash list                # Any stashed work
git log --oneline -5          # Recent commits
git branch -vv                # Branch tracking info
```

### Resolving merge conflicts
1. Read both sides of the conflict fully before editing
2. Understand the intent of each change, not just the code
3. Run tests after resolving every file
4. Do not delete the "other side" unless you understand why it's wrong

### Undoing mistakes
```bash
# Undo last commit (keep changes staged)
git reset --soft HEAD~1

# Undo last commit (keep changes unstaged)
git reset HEAD~1

# Find lost commits
git reflog

# Recover deleted branch
git reflog | grep <branch-name>
git checkout -b <branch-name> <commit-sha>
```

### Interactive rebase (squashing before PR)
```bash
# Squash last N commits interactively
git rebase -i HEAD~N

# Rebase onto updated main
git fetch origin main
git rebase origin/main
```

## Worktrees

Use worktrees for parallel work without switching branches:

```bash
# Create isolated workspace
git worktree add .worktrees/feature-name -b feature/name

# List active worktrees
git worktree list

# Remove when done
git worktree remove .worktrees/feature-name
```

Keep `.worktrees/` in `.gitignore`. Verify with `git check-ignore .worktrees/`.

## Anti-Patterns

- **Giant commits** — If `git diff --stat` shows 20+ files, break it up
- **"WIP" commits on shared branches** — Use stash or local-only branches
- **Commit generated files** — Add build artifacts, node_modules, .env to .gitignore
- **Force-push as first resort** — Almost always a safer alternative exists
- **Ignoring .gitignore** — Set it up before the first commit, not after
- **Committing secrets** — Even if removed later, they remain in history. Use `git-secrets` or `gitleaks` to prevent this
