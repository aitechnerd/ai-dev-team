---
description: >
  Initialize persistent project context that all agents reference.
  Run once per project. Creates .claude/project-context.md with
  product vision, conventions, and domain-specific context.
  Use: /setup
---

# Setup — Project Context Initialization

## Overview

Creates a persistent project context file that every agent reads automatically.
This means the PO knows your product vision, the SE knows your architecture
preferences, and DevSecOps knows your compliance requirements — without you
re-explaining every time.

Run this ONCE per project. Update as the project evolves.

## Step 1: Gather Context

Investigate the project to understand what exists:

```bash
# What's in the repo?
find . -maxdepth 2 -type f | head -50
cat README.md 2>/dev/null | head -30
cat CLAUDE.md 2>/dev/null | head -30

# Stack detection
cat .claude/stack.md 2>/dev/null

# Git history for project maturity
git log --oneline | tail -5
git log --oneline | wc -l
```

## Step 2: Interactive Discovery

Ask the user these questions (skip any that are already clear from the codebase):

**Product:**
> 1. What does this product do in one sentence?
> 2. Who are the users? (internal team, customers, developers, patients, etc.)
> 3. Any compliance requirements? (HIPAA, SOC2, PCI-DSS, GDPR, none)

**Architecture:**
> 4. What's the deployment target? (Heroku, AWS, Azure, self-hosted, etc.)
> 5. Any architecture preferences? (monolith, microservices, service objects, etc.)
> 6. Database? (PostgreSQL, MySQL, SQLite, MongoDB, etc.)

**Conventions:**
> 7. Testing philosophy? (TDD, test-after, coverage targets, etc.)
> 8. Git workflow? (trunk-based, gitflow, PR-based, etc.)
> 9. Any code style rules beyond what linters enforce?

**Domain context:**
> 10. Anything domain-specific the AI team should always know?
>     (e.g., "PHI data requires encryption at rest", "all prices in cents",
>     "users are called 'patients' not 'customers'")

## Step 3: Generate Context File

Save to `.claude/project-context.md`:

```markdown
# Project Context

## Product
- **Name:** [project name]
- **Purpose:** [one sentence]
- **Users:** [who uses this]
- **Domain:** [healthcare / fintech / e-commerce / dev tools / etc.]

## Compliance
- [HIPAA / SOC2 / PCI-DSS / GDPR / None]
- [Any specific requirements noted]

## Architecture
- **Stack:** [from stack.md]
- **Deployment:** [target]
- **Database:** [DB]
- **Pattern:** [monolith / microservices / etc.]
- **Key conventions:**
  - [e.g., "Use service objects, not fat controllers"]
  - [e.g., "All API endpoints return JSON:API format"]
  - [e.g., "Background jobs via Sidekiq"]

## Testing
- **Approach:** [TDD / test-after / etc.]
- **Coverage target:** [if any]
- **Framework:** [from stack.md]

## Git Workflow
- **Branching:** [trunk / gitflow / PR-based]
- **Commit style:** [conventional commits / freeform]

## Domain Knowledge
[Anything the AI team should always know about this domain]

## Out of Scope
[Things the AI team should NOT do or touch]
```

## Step 4: Confirm

Show the generated context to the user:
> "Here's your project context. All agents will reference this automatically.
>
> [show content]
>
> Edit `.claude/project-context.md` anytime to update.
> This file should be committed to your repo."

---

## How Agents Use This

Every agent prompt includes: "Read `.claude/project-context.md` if it exists."
This gives agents:
- Domain vocabulary (PO uses correct terms)
- Compliance awareness (DevSecOps focuses on relevant standards)
- Architecture patterns (SE follows established conventions)
- Testing approach (QA validates accordingly)

The file is optional — agents work without it, just with less project-specific context.
