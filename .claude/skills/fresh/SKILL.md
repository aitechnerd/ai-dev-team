---
name: fresh
description: >
  Reset the active feature's planning state, or delete it entirely.
  Use /fresh (reset), /fresh --all (delete), /fresh --clear (deactivate gate).
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Bash
---

# Reset Project

Read `.ai-team/.active` for the active feature.

**Default reset (no flags):**
- Delete from active feature dir: plan-approved.md, devsecops-plan-review.md, code-review.md, security-scan.md, qa-report.md, project-summary.md
- Keep: sow.md, technical-plan.md
> "🔄 Feature '{name}' reset. Gate re-engaged. Run /approve-plan or continue /scope pipeline."

**With --all:**
- Delete the entire `.ai-team/{name}/` directory
- Clear .active if it pointed to this feature
> "🗑️ Feature '{name}' deleted. Run `/features` to see remaining features."

**With --clear:**
- Just remove `.ai-team/.active` (deactivates gate without touching any feature)
> "🔓 No active feature. Gate deactivated. Code freely."
