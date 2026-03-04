---
description: >
  Detect project languages/frameworks and generate stack config.
  Run this once when setting up the team system in a new project.
  Use: /detect
---

# Init — Detect Project Stack

## Step 1: Detect Languages & Frameworks

Check the project root for these markers:

```bash
echo "=== Stack Detection ==="
[ -f "Cargo.toml" ]           && echo "RUST=yes"
[ -f "Gemfile" ]              && echo "RAILS=yes"
[ -f "package.json" ]         && echo "REACT=yes"
[ -f "requirements.txt" ]     && echo "PYTHON=yes"
[ -f "pyproject.toml" ]       && echo "PYTHON=yes"
[ -f "Pipfile" ]              && echo "PYTHON=yes"
[ -f "composer.json" ]        && echo "PHP=yes"
[ -f "go.mod" ]               && echo "GO=yes"
[ -f "Dockerfile" ]           && echo "DOCKER=yes"
[ -f "docker-compose.yml" ]   && echo "DOCKER=yes"
[ -f "terraform" ] || [ -d ".terraform" ] && echo "TERRAFORM=yes"
```

For Python, also check for ML dependencies:
```bash
grep -lE "torch|tensorflow|sklearn|transformers|mlflow|wandb|keras" \
  requirements.txt pyproject.toml 2>/dev/null && echo "MLOPS=yes"
```

For React, detect the framework:
```bash
grep -q "next" package.json 2>/dev/null && echo "NEXTJS=yes"
grep -q "vite" package.json 2>/dev/null && echo "VITE=yes"
grep -q "react-scripts" package.json 2>/dev/null && echo "CRA=yes"
```

For PHP, detect the framework:
```bash
[ -f "artisan" ]                && echo "LARAVEL=yes"
[ -f "bin/console" ]            && echo "SYMFONY=yes"
[ -f "wp-config.php" ]          && echo "WORDPRESS=yes"
```

## Step 2: Generate Stack Config

Create `.claude/stack.md` with detected results:

```markdown
# Project Stack

## Detected Languages
- [list each detected language/framework]

## Active Stack Profiles
- [list which .claude/stacks/*.md files apply]

## Test Commands
- [language]: `[command]`

## Lint Commands
- [language]: `[command]`

## Build Commands
- [language]: `[command]`

## Agents Enabled
- product-owner (Opus)
- software-engineer (Opus)
- triage (Haiku)
- code-reviewer (Sonnet)
- devsecops (Sonnet)
- qa-engineer (Sonnet)
- ux-designer (Sonnet) — only if React/frontend detected
- mlops (Sonnet) — only if ML dependencies detected
```

## Step 3: Present to User

> "Detected stack for this project:
> [list languages with versions if detectable]
>
> Stack profiles loaded: [list]
> Optional agents: [ux-designer: enabled/disabled, mlops: enabled/disabled]
>
> Config saved to `.claude/stack.md`
> Run `/scan` to verify your security tools are installed."

## Step 4: Check Scanner Tools

Run a quick check:
```bash
bash ~/.claude/scripts/run-scanners.sh docs/scans
cat docs/scans/scan-summary.md
```

If scanners are missing for detected languages, suggest:
> "Missing scanners for your stack. Run:
> `bash install-scanners.sh [detected_language]`"
