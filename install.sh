#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION=$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "unknown")

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✅${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠️${NC}  $1"; }
info() { echo -e "  ${BLUE}ℹ${NC}  $1"; }

echo "🤖 AI Dev Team v$VERSION"
echo "════════════════════════════════"
echo ""

# ============================================================
# USAGE
# ============================================================
show_usage() {
    echo "Usage: bash install.sh [command]"
    echo ""
    echo "Commands:"
    echo "  global       Install/update agents, commands, stacks to ~/.claude/"
    echo "  project      Set up current project: settings.json, CLAUDE.md"
    echo "  full         Global install + project setup (first time)"
    echo "  update       Pull latest from git + reinstall globally"
    echo "  status       Show what's installed and check for updates"
    echo "  version      Show installed version"
    echo ""
    echo "First time:    git clone <repo> ~/.ai-team && cd ~/.ai-team && bash install.sh full"
    echo "Update:        bash ~/.ai-team/install.sh update"
    echo "New project:   cd ~/my-project && bash ~/.ai-team/install.sh project"
}

# ============================================================
# GLOBAL INSTALL — shared across all projects
# ============================================================
install_global() {
    local TARGET="$HOME/.claude"
    echo -e "${BLUE}━━━ Global Install: $TARGET ━━━${NC}"
    echo ""

    mkdir -p "$TARGET/agents" "$TARGET/commands" "$TARGET/scripts" "$TARGET/stacks"

    echo "📋 Agents..."
    for agent in product-owner software-engineer ux-designer qa-engineer code-reviewer devsecops triage mlops code-health; do
        if [ -f "$SCRIPT_DIR/.claude/agents/$agent.md" ]; then
            cp -f "$SCRIPT_DIR/.claude/agents/$agent.md" "$TARGET/agents/"
            ok "$agent"
        else
            warn "$agent.md not found in package"
        fi
    done

    echo ""
    echo "📋 Commands..."
    for cmd in scope build-phase validate features switch scan detect ship health review setup revert design-review approve-plan fresh team qa-check sec-check; do
        if [ -f "$SCRIPT_DIR/.claude/commands/$cmd.md" ]; then
            cp -f "$SCRIPT_DIR/.claude/commands/$cmd.md" "$TARGET/commands/"
            ok "/$cmd"
        else
            warn "$cmd.md not found in package"
        fi
    done

    echo ""
    echo "📋 Stack profiles..."
    for stack in rust rails python react php mlops; do
        if [ -f "$SCRIPT_DIR/.claude/stacks/$stack.md" ]; then
            cp -f "$SCRIPT_DIR/.claude/stacks/$stack.md" "$TARGET/stacks/"
            ok "$stack"
        fi
    done

    echo ""
    echo "📋 Scripts..."
    cp -f "$SCRIPT_DIR/.claude/scripts/"*.py "$TARGET/scripts/" 2>/dev/null && true
    cp -f "$SCRIPT_DIR/.claude/scripts/"*.sh "$TARGET/scripts/" 2>/dev/null && true
    chmod +x "$TARGET/scripts/"*.py "$TARGET/scripts/"*.sh 2>/dev/null || true
    ok "run-scanners.sh, plan-gate-check.py, subagent-orchestrator.py"

    echo ""
    echo -e "${GREEN}Global install complete.${NC}"
    echo ""
    echo "Installed to: $TARGET"
    echo "  agents/    — 9 agents (Opus: PO + SE, Haiku: triage, Sonnet: rest)"
    echo "  commands/  — 12 slash commands"
    echo "  stacks/    — 6 language profiles"
    echo "  scripts/   — scanner runner + helpers"
}

# ============================================================
# PROJECT SETUP — per-project config
# ============================================================
setup_project() {
    local TARGET="./.claude"
    echo -e "${BLUE}━━━ Project Setup: $(pwd) ━━━${NC}"
    echo ""

    # Check global install exists
    if [ ! -d "$HOME/.claude/agents" ]; then
        warn "Global install not found. Run 'bash install.sh global' first."
        echo ""
        return 1
    fi

    mkdir -p "$TARGET"
    mkdir -p "docs/features"

    # settings.json — hooks config (project-level only)
    if [ ! -f "$TARGET/settings.json" ]; then
        cp "$SCRIPT_DIR/.claude/settings.json" "$TARGET/settings.json"
        ok "settings.json (hooks config)"
    else
        info "settings.json already exists — skipping"
    fi

    # CLAUDE.md — project conventions
    if [ ! -f "CLAUDE.md" ]; then
        cp "$SCRIPT_DIR/CLAUDE.md" "./CLAUDE.md"
        ok "CLAUDE.md → project root"
    else
        echo ""
        warn "CLAUDE.md exists. To add team system docs, append:"
        echo "     cat $SCRIPT_DIR/CLAUDE.md >> CLAUDE.md"
    fi

    echo ""
    echo -e "${GREEN}Project setup complete.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. In Claude Code, run:  /detect          # Detect languages, generate stack.md"
    echo "  2. Install scanners:     bash ~/ai-team/install-scanners.sh"
    echo "  3. Start building:       /scope [description]"
}

# ============================================================
# STATUS — show what's installed
# ============================================================
show_status() {
    echo -e "${BLUE}━━━ Installation Status ━━━${NC}"
    echo ""

    # Repo info
    echo "REPO ($SCRIPT_DIR):"
    echo "  Version: v$VERSION"
    if [ -d "$SCRIPT_DIR/.git" ]; then
        local branch=$(git -C "$SCRIPT_DIR" branch --show-current 2>/dev/null || echo "unknown")
        local last_commit=$(git -C "$SCRIPT_DIR" log -1 --format="%h %s" 2>/dev/null || echo "unknown")
        echo "  Branch:  $branch"
        echo "  Latest:  $last_commit"
    fi
    echo ""

    # Global
    echo "GLOBAL (~/.claude/):"
    if [ -d "$HOME/.claude/agents" ]; then
        local agent_count=$(ls "$HOME/.claude/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
        local cmd_count=$(ls "$HOME/.claude/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
        local stack_count=$(ls "$HOME/.claude/stacks/"*.md 2>/dev/null | wc -l | tr -d ' ')
        ok "Agents:   $agent_count ($(ls "$HOME/.claude/agents/"*.md 2>/dev/null | xargs -I{} basename {} .md | tr '\n' ' '))"
        ok "Commands: $cmd_count"
        ok "Stacks:   $stack_count ($(ls "$HOME/.claude/stacks/"*.md 2>/dev/null | xargs -I{} basename {} .md | tr '\n' ' '))"
        if [ -d "$HOME/.claude/scripts" ]; then
            ok "Scripts:  installed"
        fi
    else
        warn "Not installed. Run: bash install.sh global"
    fi

    echo ""
    echo "PROJECT ($(pwd)/.claude/):"
    if [ -f ".claude/settings.json" ]; then
        ok "settings.json"
    else
        warn "settings.json — not set up. Run: bash install.sh project"
    fi
    if [ -f ".claude/stack.md" ]; then
        local stacks=$(grep -A20 "Detected\|Active" .claude/stack.md 2>/dev/null | grep "^-" | head -5)
        ok "stack.md (detected)"
        echo "$stacks" | while read line; do echo "     $line"; done
    else
        info "stack.md — not generated yet. Run /detect in Claude Code"
    fi
    if [ -f "CLAUDE.md" ]; then
        ok "CLAUDE.md"
    else
        info "CLAUDE.md — not found"
    fi
    if [ -d "docs/features" ]; then
        local feat_count=$(ls -d docs/features/*/ 2>/dev/null | wc -l | tr -d ' ')
        ok "Features: $feat_count"
    fi
}

# ============================================================
# UPDATE — git pull + reinstall
# ============================================================
do_update() {
    cd "$SCRIPT_DIR"

    # Check if this is a git repo
    if [ -d ".git" ]; then
        echo -e "${BLUE}━━━ Pulling latest from git ━━━${NC}"
        echo ""

        local BEFORE=$(cat VERSION 2>/dev/null)
        git pull --ff-only 2>&1 || {
            warn "git pull failed. You may have local changes."
            echo "  Try: cd $SCRIPT_DIR && git stash && git pull && git stash pop"
            echo ""
        }
        local AFTER=$(cat VERSION 2>/dev/null)

        if [ "$BEFORE" != "$AFTER" ]; then
            ok "Updated: v$BEFORE → v$AFTER"
        else
            info "Already up to date (v$AFTER)"
        fi
        echo ""
    else
        info "Not a git repo — installing from local files"
        echo ""
    fi

    install_global
}

# ============================================================
# MAIN
# ============================================================
case "${1:-}" in
    global)
        install_global
        ;;
    update)
        do_update
        ;;
    project)
        setup_project
        ;;
    full)
        install_global
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        setup_project
        ;;
    status)
        show_status
        ;;
    version|-v|--version)
        echo "v$VERSION"
        ;;
    *)
        show_usage
        ;;
esac
