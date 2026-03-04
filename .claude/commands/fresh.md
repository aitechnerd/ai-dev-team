---
description: >
  Reset the active feature's planning state, or delete it entirely.
  Use: /fresh          — Reset active feature (keep SOW and plan)
       /fresh --all    — Delete active feature's entire directory
       /fresh --clear  — Remove .active pointer (deactivate gate)
---

# Reset Project

Read `docs/features/.active` for the active feature.

**Default reset (no flags):**
- Delete from active feature dir: plan-approved.md, devsecops-plan-review.md, code-review.md, security-scan.md, qa-report.md, project-summary.md
- Keep: sow.md, technical-plan.md
> "🔄 Feature '{name}' reset. Gate re-engaged. Run /approve-plan or continue /scope pipeline."

**With --all:**
- Delete the entire `docs/features/{name}/` directory
- Clear .active if it pointed to this feature
> "🗑️ Feature '{name}' deleted. Run `/features` to see remaining features."

**With --clear:**
- Just remove `docs/features/.active` (deactivates gate without touching any feature)
> "🔓 No active feature. Gate deactivated. Code freely."
