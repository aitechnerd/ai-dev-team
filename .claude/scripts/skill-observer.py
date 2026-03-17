#!/usr/bin/env python3
"""
Skill Observer — PostToolUse hook that tracks skill outcomes and detects failure signals.

Feeds data into the eval system for self-improvement.

How it works:
- Runs as a PostToolUse hook alongside track-tokens.sh
- Logs skill invocations with timestamps to a session file
- Detects failure signals: retries (same skill <60s), user corrections
- Writes observations to ~/.local/share/claude-skill-observer/

Data flow:
  PostToolUse → skill-observer.py → observations.jsonl
                                  → {skill}/outcomes.jsonl
  /eval --improve reads outcomes.jsonl to identify weak spots
"""

import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

# ── Config ──────────────────────────────────────────────────
OBS_DIR = Path.home() / ".local" / "share" / "claude-skill-observer"
OBS_DIR.mkdir(parents=True, exist_ok=True)

OBSERVATIONS_LOG = OBS_DIR / "observations.jsonl"
SESSION_STATE = OBS_DIR / "session-state.json"

# Failure signal: same skill invoked within this many seconds = likely retry
RETRY_WINDOW_SECONDS = 90

# ── Read hook input ─────────────────────────────────────────
try:
    raw = sys.stdin.read()
    if not raw.strip():
        print("{}")
        sys.exit(0)
    event = json.loads(raw)
except (json.JSONDecodeError, Exception):
    print("{}")
    sys.exit(0)

tool_name = event.get("tool_name", "")

# Only observe Skill invocations and user messages that follow skills
if tool_name != "Skill":
    # Check if this is a tool call right after a skill — could indicate
    # the user is manually doing what the skill should have done (correction signal)
    try:
        state = json.loads(SESSION_STATE.read_text()) if SESSION_STATE.exists() else {}
    except (json.JSONDecodeError, Exception):
        state = {}

    last_skill = state.get("last_skill")
    last_skill_ts = state.get("last_skill_ts", 0)

    # If a Write/Edit happens within 120s of a skill that should have written code,
    # and it's to a file the skill likely should have handled, that's a weak signal
    # We log it but don't treat it as a hard failure
    if last_skill and tool_name in ("Write", "Edit", "MultiEdit"):
        age = time.time() - last_skill_ts
        if age < 120:
            obs = {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "type": "post_skill_manual_edit",
                "skill": last_skill,
                "tool": tool_name,
                "seconds_after_skill": round(age),
                "file": event.get("tool_input", {}).get("file_path", ""),
                "signal_strength": "weak",
            }
            with open(OBSERVATIONS_LOG, "a") as f:
                f.write(json.dumps(obs) + "\n")

            # Also write to per-skill log
            skill_dir = OBS_DIR / last_skill
            skill_dir.mkdir(exist_ok=True)
            with open(skill_dir / "outcomes.jsonl", "a") as f:
                f.write(json.dumps(obs) + "\n")

    print("{}")
    sys.exit(0)

# ── Skill invocation ────────────────────────────────────────
skill_name = event.get("tool_input", {}).get("skill", "")
if not skill_name:
    print("{}")
    sys.exit(0)

now = time.time()
now_iso = datetime.now(timezone.utc).isoformat()
session_id = event.get("session_id", "")

# Load session state
try:
    state = json.loads(SESSION_STATE.read_text()) if SESSION_STATE.exists() else {}
except (json.JSONDecodeError, Exception):
    state = {}

# ── Detect retry (same skill within RETRY_WINDOW_SECONDS) ──
is_retry = False
last_skill = state.get("last_skill")
last_skill_ts = state.get("last_skill_ts", 0)

if last_skill == skill_name and (now - last_skill_ts) < RETRY_WINDOW_SECONDS:
    is_retry = True
    retry_count = state.get("retry_count", 0) + 1
else:
    retry_count = 0

# ── Check if previous skill had no retry (success signal) ──
if last_skill and last_skill != skill_name and not is_retry:
    # Previous skill was followed by a different action = likely succeeded
    prev_obs = {
        "timestamp": now_iso,
        "type": "skill_success",
        "skill": last_skill,
        "signal": "no_retry",
        "signal_strength": "moderate",
        "session_id": session_id,
        "duration_until_next": round(now - last_skill_ts),
    }
    with open(OBSERVATIONS_LOG, "a") as f:
        f.write(json.dumps(prev_obs) + "\n")

    prev_dir = OBS_DIR / last_skill
    prev_dir.mkdir(exist_ok=True)
    with open(prev_dir / "outcomes.jsonl", "a") as f:
        f.write(json.dumps(prev_obs) + "\n")

# ── Log current invocation ──────────────────────────────────
obs = {
    "timestamp": now_iso,
    "type": "skill_retry" if is_retry else "skill_invocation",
    "skill": skill_name,
    "session_id": session_id,
    "signal_strength": "strong" if is_retry else "neutral",
}

if is_retry:
    obs["retry_count"] = retry_count
    obs["seconds_since_last"] = round(now - last_skill_ts)

with open(OBSERVATIONS_LOG, "a") as f:
    f.write(json.dumps(obs) + "\n")

# Per-skill log
skill_dir = OBS_DIR / skill_name
skill_dir.mkdir(exist_ok=True)
with open(skill_dir / "outcomes.jsonl", "a") as f:
    f.write(json.dumps(obs) + "\n")

# ── Update session state ────────────────────────────────────
state["last_skill"] = skill_name
state["last_skill_ts"] = now
state["retry_count"] = retry_count
state["session_id"] = session_id

SESSION_STATE.write_text(json.dumps(state))

# Pass through — don't modify anything
print("{}")
