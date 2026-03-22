---
name: design-review
description: UX designer reviews current implementation for the active feature. Use /design-review [component or area].
disable-model-invocation: true
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Task
---

# Design Review

Read `.ai-team/.active` for the active feature.
Let FEATURE_DIR = `.ai-team/{active_name}/`

Spawn the **ux-designer** subagent:
> "Review UI implementation for feature '{active_name}'.
> Read $FEATURE_DIR/sow.md for context.
> Focus on: $ARGUMENTS (or all user-facing components if not specified).
> Check: states, accessibility, responsive, validation UX, error messages.
> Provide specific, actionable feedback with file:line references."

Present findings and ask if user wants to address them.
