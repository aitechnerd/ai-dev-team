# Changelog

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
