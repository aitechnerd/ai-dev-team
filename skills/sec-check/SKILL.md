---
name: sec-check
description: Quick security review on current changes without the full pipeline. Checks for common vulnerabilities and compliance issues.
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Task
---

# Security Check — Standalone Security Review

Lightweight security pass on current changes. No /scope required.

## Step 1: Detect Context

```bash
git diff --stat HEAD~3..HEAD
git diff --name-only HEAD~3..HEAD
```

Read `.claude/project-context.md` for compliance requirements (HIPAA, SOC2, etc.).
Read `.claude/stack.md` for stack-specific security concerns.

## Step 2: Quick Scan

If scanners are configured:
```bash
bash ~/.claude/scripts/run-scanners.sh "/tmp/sec-check-scans" 2>/dev/null
```

## Step 3: Security Review

Spawn **devsecops** (Sonnet):
> "MODE: standalone-check.
> Review the recent changes (last 3 commits + staged + unstaged).
> Stack: read `.claude/stack.md` if available.
> Project context: read `.claude/project-context.md` for compliance requirements.
> Scanner reports: read /tmp/sec-check-scans/ if they exist.
> $ARGUMENTS focus: {user's focus area if provided}.
>
> Check:
> 1. OWASP Top 10 relevance to these changes
> 2. Input validation, auth checks, data exposure
> 3. Compliance issues (if project-context.md specifies HIPAA/SOC2/etc.)
> 4. Secrets or credentials in code
> 5. Dependency vulnerabilities (if scanner output available)
>
> Output a brief report. Don't save to a file — just print results."

## Step 4: Show Results

> "**Security Check Results**
> [CLEAN / FINDINGS]
>
> [findings by severity]
>
> Want me to fix any issues?"

If user says yes → spawn SE to fix.
