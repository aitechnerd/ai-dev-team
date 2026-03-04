#!/usr/bin/env python3
"""
Subagent Orchestrator (SubagentStop)

Auto-chains the next step when a TEAM subagent completes.
Uses active feature directory for file existence checks.

IMPORTANT: Only activates when a feature is active (docs/features/.active exists).
When no feature is active, this hook does nothing — normal Claude Code
workflows (like /simplify, /batch, etc.) work unimpeded.

FAIL-OPEN: If scripts are missing or anything breaks, exits silently.
"""

import json
import sys
import os


def detect_agent(data):
    tool_input = data.get("tool_input", {})
    agent_type = str(
        tool_input.get("agent", "") or tool_input.get("agent_id", "") or ""
    ).lower()
    task_desc = str(
        tool_input.get("description", "")
        or tool_input.get("task", "")
        or tool_input.get("prompt", "")
        or ""
    ).lower()
    return agent_type, task_desc


def is_team_agent(agent_type, task_desc):
    """Return True only if this looks like one of OUR agents, not a built-in."""
    team_agents = {
        "product-owner", "software-engineer", "code-reviewer",
        "devsecops", "qa-engineer", "ux-designer", "code-health",
        "mlops", "triage",
    }
    # Check explicit agent name match
    for name in team_agents:
        if name in agent_type:
            return True
    # Check task description for our pipeline keywords
    team_signals = [
        "technical plan", "technical-plan", "sow.md", "code-review.md",
        "qa-report.md", "security-scan.md", "plan review", "plan-approved",
        "mode 1", "mode 2", "mode 3",
    ]
    for signal in team_signals:
        if signal in task_desc:
            return True
    return False


def emit(context_text):
    json.dump({"additionalContext": context_text}, sys.stdout)
    sys.exit(0)


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    agent_type, task_desc = detect_agent(data)

    # ---- SKIP: not a team agent → don't interfere with default Claude Code ----
    if not is_team_agent(agent_type, task_desc):
        sys.exit(0)

    # ---- SKIP: no feature active → don't interfere ----
    try:
        sys.path.insert(0, os.path.dirname(__file__))
        from feature_helpers import get_active_feature, feature_has_file
    except ImportError:
        sys.exit(0)

    feature_name, feature_dir = get_active_feature()
    if not feature_name:
        sys.exit(0)  # No active feature → silent exit

    feature_prefix = f"[{feature_name}] "

    # ---- SOFTWARE ENGINEER finished planning → PO should review ----
    se_signals = [
        "software-engineer" in agent_type,
        "technical plan" in task_desc,
        "technical-plan" in task_desc,
        "implementation plan" in task_desc,
        "mode 1" in task_desc and "planning" in task_desc,
    ]

    if any(se_signals) and feature_has_file("technical-plan.md"):
        if not feature_has_file("plan-approved.md"):
            emit(
                f"🔄 {feature_prefix}PIPELINE: Software Engineer completed the technical plan. "
                f"Per the team workflow, spawn the devsecops subagent in MODE 1 "
                f"(Plan Review) to review the plan for security architecture, "
                f"infrastructure feasibility, and deployment strategy. "
                f"All docs are in the active feature directory. "
                f"DevSecOps will save to devsecops-plan-review.md."
            )

    # ---- DEVSECOPS finished plan review → trigger PO review ----
    dso_plan_signals = [
        "devsecops" in agent_type and "plan review" in task_desc,
        "devsecops" in agent_type and "mode 1" in task_desc,
    ]

    if any(dso_plan_signals) and feature_has_file("devsecops-plan-review.md"):
        emit(
            f"🔒 {feature_prefix}PIPELINE: DevSecOps plan review complete. "
            f"Check devsecops-plan-review.md for blockers. "
            f"If NO BLOCKERS: spawn product-owner MODE 2 to review the plan. "
            f"If BLOCKERS: present them to the user and ask how to proceed "
            f"before triggering PO review."
        )

    # ---- PRODUCT OWNER finished review → report result ----
    po_signals = [
        "product-owner" in agent_type,
        "plan review" in task_desc,
        "mode 2" in task_desc,
    ]

    if any(po_signals):
        if feature_has_file("plan-approved.md"):
            emit(
                f"✅ {feature_prefix}PIPELINE: Product Owner APPROVED the plan. "
                f"Present the approval to the user with a summary of phases "
                f"and suggest /build-phase 1."
            )
        else:
            emit(
                f"❌ {feature_prefix}PIPELINE: Product Owner did NOT approve the plan. "
                f"Read the PO's feedback and present it. Ask: "
                f"1) Revise the plan? 2) /approve-plan to override? 3) Discuss?"
            )

    # ---- CODE REVIEWER finished → trigger QA ----
    cr_signals = [
        "code-reviewer" in agent_type,
        "code review" in task_desc,
        "review implementation" in task_desc,
    ]

    if any(cr_signals) and feature_has_file("code-review.md"):
        emit(
            f"📋 {feature_prefix}PIPELINE: Code review complete. "
            f"Check the verdict. If APPROVE, proceed to spawn devsecops "
            f"in MODE 2 (Security Scan) to scan the implementation. "
            f"If REQUEST CHANGES, present issues and ask to fix first."
        )

    # ---- DEVSECOPS finished security scan → trigger QA ----
    dso_scan_signals = [
        "devsecops" in agent_type and "security scan" in task_desc,
        "devsecops" in agent_type and "mode 2" in task_desc,
    ]

    if any(dso_scan_signals) and feature_has_file("security-scan.md"):
        emit(
            f"🔒 {feature_prefix}PIPELINE: Security scan complete. "
            f"Check security-scan.md. If PROCEED TO QA: spawn qa-engineer. "
            f"If CRITICAL findings: present them and ask to fix first."
        )

    # ---- QA finished → check verdict ----
    qa_signals = [
        "qa-engineer" in agent_type,
        "qa report" in task_desc,
        "qa-report" in task_desc,
    ]

    if any(qa_signals) and feature_has_file("qa-report.md"):
        emit(
            f"📋 {feature_prefix}PIPELINE: QA validation complete. "
            f"Read the report. If PASS: spawn product-owner MODE 3 for summary. "
            f"If CONDITIONAL PASS: present conditions. "
            f"If FAIL: spawn software-engineer to fix, then re-run QA."
        )

    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        sys.exit(0)  # FAIL-OPEN: any crash = silent exit
