# AI Dev Team

> Auto-updated by installer. Do not edit.

## Entry Point

`/scope [describe what you need]` — detects investigation / bug / small feature / large feature.

| Type | Agent Calls | Models |
|------|-------------|--------|
| Investigation | 0 | Direct |
| Bug fix | 2-3 | PO(Sonnet) + SE(Opus) |
| Small feature | 3-4 | PO(Sonnet) + SE(Opus) + DevSecOps? |
| Large feature | 6-8 | PO(Opus) + SE(Opus) + reviews(Sonnet) |

## Model Strategy

Three tiers — use the cheapest model that can do the job:

| Tier | Model | Use for | Agents |
|------|-------|---------|--------|
| Heavy | Opus | Planning, implementation, complex scoping | SE, PO (large features) |
| Standard | Sonnet | Reviews, security, QA, health checks | CR, QA, DevSecOps, Code Health, UX, MLOps, PO (bugs/small) |
| Fast | Haiku | Triage, structure checks, second-pass review | Triage, CR (second pass) |

Downgrades: PO uses Sonnet for bugs/small features. SE uses Sonnet for feasibility checks.
Second-pass code review (fix verification) uses Haiku — narrow scope, CRITICAL/HIGH only.

## Context Isolation

Heavy pipeline skills run with `context: fork` to prevent large outputs from
polluting the main conversation window: `/validate`, `/review`, `/qa-browser`, `/scan`.
Interactive skills (`/scope`, `/build-phase`) stay in the main context for user interaction.

## Shared Context

Agents share state via `.ai-team/{feature}/shared-context.md`. Each agent reads it first and appends findings. This prevents re-exploring what previous agents already discovered.

## Commands

`/scope` `/build-phase` `/validate` `/review` `/qa-check` `/sec-check` `/design-review`
`/ship` `/health` `/revert` `/setup` `/features` `/switch` `/approve-plan`
`/fresh` `/scan` `/team`

## Token Tracker

All tool usage is logged to `~/.local/share/claude-token-tracker/tool-usage.jsonl`.
Reports: `~/.claude/scripts/track-tokens.sh [report|tools|agents|models|memory|savings]`

## Agent Memory Namespaces

Each agent stores memories under its own prefix to avoid cross-role noise:

| Agent | Prefix | Examples |
|-------|--------|----------|
| Product Owner | `po/` | `po/scope-patterns`, `po/user-prefs` |
| Software Engineer | `se/` | `se/build-commands`, `se/test-patterns` |
| Code Reviewer | `cr/` | `cr/common-issues`, `cr/conventions` |
| QA Engineer | `qa/` | `qa/edge-cases`, `qa/flaky-tests` |
| DevSecOps | `sec/` | `sec/vuln-patterns`, `sec/infra-setup` |
| Code Health | `health/` | `health/debt-items`, `health/dep-conventions` |
| UX Designer | `ux/` | `ux/component-patterns`, `ux/a11y-issues` |
| MLOps | `ml/` | `ml/training-setup`, `ml/serving-patterns` |

Triage agent has no memory (fast, disposable).

## Conventions

- All generated files go in `.ai-team/{feature}/`, never project root
- Read shared-context.md before exploring the codebase
- Append key findings to shared-context.md for the next agent
- Follow existing codebase patterns over introducing new ones
- Write tests alongside code

## Gate

No active feature → code freely. SOW exists + no plan-approved.md → blocks implementation.
Hooks fail-open. Built-in commands always work.
