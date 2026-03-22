# AI Dev Team

> 9 specialized AI agents for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Planning, implementation, code review, security, QA, and refactoring — you focus on **what** to build, the team handles **how**.

Works alongside normal Claude Code. Use the full pipeline for big features, or just the standalone skills on code you wrote yourself.

## Install

### Step 1: Clone and install globally

```bash
git clone https://github.com/aitechnerd/ai-dev-team.git ~/.ai-team
bash ~/.ai-team/install.sh global
```

This copies agents, skills, stack profiles, and scripts to `~/.claude/` — available in every project.

### Step 2: Set up a project

```bash
cd ~/your-project
bash ~/.ai-team/install.sh project
```

Creates `.claude/settings.json`, `.claude/ai-team.md`, `CLAUDE.md`, `.ai-team/`, and configures `.gitignore`.

### Step 3: Run /setup in Claude Code

```
/setup
```

One command that does everything:
1. **Detects stack** — languages, frameworks, test/build/lint commands, scanners → `.claude/stack.md`
2. **Asks about your product** — vision, architecture, compliance, conventions → `.claude/project-context.md`
3. **Maps the codebase** — modules, key files, entry points, naming conventions → `.claude/codemap.md`
4. **Validates setup** — checks all config, auto-fixes what it can, reports status

After this, Claude never re-discovers your project — it reads the context files instead.

### Update

```bash
bash ~/.ai-team/install.sh update
```

Pulls latest from git and re-installs globally. All projects pick up new agents/skills automatically.

### Check status

```bash
bash ~/.ai-team/install.sh status
```

## Usage

### Full pipeline (features)

```bash
/scope Add patient search with fuzzy matching   # PO scopes → SE plans → PO approves
/build-phase all                                 # autonomous: build → review → QA → fix
/ship                                            # create draft PR
```

### Standalone skills (no pipeline needed)

```bash
/review            # code review on current branch
/qa-check          # QA validation on current changes
/sec-check         # security review
/health            # code health assessment
/retro             # weekly engineering retrospective
/qa-browser        # Playwright-based browser QA
```

### Auto-triggered skills (activate when relevant)

These load automatically based on what you're doing — no slash command needed:

| Skill | Triggers when... |
|-------|------------------|
| `systematic-debugging` | Bug, test failure, unexpected behavior |
| `test-driven-development` | Implementing a feature or fix |
| `git-mastery` | Git operations (commit, merge, rebase) |
| `python-pro` | Writing Python code |
| `rust-engineer` | Writing Rust code |
| `sql-pro` | Writing SQL, optimizing queries |
| `database-optimizer` | Investigating slow queries |
| `secure-code-guardian` | Implementing auth, input handling |
| `test-master` | Writing tests |
| `debugging-wizard` | Investigating errors |

## The Pipeline

```
/scope [description]
  │
  ├─ PO: discovery → scope → SOW
  ├─ SE: technical plan
  ├─ DevSecOps: plan review
  └─ PO: approve or reject
      │
/build-phase all
  │
  ├─ SE: implement each phase + auto-commit
  ├─ Scanners: semgrep, gitleaks, trivy, etc.
  ├─ Code Reviewer + DevSecOps (parallel)
  ├─ QA: validate → SE fixes if needed (2 rounds)
  ├─ Code Health: refactor + simplify
  └─ PO: completion summary
      │
/ship → draft PR
```

## Agents

| Agent | Model | Role |
|-------|-------|------|
| **product-owner** | Opus | Scope, SOW, plan approval, completion summaries |
| **software-engineer** | Opus | Technical plans, implementation, fixes |
| **code-reviewer** | Sonnet | Quality, correctness, over-engineering |
| **devsecops** | Sonnet | Security review, OWASP, compliance |
| **qa-engineer** | Sonnet | AC validation, edge cases, test gaps |
| **ux-designer** | Sonnet | Design review, accessibility |
| **code-health** | Sonnet | Refactoring, tech debt, dependencies |
| **mlops** | Sonnet | ML pipelines, model deployment (auto-detected) |
| **triage** | Haiku | Fast preprocessing — scan parsing, diff summaries |

Agents with `memory: project` (code-reviewer, qa-engineer, software-engineer, devsecops, code-health) learn your codebase patterns, working commands, and conventions across sessions.

## Commands

| Command | Description |
|---------|-------------|
| **Planning** | |
| `/scope [description]` | Smart entry point — auto-detects task size |
| `/approve-plan` | Manually approve a plan |
| `/features` | List all features and status |
| `/switch [name]` | Switch active feature |
| **Setup** | |
| `/setup` | Full onboarding: stack + context + codemap |
| `/fresh` | Reset feature state |
| **Building** | |
| `/build-phase [N\|all]` | Build phases. `all` = autonomous pipeline |
| `/validate` | Run validation pipeline |
| `/scan` | Run security scanners |
| **Review** | |
| `/review` | Code review on any branch |
| `/qa-check` | QA on current changes |
| `/sec-check` | Security review |
| `/design-review` | UX/accessibility review |
| **Shipping** | |
| `/ship` | Create draft PR |
| `/health` | Code health, refactoring, deps |
| `/revert [phase N\|feature\|last]` | Semantic undo |
| `/retro` | Engineering retrospective |
| `/qa-browser` | Playwright browser QA |

## Stack Support

All agents adapt to your project's language via stack profiles.

| Stack | Detected By | Scanners |
|-------|-------------|----------|
| Rust | `Cargo.toml` | cargo-audit, cargo-deny, clippy |
| Rails | `Gemfile` | Brakeman, bundler-audit, RuboCop |
| Python | `requirements.txt`, `pyproject.toml` | Bandit, pip-audit, ruff |
| React/TS | `package.json` | npm audit, ESLint |
| PHP | `composer.json` | PHPStan, Composer audit |
| MLOps | torch/tensorflow in deps | Python scanners + ML checks |

Plus: Semgrep (SAST), Gitleaks (secrets), Trivy (CVEs), Hadolint (Dockerfiles).

## Token Tracker

Built-in observability for every tool Claude uses. Installed automatically with `bash install.sh global`.

```bash
# Summary with per-tool breakdown
~/.claude/scripts/track-tokens.sh report

# Other reports
~/.claude/scripts/track-tokens.sh top         # biggest token burners
~/.claude/scripts/track-tokens.sh tools       # breakdown by tool type
~/.claude/scripts/track-tokens.sh categories  # by category (git, search, agent, etc.)
~/.claude/scripts/track-tokens.sh agents      # agent invocations by type
~/.claude/scripts/track-tokens.sh skills      # skill invocations
~/.claude/scripts/track-tokens.sh memory      # CLAUDE.md, memory, context reads
~/.claude/scripts/track-tokens.sh models      # usage by model
~/.claude/scripts/track-tokens.sh timeline    # daily usage
~/.claude/scripts/track-tokens.sh savings     # what filtering could save
```

Tracks all tools (Bash, Read, Write, Edit, Grep, Glob, Agent, Skill, WebFetch, LSP), categorizes CLAUDE.md reads vs code reads vs memory access, records which model and agent type processed each call.

Data: `~/.local/share/claude-token-tracker/tool-usage.jsonl`

## What Gets Installed Where

### Global (`~/.claude/`) — shared across all projects

```
~/.claude/
├── agents/       9 agent definitions
├── skills/       30 skills (with reference docs)
├── stacks/       6 language profiles
├── scripts/      pipeline hooks + scanner runner + token tracker
└── ai-team.md    team reference
```

### Per-project — created by `bash install.sh project`

```
your-project/
├── .claude/
│   ├── settings.json         hooks config
│   ├── ai-team.md            team reference
│   ├── stack.md              generated by /setup (gitignored)
│   ├── project-context.md    generated by /setup (gitignored)
│   └── codemap.md            generated by /setup (gitignored)
├── .ai-team/                 feature docs (gitignored)
├── .gitignore                auto-configured
└── CLAUDE.md                 your project conventions
```

### Agent memory — learned per-project

Agents with `memory: project` build up knowledge in `.claude/agent-memory/<agent>/`:
- Working commands (test, build, lint, deploy)
- Codebase patterns and conventions
- Common issues and fixes

This is gitignored — it's per-machine knowledge.

## Skill Evaluation & Self-Improvement

Skills improve over time through a built-in eval loop. Three tiers of evaluation, score tracking, and AI-powered improvement suggestions.

```bash
/eval browse              # Run all tiers on a skill
/eval --static            # Quick structural check on all skills (free, <5s)
/eval --improve browse    # Analyze failures + usage data → suggest edits
/eval --compare A B       # Blind A/B comparison of two skill versions
/eval --history browse    # Show score history over time
/eval --regression        # Check all skills against baseline scores
```

### Evaluation Tiers

| Tier | What | Cost |
|------|------|------|
| **Static** | Frontmatter, reference integrity, tool consistency, trigger quality | Free |
| **LLM Judge** | Scores clarity, completeness, actionability, efficiency, trigger precision (1-5 each) | Subscription |
| **E2E** | Spawns real Claude Code sessions via `claude -p`, runs test cases, verifies skills work | Subscription |

Composite score: `static × 0.2 + judge × 0.4 + e2e × 0.4` (0-100 scale).

### Self-Improvement Cycle

```
/eval browse              → Score: 72/100
/eval --improve browse    → 3 fixes identified from eval failures + usage signals
Apply fixes               → SKILL.md updated
/eval browse              → Score: 85/100 ✓
```

`--improve` analyzes eval results **and** real usage data (retry rates, manual edits after skill runs) to prioritize fixes that matter most. Test cases accumulate — each failure becomes a regression guard.

Results are saved to `.ai-team/evals/` with full history in `history.jsonl`.

## When to Use This vs Default Claude Code

| Situation | Use |
|-----------|-----|
| Quick fix, small change | Claude Code normally |
| Review code you wrote | `/review`, `/qa-check`, `/sec-check` |
| Bug fix | `/scope` → light pipeline (2-3 agent calls) |
| Small feature | `/scope` → medium pipeline (3-4 calls) |
| Large feature | `/scope` → full pipeline (6-8 calls) |

When no feature is active, the hooks do nothing — Claude Code works exactly as normal.

## License

MIT
