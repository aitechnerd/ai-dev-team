---
description: >
  Run code health checks: full assessment, targeted refactoring, or dependency updates.
  Use: /health              — full codebase health report
  Use: /health refactor     — refactor active feature's code
  Use: /health simplify src/auth.rs  — simplify specific file
  Use: /health deps         — review and update dependencies
---

# Code Health

## Input
Mode: $ARGUMENTS (default: full health check)

## Route by Mode

### No arguments or "check" → Full Health Check

Spawn **code-health** (Sonnet) MODE 3:
> "Full codebase health check. Read `.claude/stack.md` for test/lint/outdated commands.
> Scan for complexity, dead code, tech debt, test gaps, dependency issues.
> Save to docs/health-report.md."

Present the health score and top 5 priorities.

### "refactor" → Post-Feature Refactor

Read `docs/features/.active`. If no active feature -> health check instead.
Spawn **code-health** (Sonnet) MODE 1:
> "Post-feature refactor for {active_name}. Review changed code.
> Run tests after changes. Save to {feature_dir}/refactor-report.md."

### "simplify [path]" → Targeted Simplification

Spawn **code-health** (Sonnet) MODE 2:
> "Simplify [target path]. Deep-dive the code, find the simplest version
> that preserves behavior. Run tests after each change."

### "deps" → Dependency Update

Spawn **code-health** (Sonnet) MODE 4:
> "Review and update outdated dependencies. Read `.claude/stack.md` for
> outdated/audit commands. Update safe ones, flag risky ones."
