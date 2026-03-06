# AI Dev Team

> An AI-powered development team for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). 9 specialized sub-agents handle planning, implementation, code review, security, QA, and refactoring — you focus on **what** to build, the team handles **how**.

Works alongside normal Claude Code. Use the full pipeline for big features, or just run `/review` or `/qa-check` on code you wrote yourself.

## Quick Start

```bash
# Install
brew tap aitechnerd/ai-dev-team
brew install ai-dev-team
ai-team install

# Set up a project
cd ~/your-project
ai-team project

# In Claude Code
/detect                                          # detect stack, generate config
/scope why are lab results missing               # auto-detects: investigation
/scope Fix the timeout on slow connections           # auto-detects: bugfix
/scope Add patient search with fuzzy matching        # auto-detects: feature → full pipeline
/build-phase all                                 # build it autonomously
/ship                                            # create a draft PR
```

## The Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│  /scope                              SMART TASK ROUTER      │
│                                                             │
│  Investigation? → work directly, no subagents (0 calls)     │
│  Bug fix? → PO(Sonnet) + SE(Opus), auto-approve (2-3 calls)│
│  Small feature? → PO(Sonnet) + SE(Opus) + DevSecOps?       │
│                    auto-approve (3-4 calls)                 │
│  Large feature? ↓ full pipeline (6-8 calls)                 │
│                                                             │
│  Triage (Haiku) → PO (Opus) → SE+UX feasibility (Sonnet)   │
│  → SE plan (Opus) → DevSecOps → PO approval (Sonnet)       │
├─────────────────────────────────────────────────────────────┤
│  /build-phase all                          AUTONOMOUS       │
│                                                             │
│  SE implements each phase + auto-commit + checkpoint        │
│  Scanners → Triage parses results                           │
│  Code Reviewer + DevSecOps (parallel)                       │
│  QA validates → SE fixes if needed (2 rounds)               │
│  Second-pass review (critical/high only)                    │
│  Code Health refactors + simplifies                         │
├─────────────────────────────────────────────────────────────┤
│  /ship                                     YOU DECIDE       │
│                                                             │
│  Generates PR description → creates draft PR                │
└─────────────────────────────────────────────────────────────┘
```

## Agents

| Agent | Model | Role |
|-------|-------|------|
| **product-owner** | Opus | Scope discovery, SOW, plan approval, feature summaries |
| **software-engineer** | Opus | Technical plans, implementation across all stacks |
| **code-reviewer** | Sonnet | Quality, correctness, over-engineering detection |
| **devsecops** | Sonnet | Security review, OWASP scanning, compliance |
| **qa-engineer** | Sonnet | Acceptance criteria validation, edge cases, test gaps |
| **ux-designer** | Sonnet | Design review, accessibility, UX heuristics |
| **code-health** | Sonnet | Post-feature refactoring, tech debt, dependency updates |
| **mlops** | Sonnet | ML pipeline review, model deployment (optional, auto-detected) |
| **triage** | Haiku | Fast preprocessing — research, scan parsing, diff summaries |

## Commands

### Planning (use /scope to start)

| Command | Description |
|---------|-------------|
| `/scope [description]` | Smart entry point: auto-detects investigation vs bugfix vs feature |
| `/approve-plan` | Manually approve a plan (skip PO review) |
| `/features` | List all features and their status |
| `/switch [name]` | Switch active feature |

### Setup (once per project)

| Command | Description |
|---------|-------------|
| `/detect` | Detect project stack, generate `.claude/stack.md` |
| `/setup` | Create persistent project context (vision, conventions, compliance) |
| `/fresh` | Reset feature state, deactivate plan gate |

### Building (after /scope)

| Command | Description |
|---------|-------------|
| `/build-phase [N\|all]` | Build phases. `all` = full autonomous pipeline |
| `/validate` | Run validation pipeline on current feature |
| `/scan` | Run security scanners |

### Review (standalone — no /scope needed)

| Command | Description |
|---------|-------------|
| `/review` | Full code review + security on any branch |
| `/qa-check` | QA validation on current changes |
| `/sec-check` | Security review on current changes |
| `/design-review` | UX/accessibility review |

### Shipping

| Command | Description |
|---------|-------------|
| `/ship` | Generate PR description, create draft PR |
| `/health` | Code health check, refactoring, dependency updates |
| `/revert [phase N\|feature\|last]` | Semantic undo by logical unit |

### Info

| Command | Description |
|---------|-------------|
| `/team` | Show all agents, commands, and workflows |

## When to Use This vs Default Claude Code

| Situation | Approach |
|-----------|----------|
| Bug fix, small change | Just use Claude Code normally |
| Investigation, data audit | `/scope` → auto-detects, works directly (0 agent calls) |
| Quick review of your code | `/review`, `/qa-check`, or `/sec-check` |
| Bug fix (known broken behavior) | `/scope` → light pipeline (2-3 agent calls) |
| Small feature (1-3 files) | `/scope` → light pipeline (3-4 agent calls) |
| Large feature (new subsystem) | `/scope` → full pipeline (6-8 agent calls) |

The hooks are designed to stay out of your way. When no feature is active (`.ai-team/.active` doesn't exist), both hooks do nothing — Claude Code works exactly as normal.

## Stack Support

All agents adapt to your project's language. Stack profiles provide testing commands, security checks, architecture patterns, and code review focus areas.

| Stack | Detected By | Scanners |
|-------|-------------|----------|
| **Rust** | `Cargo.toml` | cargo-audit, cargo-deny, cargo-clippy, cargo-geiger |
| **Ruby on Rails** | `Gemfile` | Brakeman, bundler-audit, RuboCop |
| **Python** | `requirements.txt`, `pyproject.toml` | Bandit, pip-audit, ruff/mypy |
| **React / TypeScript** | `package.json` | npm audit, ESLint |
| **PHP / Laravel** | `composer.json` | PHPStan, Composer audit, PHP-CS-Fixer |
| **MLOps** | torch/tensorflow in deps | All Python scanners + ML-specific checks |

Plus language-agnostic: **Semgrep** (SAST), **Gitleaks** (secrets), **Trivy** (CVEs), **Hadolint** (Dockerfiles).

## Installation

### Option A: Homebrew (recommended)

```bash
brew tap aitechnerd/ai-dev-team
brew install ai-dev-team
ai-team install
```

### Option B: Git Clone

```bash
git clone https://github.com/aitechnerd/ai-dev-team.git ~/.ai-team
cd ~/.ai-team
bash install.sh global
```

### Set Up a Project

```bash
cd ~/your-project
ai-team project
```

Then in Claude Code:
```
/detect          # Detect stack, generate .claude/stack.md
/setup           # (Optional) Create project context for all agents
```

### Update

```bash
ai-team update                  # Homebrew
# or
cd ~/.ai-team && bash install.sh update   # Git clone
```

### Install Scanners (optional)

Run `/detect` in Claude Code — it checks what's missing and gives you
the exact `pip install` / `brew install` commands to copy-paste.

## What Gets Installed Where

### Global (`~/.claude/`) — shared across all projects

```
~/.claude/
├── agents/       # 9 agent definitions
├── commands/     # 18 slash commands
├── stacks/       # 6 language profiles
└── scripts/      # Scanner runner, hooks, helpers
```

### Per-Project — created by `ai-team project`

```
your-project/
├── .claude/
│   ├── settings.json       # Hook config (auto-updated by installer)
│   ├── ai-team.md          # Team system reference (auto-updated by installer)
│   ├── stack.md            # Generated by /detect
│   └── project-context.md  # Generated by /setup (optional)
├── .ai-team/               # Feature docs — auto-gitignored
│   ├── .active             # Current feature name
│   └── patient-search/     # Feature artifacts (SOW, plan, reviews)
├── .gitignore              # .ai-team/ added automatically
└── CLAUDE.md               # YOUR project conventions (never overwritten)
```

## Token Cost Model

The system right-sizes the pipeline based on task complexity:

| Task Type | Opus Calls | Sonnet Calls | Haiku Calls |
|-----------|-----------|-------------|-------------|
| Investigation | 0 | 0 | 0 |
| Bug fix | 1 (SE plan) | 1 (PO scope) | 0 |
| Small feature | 1 (SE plan) | 1-2 (PO + DevSecOps?) | 0 |
| Large feature | 2 (PO + SE plan) | 3-4 (feasibility + reviews + approval) | 2 (triage) |

Additional savings:
- **Haiku triage** — cheap preprocessing before expensive models
- **Conditional skipping** — UX only for UI features, DevSecOps only for security-relevant changes, MLOps only for ML projects
- **Sonnet for structured work** — PO scoping for bugs/small features, feasibility checks, plan approval
- **Opus only for deep work** — PO discovery on large features, SE architecture planning

## Project Structure

```
ai-dev-team/
├── .claude/
│   ├── agents/           # 9 agent definitions
│   ├── commands/         # 18 slash commands
│   ├── stacks/           # 6 language profiles (rust, rails, python, react, php, mlops)
│   ├── scripts/          # Hook scripts + scanner runner
│   └── settings.json     # Hook config template
├── CLAUDE.md             # Project conventions template
├── install.sh            # Installer (global/project/update/status)
├── release.sh            # Automated release script
├── VERSION
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## License

MIT
