# Changelog

## [0.2.0] — 2026-03-25

Major release: migrated from custom commands to Claude Code skills, added Codex dual-agent
support, built a full eval framework, and added token optimization across the pipeline.

### Skills Migration (commands → skills)
- **Migrated all 18 commands to skills** — skills are the standard Claude Code extension point, replacing `.claude/commands/` with `skills/` directory
- **33 skills total** — 18 migrated + 15 new (see below)
- **External skill integration** — skills can reference external packages and resources

### New Skills (15)
- **eval** — evaluate and improve skills with 3 tiers: static validation, LLM-judge scoring, E2E testing via `claude -p`; tracks results over time, detects regressions
- **browse** — general-purpose Playwright CLI browser automation (navigation, interaction, screenshots, network mocking)
- **qa-browser** — systematic QA testing of web apps with diff-aware, full, quick, and regression modes; uses accessibility tree snapshots for 4x token efficiency
- **webapp-testing** — toolkit for testing local web applications with Playwright CLI
- **rust-engineer** — idiomatic Rust: ownership, lifetimes, traits, async/tokio, FFI
- **python-pro** — type-safe Python 3.11+: mypy strict, pytest, async patterns
- **sql-pro** — query optimization, schema design, EXPLAIN/ANALYZE, dialect migration
- **database-optimizer** — index design, query rewrites, partitioning, lock contention
- **secure-code-guardian** — OWASP Top 10 prevention, auth, input validation, encryption
- **git-mastery** — advanced git workflows, conflict resolution, worktrees, bisect
- **systematic-debugging** — strict 4-phase root-cause-first methodology: investigate before fixing
- **debugging-wizard** — error parsing, stack trace analysis, log correlation
- **test-driven-development** — red-green-refactor with iron law enforcement
- **test-master** — test generation, mocking strategies, coverage analysis, test architecture
- **hipaa** — HIPAA compliance review (PHI exposure, encryption, audit logging); per-project activation via `.hipaa` marker file

### Codex Integration
- **Dual-agent mode** — optional Codex CLI integration at 3 pipeline stages: SOW review, code review, QA validation
- **`/setup` opt-in** — Codex detected automatically, user prompted to enable per-project
- **AGENTS.md generation** — project context file for Codex with output format guidelines
- **Parallel execution** — Codex runs alongside existing agents, findings merged into fix list

### Agent Updates
- **Model tiering** — Opus for planning/implementation (SE, PO), Sonnet for reviews (code-reviewer, devsecops, qa-engineer, ux-designer, code-health, mlops), Haiku for triage
- **SE upgraded to Opus** — was Sonnet in 0.1.0, now Opus for complex implementation work
- **Agent colors** — each agent type has a distinct color for visual identification
- **Context forking** — agents read shared-context.md and append findings for downstream agents
- **Memory namespaces** — each agent stores learned commands/patterns under its own prefix (e.g., `se/`, `po/`)

### Token Optimization
- **SE large file strategy** — splits files >300 lines before heavy editing, avoiding repeated full-file returns from Edit tool
- **Read dedup hook** — PreToolUse hook blocks redundant Read calls with two layers:
  - Session-based: blocks re-reads within same session if file hasn't been edited
  - Time-based cache: blocks re-reads across agent boundaries (30-min TTL for stable files, 10-min TTL for pipeline files like SOW/plans)
  - Mtime invalidation: automatically allows re-reads if file was modified on disk
- **Output compression hook** — PreToolUse hook compresses verbose Bash output (build logs, test output, git diffs)
- **Token tracker** — PostToolUse hook logging every tool call with token estimates, categorization, model, agent type; 12 report commands (`report`, `tools`, `categories`, `agents`, `models`, `timeline`, `big`, `savings`, `codemap`, `compression`, `skills`, `memory`)
- **Token tracker model fix** — agent calls now resolve actual model from agent definition frontmatter instead of inheriting parent's model

### Eval Framework
- **Static validation** — free structural checks on all skills (frontmatter, sections, tool refs)
- **LLM-judge scoring** — quality assessment using Claude subscription (no API key needed)
- **E2E testing** — full pipeline testing via `claude -p`
- **Score tracking** — results stored over time, regression detection
- **`/eval --compare`** — blind A/B comparison of two skill versions
- **`/eval --improve`** — analyzes failures and suggests edits

### Setup Improvements
- **Unified `/setup`** — single command replaces separate `/detect` + manual setup
- **`/setup` re-run behavior** — always regenerates `stack.md` and `codemap.md` on re-run, never skips phases
- **Project context drift detection** — on re-run, scans codebase and diffs against existing `project-context.md`, showing what changed
- **Context files** — `stack.md`, `project-context.md`, `codemap.md` loaded by all agents to avoid redundant codebase exploration

### Pipeline Improvements
- **Scope modes** — PO adapts discovery based on feature size (quick for small, thorough for large)
- **Fix-first code review** — code-reviewer auto-fixes mechanical issues, only escalates judgment calls
- **Per-phase validation** — tests + lint after each phase, up to 2 fix attempts before escalation
- **Crash recovery** — checkbox progress tracking in technical-plan.md; interrupted `/build-phase all` resumes from first unchecked phase
- **Codemap refresh** — `/build-phase` auto-regenerates codemap.md after building to reflect new files

### Hooks
- **Session cleanup** — cron-friendly script to clean stale session files
- **Skill observer** — tracks which skills are invoked and how often
- **Subagent orchestrator** — auto-chains pipeline stages (SE → DevSecOps → PO review)

## [0.1.0] — 2026-03-04

Initial public release.

### Agents (9)
- **product-owner** (Opus) — scope discovery, SOW writing, plan approval, feature summaries
- **software-engineer** (Sonnet) — planning and implementation across all stacks
- **code-reviewer** (Sonnet) — quality, correctness, over-engineering/YAGNI detection
- **devsecops** (Sonnet) — plan security review, OWASP scanning, compliance checks
- **qa-engineer** (Sonnet) — acceptance criteria validation, edge cases, test gaps
- **ux-designer** (Sonnet) — design review, accessibility, UX heuristics
- **code-health** (Sonnet) — post-feature refactoring, tech debt, dependency updates
- **mlops** (Sonnet) — ML pipeline review, model deployment (optional, auto-detected)
- **triage** (Haiku) — fast preprocessing: research, scan parsing, diff summaries

### Commands (18)
- **Planning:** `/scope`, `/approve-plan`, `/features`, `/switch`
- **Setup:** `/detect`, `/setup`, `/fresh`
- **Building:** `/build-phase`, `/validate`, `/scan`
- **Review:** `/review`, `/qa-check`, `/sec-check`, `/design-review`
- **Shipping:** `/ship`, `/health`, `/revert`
- **Info:** `/team`

### Stack Profiles (6)
- Rust, Rails, Python, React, PHP/Laravel, MLOps
- Auto-detected by `/detect`, stored in `.claude/stack.md`

### Pipeline Features
- Per-phase validation with auto-commit and checkbox progress tracking
- Crash recovery: interrupted builds resume from first unchecked phase
- Parallel code review + DevSecOps
- Two-pass code review (comprehensive → focused critical-only)
- Haiku triage layer for token optimization
- Plan approval gate (blocks implementation until plan is approved)

### Hooks
- **Fail-open design**: hooks do nothing when no feature is active
- Normal Claude Code (`/simplify`, `/batch`, etc.) works unimpeded
- Subagent orchestrator only chains for team agents

### Distribution
- Homebrew tap: `brew tap aitechnerd/ai-dev-team`
- Git clone with `install.sh`
- `release.sh` for automated releases
