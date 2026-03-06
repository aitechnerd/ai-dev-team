"""
Shared helper for resolving the active feature directory.

Structure:
  .ai-team/.active          ← contains feature name (e.g., "patient-intake")
  .ai-team/patient-intake/  ← feature artifacts
    sow.md
    technical-plan.md
    plan-approved.md
    code-review.md
    qa-report.md
    project-summary.md
"""

import os


def get_active_feature():
    """Return (feature_name, feature_dir) or (None, None) if no active feature."""
    active_file_paths = [
        os.path.join(os.getcwd(), "docs", "features", ".active"),
        os.path.join("docs", "features", ".active"),
    ]

    for path in active_file_paths:
        if os.path.exists(path):
            name = open(path).read().strip()
            if name:
                feature_dir = os.path.join(os.path.dirname(path), name)
                if os.path.isdir(feature_dir):
                    return name, feature_dir
    return None, None


def feature_has_file(filename):
    """Check if the active feature has a specific file."""
    _, feature_dir = get_active_feature()
    if feature_dir:
        return os.path.exists(os.path.join(feature_dir, filename))
    return False


def any_feature_active():
    """Check if any feature planning cycle is active (has sow.md)."""
    _, feature_dir = get_active_feature()
    if feature_dir:
        return os.path.exists(os.path.join(feature_dir, "sow.md"))
    return False
