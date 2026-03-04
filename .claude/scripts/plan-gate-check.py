#!/usr/bin/env python3
"""
Plan Approval Gate (PreToolUse: Write|Edit|MultiEdit)

Blocks implementation code writes for the ACTIVE feature unless its
plan-approved.md exists. Gate is inactive if no feature is active
or no SOW exists — you can always code freely without /scope.

FAIL-OPEN: If scripts are missing or anything breaks, writes are ALLOWED.
Exit 0 = allow | Exit 2 = block
"""

import json
import sys
import os


def main():
    # ---- FAIL-OPEN: any error = allow ----
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    tool_input = data.get("tool_input", {})
    file_path = tool_input.get("file_path", "") or tool_input.get("file", "")
    if not file_path:
        sys.exit(0)

    file_path = os.path.normpath(file_path)
    basename = os.path.basename(file_path)
    lower_path = file_path.lower()

    # ---- ALWAYS ALLOWED ----

    if "/docs/" in file_path or file_path.startswith("docs/"):
        sys.exit(0)

    always_allowed_names = {
        "CLAUDE.md", ".gitignore", ".env", ".env.example",
        "package.json", "package-lock.json", "yarn.lock", "pnpm-lock.yaml",
        "Gemfile", "Gemfile.lock", "requirements.txt", "pyproject.toml",
        "Cargo.toml", "Cargo.lock", "go.mod", "go.sum",
        "docker-compose.yml", "docker-compose.yaml", "Dockerfile",
        "Makefile", "Rakefile", "Procfile",
        ".eslintrc", ".eslintrc.js", ".eslintrc.json",
        ".prettierrc", ".prettierrc.js",
        "tsconfig.json", "vite.config.ts", "next.config.js",
        "README.md", "CHANGELOG.md", "LICENSE",
    }
    if basename in always_allowed_names:
        sys.exit(0)

    if "/.claude/" in file_path or file_path.startswith(".claude/"):
        sys.exit(0)

    test_patterns = [
        "test_", "_test.", ".test.", ".spec.",
        "/tests/", "/test/", "/__tests__/", "/spec/", "_spec.",
    ]
    for pattern in test_patterns:
        if pattern in lower_path:
            sys.exit(0)

    # ---- GATE CHECK (only if feature_helpers exists) ----

    try:
        sys.path.insert(0, os.path.dirname(__file__))
        from feature_helpers import any_feature_active, feature_has_file, get_active_feature
    except ImportError:
        sys.exit(0)  # Scripts not installed → allow freely

    if not any_feature_active():
        sys.exit(0)  # No planning cycle → code freely

    if feature_has_file("plan-approved.md"):
        sys.exit(0)  # Plan approved → gate open

    feature_name, _ = get_active_feature()
    print(
        f"⛔ Implementation blocked — plan for '{feature_name}' not yet approved.\n"
        f"\n"
        f"Active feature '{feature_name}' has a SOW but the plan\n"
        f"has not been approved by the Product Owner yet.\n"
        f"\n"
        f"Options:\n"
        f"  • Wait for /scope pipeline to complete\n"
        f"  • /approve-plan      — Manual override\n"
        f"  • /switch [other]    — Switch to an approved feature\n"
        f"  • /fresh             — Cancel planning, deactivate gate\n"
        f"\n"
        f"Writes to docs/, tests, and config files are always allowed.",
        file=sys.stderr,
    )
    sys.exit(2)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        sys.exit(0)  # FAIL-OPEN: any crash = allow
