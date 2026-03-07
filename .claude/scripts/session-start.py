#!/usr/bin/env python3
"""
SessionStart: Auto-load minimal project context.

Prints a brief summary so Claude knows the project and active feature
without reading full files. Keeps output under 200 tokens.
"""

import os
import sys


def read_head(path, lines=5):
    """Read first N lines of a file, return empty string if missing."""
    try:
        with open(path) as f:
            return "\n".join(f.readline().rstrip() for _ in range(lines) if f)
    except (FileNotFoundError, PermissionError):
        return ""


def main():
    parts = []

    # Project context — just the first few lines (product name, purpose)
    ctx = read_head(".claude/project-context.md", 6)
    if ctx:
        parts.append(f"## Project\n{ctx}")

    # Stack — just the detected languages line
    stack = read_head(".claude/stack.md", 4)
    if stack:
        parts.append(f"## Stack\n{stack}")

    # Active feature + shared context summary
    active = ""
    try:
        with open(".ai-team/.active") as f:
            active = f.read().strip()
    except FileNotFoundError:
        pass

    if active:
        parts.append(f"## Active Feature: {active}")
        shared = read_head(f".ai-team/{active}/shared-context.md", 8)
        if shared:
            parts.append(shared)
        # Check gate status
        feature_dir = f".ai-team/{active}"
        has_sow = os.path.exists(f"{feature_dir}/sow.md")
        has_plan = os.path.exists(f"{feature_dir}/technical-plan.md")
        has_approved = os.path.exists(f"{feature_dir}/plan-approved.md")
        if has_approved:
            parts.append("Gate: OPEN (plan approved)")
        elif has_sow:
            parts.append("Gate: BLOCKED (plan not approved yet)")
        else:
            parts.append("Gate: INACTIVE")
    else:
        parts.append("No active feature. Use /scope to start.")

    if parts:
        print("\n".join(parts))
    else:
        print("New project. Run /detect then /scope.")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass  # Fail silently — never block session start
