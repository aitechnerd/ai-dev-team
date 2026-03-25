---
name: setup
description: >
  Full project onboarding in one command. Detects stack, asks about product/architecture,
  generates codemap. Creates stack.md, project-context.md, and codemap.md so Claude
  never re-discovers the same project twice. Run once per project, re-run after major changes.
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

# Setup — Full Project Onboarding

One command to onboard any project. Generates three context files that eliminate
codebase re-discovery in every future session:

| File | Purpose |
|------|---------|
| `.claude/stack.md` | Languages, frameworks, test/build/lint commands, scanners |
| `.claude/project-context.md` | Product vision, architecture, domain knowledge |
| `.claude/codemap.md` | Module map, key files, entry points, naming conventions |

Run once per project. Re-run after major architecture changes.

---

## Re-run Behavior

When `/setup` runs on a project that already has context files, it MUST still
regenerate them — **never skip a phase because the file already exists**.

| File | Re-run behavior |
|------|----------------|
| `stack.md` | Always overwrite — re-detect everything |
| `project-context.md` | Re-scan codebase, diff against existing, show user what drifted |
| `codemap.md` | Always overwrite — re-scan codebase |

The whole point of re-running `/setup` is to catch drift. If files exist, that
means the project was set up before — but things may have changed.

---

## Phase 1: Stack Detection

Detect languages, frameworks, and tools automatically.

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

Sub-detection for frameworks:
```bash
# Python ML
grep -lE "torch|tensorflow|sklearn|transformers|mlflow|wandb|keras" \
  requirements.txt pyproject.toml 2>/dev/null && echo "MLOPS=yes"

# React frameworks
grep -q "next" package.json 2>/dev/null && echo "NEXTJS=yes"
grep -q "vite" package.json 2>/dev/null && echo "VITE=yes"

# PHP frameworks
[ -f "artisan" ] && echo "LARAVEL=yes"
```

### Check scanners

Only check scanners for the detected stack:

```bash
# Universal
for tool in semgrep gitleaks trivy; do
    if [ -x ".venv/bin/$tool" ]; then echo "$tool=ok (.venv)"
    elif [ -x "venv/bin/$tool" ]; then echo "$tool=ok (venv)"
    elif command -v $tool >/dev/null 2>&1; then echo "$tool=ok (global)"
    else echo "$tool=missing"; fi
done
```

**Python:** check `bandit ruff pip-audit` (same pattern, check .venv first)
**Rust:** `cargo audit --version`, `cargo deny --version`
**Rails:** `brakeman`, `bundler-audit`, `rubocop`
**PHP:** `vendor/bin/phpstan`
**React/JS:** `npx eslint --version`
**Docker:** `hadolint`

### Generate `.claude/stack.md`

Always overwrite — this file is regenerated every time `/setup` runs.

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
- [list each installed scanner with location]
- [note missing ones as "❌ tool — not installed"]

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

---

## Phase 2: Project Context (Interactive)

### If `.claude/project-context.md` already exists:

Do a full re-discovery — don't ask the user to remember what changed.

1. Read the existing `project-context.md` and save it as the "old" baseline.
2. Re-scan the codebase for current state: check `package.json`, `requirements.txt`,
   `Cargo.toml`, config files, database schemas, Dockerfiles, CI configs, README, etc.
3. Compare what the codebase shows NOW vs what the old context says.
4. Show the user a **diff summary** — what's new, what's gone, what looks different:

> **Project context drift detected:**
> - **Added:** Docker setup (Dockerfile + docker-compose.yml not in previous context)
> - **Changed:** Database switched from SQLite to PostgreSQL (found in settings.py)
> - **Changed:** New dependencies: celery, redis (in requirements.txt)
> - **Removed:** References to Flask (now using FastAPI based on imports)
> - **Unchanged:** Product purpose, users, compliance, git workflow
>
> I'll update project-context.md with these changes. Anything else to add or correct?

5. Wait for user confirmation, then regenerate the file with updated info.
   Preserve any manually-written sections (domain knowledge, out of scope) unless
   the user says to change them.

### If no project-context.md exists (first run):

Ask the user these questions. Skip any that are already clear from the codebase.
Gather context before writing anything.

**Product:**
> 1. What does this product do in one sentence?
> 2. Who are the users? (internal team, customers, developers, patients, etc.)
> 3. Any compliance requirements? (HIPAA, SOC2, PCI-DSS, GDPR, none)

**Architecture:**
> 4. What's the deployment target? (Heroku, AWS, Azure, self-hosted, etc.)
> 5. Any architecture preferences? (monolith, microservices, service objects, etc.)
> 6. Database? (PostgreSQL, MySQL, SQLite, MongoDB, etc.)

**Conventions:**
> 7. Testing philosophy? (TDD, test-after, coverage targets, etc.)
> 8. Git workflow? (trunk-based, gitflow, PR-based, etc.)
> 9. Any code style rules beyond what linters enforce?

**Domain context:**
> 10. Anything domain-specific the AI team should always know?
>     (e.g., "PHI data requires encryption at rest", "all prices in cents",
>     "users are called 'patients' not 'customers'")

### Generate `.claude/project-context.md`

```markdown
# Project Context

## Product
- **Name:** [project name]
- **Purpose:** [one sentence]
- **Users:** [who uses this]
- **Domain:** [healthcare / fintech / e-commerce / dev tools / etc.]

## Compliance
- [HIPAA / SOC2 / PCI-DSS / GDPR / None]
- [Any specific requirements noted]

## Architecture
- **Stack:** [from stack detection]
- **Deployment:** [target]
- **Database:** [DB]
- **Pattern:** [monolith / microservices / etc.]
- **Key conventions:**
  - [e.g., "Use service objects, not fat controllers"]
  - [e.g., "Background jobs via Sidekiq"]

## Testing
- **Approach:** [TDD / test-after / etc.]
- **Coverage target:** [if any]
- **Framework:** [from stack detection]

## Git Workflow
- **Branching:** [trunk / gitflow / PR-based]
- **Commit style:** [conventional commits / freeform]

## Domain Knowledge
[Anything the AI team should always know about this domain]

## Out of Scope
[Things the AI team should not do or touch]
```

---

## Phase 3: Codebase Map

Scan the project structure and generate a persistent map.

### Scan directories

```bash
find . -maxdepth 2 -type d \
  ! -path './.git*' ! -path './node_modules*' ! -path './.venv*' \
  ! -path './venv*' ! -path './__pycache__*' ! -path './dist*' \
  ! -path './build*' ! -path './target*' ! -path './.ai-team*' \
  ! -path './.claude*' | sort

ls -la main.py app.py manage.py server.py index.ts index.js \
  src/main.rs src/lib.rs Cargo.toml 2>/dev/null
```

### Identify key modules

For each top-level source directory, identify:
- **Purpose** — what this module/package does (1 sentence)
- **Key files** — the 3-5 most important files
- **Entry point** — main function, route handler, or exported interface
- **Tests** — where tests live for this module

Stay fast: read at most 20-30 lines per file for class/function definitions.
Check README.md or __init__.py for module descriptions.

### Detect architecture patterns

Look for:
- **Config** — where settings, env vars, and secrets are configured
- **Database** — schema files, migrations directory, ORM models
- **API routes** — where endpoints are defined
- **Auth** — where authentication logic lives
- **Background jobs** — queues, workers, scheduled tasks
- **External services** — API clients, integrations

### Generate `.claude/codemap.md`

```markdown
# Codebase Map

Generated: {date}
Project: {name}

## Directory Overview

{2-level tree with 1-line descriptions per directory}

## Key Modules

### {module-name}
- **Purpose:** {what it does}
- **Key files:** {list}
- **Entry point:** {main file or function}
- **Tests:** {test directory or file pattern}

## Architecture Patterns

- **Config:** {where and how config is loaded}
- **Database:** {ORM, migration tool, schema location}
- **API:** {framework, route definition pattern, base path}
- **Auth:** {mechanism, where implemented}
- **Jobs:** {queue system, worker location}

## Common Operations

- **Run tests:** `{command}`
- **Start dev server:** `{command}`
- **Run migrations:** `{command}`
- **Lint/format:** `{command}`
- **Build:** `{command}`

## File Naming Conventions

- {e.g., "Controllers: src/controllers/{name}_controller.py"}
- {e.g., "Tests: tests/test_{module}.py"}
- {e.g., "Models: src/models/{name}.py"}
```

Keep under 200 lines. This is an index, not documentation.

---

## Phase 4: Setup Validation & Report

### Check setup items

```bash
echo "=== Setup Status ==="
[ -d "$HOME/.claude/agents" ] && echo "GLOBAL=ok" || echo "GLOBAL=missing"
[ -f ".claude/settings.json" ] && echo "SETTINGS=ok" || echo "SETTINGS=missing"
[ -f ".claude/ai-team.md" ] && echo "AI_TEAM_MD=ok" || echo "AI_TEAM_MD=missing"
[ -d ".ai-team" ] && echo "AI_TEAM_DIR=ok" || echo "AI_TEAM_DIR=missing"
grep -q "ai-team.md" CLAUDE.md 2>/dev/null && echo "CLAUDE_REF=ok" || echo "CLAUDE_REF=missing"
[ -f ".claude/stack.md" ] && echo "STACK=ok" || echo "STACK=missing"
[ -f ".claude/project-context.md" ] && echo "CONTEXT=ok" || echo "CONTEXT=missing"
[ -f ".claude/codemap.md" ] && echo "CODEMAP=ok" || echo "CODEMAP=missing"
command -v codex >/dev/null 2>&1 && echo "CODEX=ok" || echo "CODEX=missing"
```

### Codex Integration (optional)

If `CODEX=ok`, ask the user **and STOP to wait for their answer** before
continuing to the final report. Use AskUserQuestion or equivalent — do NOT
proceed until you have a yes or no:

> Codex CLI detected. Enable dual-agent mode for this project?
> Codex provides independent second opinions at key pipeline stages:
> - SOW review — helps PO catch gaps and ambiguities in requirements
> - Code review — parallel with code-reviewer, catches different issues
> - QA validation — parallel with qa-engineer, validates against ACs
> Adds ~2-3 min to builds but catches more issues. (y/n)

**WAIT for the user's response.** Do not print the final report until answered.

If yes, add to `.claude/project-context.md`:
```markdown
## External Agents
- **Codex:** enabled (SOW review, code review, QA)
```

Also generate an `AGENTS.md` file at the project root (if it doesn't exist) that gives
Codex the same project context Claude has:

```markdown
# Project Context for Codex

You are acting as an independent reviewer for this project.
Your reviews are consumed by Claude Code's AI Dev Team pipeline.

## Output Format
- Be concise — your output is parsed by another AI, not a human
- Use numbered lists for issues/suggestions
- Prefix severity: [critical], [major], [minor], [suggestion]
- Focus on gaps, edge cases, and things the primary agent might miss

## Project
{copy product section from project-context.md}

## Stack
{copy from stack.md}

## Conventions
{copy conventions from project-context.md}
```

If `CODEX=missing`, add to the final report:
```
ℹ Codex CLI — not installed (optional: brew install codex for dual-agent reviews)
```

### Auto-fix

- AI_TEAM_DIR=missing → `mkdir -p .ai-team`
- CLAUDE_REF=missing → prepend ai-team.md reference to CLAUDE.md

### Final report

Show ALL items with ✅ or ❌. Use 🔧 for auto-fixed items.

```
**Project: {name}**
**Stack:** {detected languages}

**Context Files:**
✅ stack.md — {N} languages detected
✅ project-context.md — product and architecture
✅ codemap.md — {N} modules mapped

**Setup:**
✅ Global install — agents in ~/.claude/
✅ settings.json — hooks configured
✅ ai-team.md — team reference
✅ .ai-team/ directory — feature docs
✅ CLAUDE.md — references ai-team.md

**Scanners:**
✅ semgrep, gitleaks, trivy (global)
❌ pip-audit — `pip install pip-audit`

**Ready!** `/scope [description]` to start working
```

### Scanner install commands

Group missing scanners into copy-pasteable commands:

**Universal:** `brew install semgrep gitleaks trivy`
**Python (venv):** `source .venv/bin/activate && pip install bandit ruff pip-audit`
**Python (global):** `pipx install bandit && pipx install ruff && pipx install pip-audit`
**Rust:** `cargo install cargo-audit cargo-deny`
**Rails:** `gem install brakeman bundler-audit rubocop`
**PHP:** `composer require --dev phpstan/phpstan`
**React/JS:** `npm install -D eslint eslint-plugin-security`
**Docker:** `brew install hadolint`

Scanners are optional — the team works without them, but DevSecOps and `/scan`
produce better results with them installed.

If scanners are missing, add this note after the install commands:

```
After installing, re-run `/setup` to verify they're detected and update stack.md.
```
