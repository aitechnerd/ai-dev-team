---
description: >
  Detect project stack and walk through setup. Run once per project.
  Detects languages, generates stack.md, checks what's installed,
  and shows exact commands for anything missing.
  Use: /detect
---

# Detect — Project Stack Setup

## Step 1: Detect Languages & Frameworks

Check the project root:

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
```

For Python, check for ML dependencies:
```bash
grep -lE "torch|tensorflow|sklearn|transformers|mlflow|wandb|keras" \
  requirements.txt pyproject.toml 2>/dev/null && echo "MLOPS=yes"
```

For React, detect framework:
```bash
grep -q "next" package.json 2>/dev/null && echo "NEXTJS=yes"
grep -q "vite" package.json 2>/dev/null && echo "VITE=yes"
```

For PHP, detect framework:
```bash
[ -f "artisan" ] && echo "LARAVEL=yes"
```

## Step 2: Generate Stack Config

Create `.claude/stack.md` with detected results.
**Always overwrite** — this file is regenerated every time `/detect` runs.

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

## Scanners Available
- [list each installed scanner, e.g. "semgrep (global)" or "bandit (.venv)"]
- [note any missing ones as "❌ bandit — not installed"]

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

## Step 3: Check & Fix Setup

Run ALL of these checks. Report EVERY item. Fix what you can.

```bash
echo "=== Setup Status ==="

# 1. Global install
[ -d "$HOME/.claude/agents" ] && echo "GLOBAL=ok" || echo "GLOBAL=missing"

# 2. settings.json (hooks)
[ -f ".claude/settings.json" ] && echo "SETTINGS=ok" || echo "SETTINGS=missing"

# 3. ai-team.md (team reference)
[ -f ".claude/ai-team.md" ] && echo "AI_TEAM_MD=ok" || echo "AI_TEAM_MD=missing"

# 4. .ai-team/ directory
[ -d ".ai-team" ] && echo "AI_TEAM_DIR=ok" || echo "AI_TEAM_DIR=missing"

# 5. CLAUDE.md references ai-team.md
grep -q "ai-team.md" CLAUDE.md 2>/dev/null && echo "CLAUDE_REF=ok" || echo "CLAUDE_REF=missing"

# 6. Project context
[ -f ".claude/project-context.md" ] && echo "CONTEXT=ok" || echo "CONTEXT=missing"
```

**Auto-fix any missing items:**

- SETTINGS=missing → "Run `bash /path/to/install.sh project`"
- AI_TEAM_MD=missing → "Run `bash /path/to/install.sh project`"
- AI_TEAM_DIR=missing → Create it: `mkdir -p .ai-team`
- CLAUDE_REF=missing → Prepend to CLAUDE.md:
  `Read .claude/ai-team.md for the AI Dev Team system reference.`
  (If no CLAUDE.md exists, create it with that line.)
- CONTEXT=missing → "Run `/setup` to create project context"

**IMPORTANT: Show ALL 6 items in the report, even if they are ok.**
Do NOT skip or summarize items that pass. The user wants to see the full checklist.

## Step 4: Check Scanners

Only check scanners relevant to the detected stack. Run:

```bash
# Universal — check .venv first, then global PATH
for tool in semgrep gitleaks trivy; do
    if [ -x ".venv/bin/$tool" ]; then
        echo "$tool=ok (.venv)"
    elif [ -x "venv/bin/$tool" ]; then
        echo "$tool=ok (venv)"
    elif command -v $tool >/dev/null 2>&1; then
        echo "$tool=ok (global)"
    else
        echo "$tool=missing"
    fi
done
```

Then only check the scanners for detected languages:

**Python:**
```bash
# Check .venv first (most common), then venv, then PATH
for tool in bandit ruff pip-audit; do
    if [ -x ".venv/bin/$tool" ]; then
        echo "$tool=ok (.venv)"
    elif [ -x "venv/bin/$tool" ]; then
        echo "$tool=ok (venv)"
    elif command -v $tool >/dev/null 2>&1; then
        echo "$tool=ok (global)"
    else
        echo "$tool=missing"
    fi
done
```

**Rust:**
```bash
cargo audit --version >/dev/null 2>&1 && echo "cargo-audit=ok" || echo "cargo-audit=missing"
cargo deny --version >/dev/null 2>&1 && echo "cargo-deny=ok" || echo "cargo-deny=missing"
```

**Rails:**
```bash
command -v brakeman >/dev/null 2>&1 && echo "brakeman=ok" || echo "brakeman=missing"
command -v bundler-audit >/dev/null 2>&1 && echo "bundler-audit=ok" || echo "bundler-audit=missing"
command -v rubocop >/dev/null 2>&1 && echo "rubocop=ok" || echo "rubocop=missing"
```

**PHP:**
```bash
test -f vendor/bin/phpstan && echo "phpstan=ok" || echo "phpstan=missing"
```

**React/JS:**
```bash
# npm audit is built-in, no install needed
npx eslint --version >/dev/null 2>&1 && echo "eslint=ok" || echo "eslint=missing"
```

**Docker:**
```bash
command -v hadolint >/dev/null 2>&1 && echo "hadolint=ok" || echo "hadolint=missing"
```

## Step 5: Auto-Fix & Report

**Auto-fix what you can:**

If CLAUDE_REF is missing (CLAUDE.md exists but doesn't reference ai-team.md):
- Prepend `Read .claude/ai-team.md for the AI Dev Team system reference.` to the top of CLAUDE.md
- Report as fixed

If AI_TEAM_DIR is missing:
- Create `.ai-team/` directory
- Report as fixed

Then present the status report showing ALL 6 setup items, even if they pass:

> "**Project: [name]**
> **Stack:** [detected languages]
>
> **Setup:**
> ✅ Global install — agents and commands in ~/.claude/
> ✅ settings.json — hooks configured
> ✅ ai-team.md — team system reference
> ✅ .ai-team/ directory — feature docs
> ✅ CLAUDE.md — references ai-team.md
> ❌ Project context — run `/setup` to create
>
> **Scanners:**
> ✅ semgrep, gitleaks, trivy (global)
> ✅ bandit, ruff (.venv)
> ❌ pip-audit — `pip install pip-audit` (in your venv)
>
> **Ready?** `/scope [description]` to start working"

Show ✅ or ❌ for EVERY line — never skip items that pass.
If you auto-fixed something, show it as: 🔧 CLAUDE.md — added ai-team.md reference (fixed)

Use these install commands for each scanner:

**Universal:**
- semgrep: `brew install semgrep` or `pipx install semgrep`
- gitleaks: `brew install gitleaks`
- trivy: `brew install trivy`

**Python:**
- bandit, ruff, pip-audit
- If project has a venv: `source .venv/bin/activate && pip install bandit ruff pip-audit`
- No venv / want global access: `pipx install bandit && pipx install ruff && pipx install pip-audit`
  (Install pipx first if needed: `brew install pipx && pipx ensurepath`)

**Rust:**
- cargo-audit: `cargo install cargo-audit`
- cargo-deny: `cargo install cargo-deny`
- clippy: `rustup component add clippy`

**Rails:**
- brakeman: `gem install brakeman`
- bundler-audit: `gem install bundler-audit`
- rubocop: `gem install rubocop`

**PHP:**
- phpstan: `composer require --dev phpstan/phpstan`
- pint (Laravel): `composer require --dev laravel/pint`

**React/JS:**
- eslint: `npm install -D eslint eslint-plugin-security`
- npm audit: built-in, no install needed

**Docker:**
- hadolint: `brew install hadolint`

Group the missing ones into a single copy-pasteable command when possible, e.g.:
`pipx install bandit && pipx install ruff && pipx install pip-audit`
or for brew tools: `brew install trivy gitleaks`

If the user doesn't have pipx: `brew install pipx && pipx ensurepath`

Scanners are optional — the team works without them, but DevSecOps and `/scan`
will be more effective with them installed.

After installing, tell the user:
> "After installing, run `/detect` again to update your stack config."
