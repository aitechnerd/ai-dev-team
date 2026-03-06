---
description: >
  Show all agents, commands, and workflows available in AI Dev Team.
  Use: /team
  Use: /team agents
  Use: /team commands
  Use: /team workflow
---

# Team — Agent & Command Reference

Show what's available. Default: show everything. Pass an argument to filter.

## If $ARGUMENTS is empty or "all"

Print this reference card. Use plain text, no box-drawing characters, no code blocks:

```
AI DEV TEAM v0.1

AGENTS (9)

  product-owner     Scope discovery, SOW, plan approval        [Opus]
  software-engineer Plans, implements, tests across all stacks  [Opus]
  code-reviewer     Quality, correctness, over-engineering      [Sonnet]
  devsecops         Security audit, OWASP, compliance           [Sonnet]
  qa-engineer       AC validation, edge cases, test gaps        [Sonnet]
  ux-designer       Design review, accessibility                [Sonnet]
  code-health       Post-feature refactoring, tech debt         [Sonnet]
  mlops             ML pipeline, model deployment (optional)    [Sonnet]
  triage            Fast preprocessing, research, scan parsing  [Haiku]

COMMANDS (18)

  Planning:   /scope (smart router)  /approve-plan  /features  /switch
  Setup:      /detect  /setup  /fresh
  Building:   /build-phase  /validate  /scan
  Review:     /review  /qa-check  /sec-check  /design-review
  Shipping:   /ship  /health  /revert
  Info:       /team

AUTONOMOUS PIPELINE

  /scope detects task type:
    Investigation → works directly, shows findings
    Bug fix → lightweight SOW → quick plan → build
    Feature → full pipeline: PO → SE → reviews → build

STANDALONE (no /scope needed)

  /review     Review any branch (code + security)
  /qa-check   Run QA validation on current changes
  /sec-check  Run security review on current changes
  /health     Code health check and refactoring
  /scan       Run static analysis scanners

STACKS: rust · rails · python · react · php · mlops
```

## If $ARGUMENTS is "agents"

List all 9 agents with their model tier, tools, and detailed purpose.

## If $ARGUMENTS is "commands"

List all 18 commands grouped by category with full descriptions.

## If $ARGUMENTS is "workflow"

Show the full autonomous pipeline with all 9 steps, explaining
what happens at each stage and which agents run.
