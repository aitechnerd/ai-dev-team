---
description: >
  Run all available security and quality scanners on the codebase.
  Auto-detects project languages and runs appropriate tools.
  Reports are saved to the active feature's scans/ directory.
  Use: /scan [optional: specific tool name]
---

# Scan — Run Security & Quality Scanners

## Process

1. Determine the output directory:
   - If active feature exists: `.ai-team/{active_name}/scans/`
   - Otherwise: `docs/scans/`

2. Run the scanner script:
   ```bash
   bash ~/.claude/scripts/run-scanners.sh
   ```

3. After scan completes, read `scan-summary.md` from the output directory.

4. Present results to the user:
   - List which tools ran and their status
   - Highlight any tools that found issues
   - For tools with findings, briefly summarize the most critical items

5. If there are findings, ask:
   > "Would you like me to have the DevSecOps agent analyze these reports in detail?"

   If yes, spawn **devsecops** subagent:
   > "MODE 2: Security Scan.
   > Review the scanner reports in {scan_dir}/.
   > Read each JSON report, correlate findings across tools,
   > prioritize by severity, and produce a consolidated analysis.
   > Save to {feature_dir}/security-scan.md."

## If specific tool requested ($ARGUMENTS)

Only run that tool. Supported names:
- semgrep, gitleaks, trivy
- cargo-audit, cargo-clippy, cargo-deny, cargo-geiger, cargo-machete
- brakeman, bundler-audit, rubocop
- bandit, pip-audit
- npm-audit, eslint
- phpstan, hadolint

## Missing Tools

If no scanners are installed, show install instructions from the summary
and offer to install them:
> "I can install the recommended tools for your stack. Proceed?"
