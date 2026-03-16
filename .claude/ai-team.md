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

## Shared Context

Agents share state via `.ai-team/{feature}/shared-context.md`. Each agent reads it first and appends findings. This prevents re-exploring what previous agents already discovered.

## Commands

`/scope` `/build-phase` `/validate` `/review` `/qa-check` `/sec-check` `/design-review`
`/ship` `/health` `/revert` `/setup` `/features` `/switch` `/approve-plan`
`/fresh` `/scan` `/team`

## Token Tracker

All tool usage is logged to `~/.local/share/claude-token-tracker/tool-usage.jsonl`.
Reports: `~/.claude/scripts/track-tokens.sh [report|tools|agents|models|memory|savings]`

## Conventions

- All generated files go in `.ai-team/{feature}/`, never project root
- Read shared-context.md before exploring the codebase
- Append key findings to shared-context.md for the next agent
- Follow existing codebase patterns over introducing new ones
- Write tests alongside code

## Gate

No active feature → code freely. SOW exists + no plan-approved.md → blocks implementation.
Hooks fail-open. Built-in commands always work.
