# Git Hooks & Automation

## Common Git Hooks

| Hook | When | Use Case |
|------|------|----------|
| `pre-commit` | Before commit is created | Lint, format, run fast tests |
| `commit-msg` | After message is written | Validate commit message format |
| `pre-push` | Before push to remote | Run full test suite |
| `post-merge` | After merge completes | Install dependencies, run migrations |
| `post-checkout` | After branch checkout | Install dependencies if lockfile changed |

## Pre-commit Framework

Install and configure [pre-commit](https://pre-commit.com/):

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
        args: ['--maxkb=500']
      - id: detect-private-key
      - id: check-merge-conflict

  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

```bash
pre-commit install           # Set up hooks
pre-commit run --all-files   # Run manually
```

## Commit Message Validation

```bash
#!/bin/sh
# .git/hooks/commit-msg

commit_msg=$(cat "$1")
pattern='^(feat|fix|refactor|test|docs|chore|perf|ci|style)(\(.+\))?: .{1,72}'

if ! echo "$commit_msg" | head -1 | grep -qE "$pattern"; then
  echo "Invalid commit message format."
  echo "Expected: <type>: <description>"
  echo "Types: feat, fix, refactor, test, docs, chore, perf, ci, style"
  exit 1
fi
```

## Secrets Prevention

```bash
# Install git-secrets
brew install git-secrets   # macOS
git secrets --install      # Per-repo
git secrets --register-aws # Block AWS keys

# Or use gitleaks
brew install gitleaks
gitleaks detect            # Scan repo
gitleaks protect --staged  # Pre-commit check
```

## Commit Signing

```bash
# Set up GPG signing
git config --global commit.gpgsign true
git config --global user.signingkey <GPG_KEY_ID>

# Or use SSH signing (simpler)
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519
git config --global commit.gpgsign true
```

## GitHub CLI Integration

```bash
# Create PR
gh pr create --title "feat: add auth" --body "Description"

# Review PRs
gh pr list
gh pr diff 123
gh pr review 123 --approve

# Issues
gh issue create --title "Bug: login fails" --label bug
gh issue list --label "priority:high"

# Actions
gh run list
gh run view <run-id>
gh run watch <run-id>

# Releases
gh release create v1.2.0 --generate-notes
```

## CI/CD Git Patterns

```yaml
# GitHub Actions: only run on relevant changes
on:
  push:
    paths:
      - 'src/**'
      - 'tests/**'
      - 'package.json'

# Skip CI for docs-only changes
# Add [skip ci] to commit message

# Cache based on lockfile
- uses: actions/cache@v4
  with:
    path: node_modules
    key: ${{ hashFiles('package-lock.json') }}
```

## Useful Git Aliases

```bash
git config --global alias.lg "log --oneline --graph --decorate -20"
git config --global alias.st "status -sb"
git config --global alias.co "checkout"
git config --global alias.unstage "reset HEAD --"
git config --global alias.last "log -1 HEAD --stat"
git config --global alias.branches "branch -vv --sort=-committerdate"
git config --global alias.whoami "config user.email"
```
