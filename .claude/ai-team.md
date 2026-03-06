# AI Dev Team — System Reference

> This file is managed by `install.sh` — do not edit manually.
> It gets updated when you run `install.sh project`.

## Entry Point

**`/scope [describe what you need]`** — the only command you need to remember.

It detects what you're asking for:
- **Investigation** → works directly, shows findings, no planning pipeline
- **Bug fix** → lightweight SOW, quick plan, auto-approve → ready to build
- **Feature** → full pipeline: PO discovery → SE plan → reviews → approval

## Agents

| Agent | Model | Role |
|-------|-------|------|
| product-owner | Opus | Scope discovery, SOW, plan approval |
| software-engineer | Opus | Technical plans, implementation |
| code-reviewer | Sonnet | Quality, correctness, YAGNI |
| devsecops | Sonnet | Security, OWASP, compliance |
| qa-engineer | Sonnet | AC validation, edge cases |
| ux-designer | Sonnet | Design review, accessibility |
| code-health | Sonnet | Refactoring, tech debt |
| mlops | Sonnet | ML pipelines (optional) |
| triage | Haiku | Fast preprocessing |

All agents read `.claude/stack.md`, `.claude/project-context.md`, and `.ai-team/{feature}/` docs.

## Commands

| Command | What it does |
|---------|-------------|
| `/scope [description]` | Smart entry: investigation / bugfix / feature |
| `/build-phase [N\|all]` | Build phases. `all` = full autonomous pipeline |
| `/validate` | Run validation pipeline |
| `/review` | Review any branch (code + security, no /scope needed) |
| `/qa-check` | Standalone QA on current changes |
| `/sec-check` | Standalone security review |
| `/design-review` | UX/accessibility review |
| `/ship` | Generate PR description, create draft PR |
| `/health` | Code health, refactoring, dependency updates |
| `/revert [phase N\|feature\|last]` | Semantic undo |
| `/detect` | Detect stack, generate `.claude/stack.md` |
| `/setup` | Create project context (vision, conventions) |
| `/features` | List all features and status |
| `/switch [name]` | Switch active feature |
| `/approve-plan` | Manually approve plan |
| `/fresh` | Reset feature state |
| `/scan` | Run security scanners |
| `/team` | Show all agents and commands |

## Feature Directory

```
.ai-team/
├── .active              ← current feature name
└── patient-search/      ← per-feature artifacts
    ├── sow.md           ← Requirements (from PO)
    ├── feasibility-check.md ← Quick technical review (from SE)
    ├── ux-scope-review.md   ← UX concerns (from UX, if UI feature)
    ├── technical-plan.md← Plan (from SE)
    ├── plan-approved.md ← Approval gate
    ├── code-review.md   ← Code review results
    ├── qa-report.md     ← QA validation
    ├── findings.md      ← Investigation results
    └── scans/           ← Scanner output
```

## Implementation Gate

- **No active feature** → gate inactive, code freely
- **SOW exists, no plan-approved.md** → blocks implementation code
- **plan-approved.md exists** → gate open
- **Always allowed**: docs, tests, configs, .claude/, package files
- **Any hook error** → fail-open, never blocks unexpectedly

## Conventions

- All agents read from `.ai-team/{feature}/`
- All generated files (SQL, scripts, logs) go in `.ai-team/{feature}/`, never project root
- Read the SOW before implementing
- Follow existing codebase patterns over introducing new ones
- Write tests alongside code, not after
