#!/bin/bash
# install-scanners.sh
#
# Installs security and quality scanners based on your project's languages.
# Auto-detects what you need from project files, or install specific stacks.
#
# Usage:
#   bash install-scanners.sh              # Auto-detect and install
#   bash install-scanners.sh rust         # Rust tools only
#   bash install-scanners.sh ruby         # Ruby tools only
#   bash install-scanners.sh python       # Python tools only
#   bash install-scanners.sh js           # JS/TS tools only
#   bash install-scanners.sh all          # Everything
#   bash install-scanners.sh core         # Just Semgrep + Gitleaks + Trivy

set -e

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}ℹ${NC}  $1"; }
ok()    { echo -e "${GREEN}✅${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠️${NC}  $1"; }
fail()  { echo -e "${RED}❌${NC} $1"; }

# --- OS Detection ---
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
fi

HAS_BREW=false
HAS_CARGO=false
HAS_PIP=false
HAS_GEM=false
HAS_NPM=false

command -v brew &>/dev/null && HAS_BREW=true
command -v cargo &>/dev/null && HAS_CARGO=true
command -v pip3 &>/dev/null && HAS_PIP=true || command -v pip &>/dev/null && HAS_PIP=true
command -v gem &>/dev/null && HAS_GEM=true
command -v npm &>/dev/null && HAS_NPM=true

PIP_CMD="pip3"
command -v pip3 &>/dev/null || PIP_CMD="pip"

INSTALLED=0
SKIPPED=0
FAILED=0

install_tool() {
    local name="$1"
    local check_cmd="$2"
    local install_cmd="$3"
    local description="$4"

    if eval "$check_cmd" &>/dev/null 2>&1; then
        ok "$name already installed"
        return
    fi

    info "Installing $name — $description"
    if eval "$install_cmd" 2>&1 | tail -3; then
        ok "$name installed"
        INSTALLED=$((INSTALLED + 1))
    else
        fail "$name failed to install"
        FAILED=$((FAILED + 1))
    fi
}

# ============================================================
# CORE TOOLS (multi-language)
# ============================================================
install_core() {
    echo ""
    echo -e "${BLUE}━━━ Core Tools (all languages) ━━━${NC}"

    # Semgrep
    if $HAS_PIP; then
        install_tool "Semgrep" \
            "command -v semgrep" \
            "$PIP_CMD install semgrep" \
            "SAST scanner for 30+ languages"
    elif $HAS_BREW; then
        install_tool "Semgrep" \
            "command -v semgrep" \
            "brew install semgrep" \
            "SAST scanner for 30+ languages"
    else
        warn "Semgrep: needs pip or brew to install"
    fi

    # Gitleaks
    if $HAS_BREW; then
        install_tool "Gitleaks" \
            "command -v gitleaks" \
            "brew install gitleaks" \
            "Secrets detection (API keys, passwords, tokens)"
    elif [ "$OS" = "linux" ]; then
        install_tool "Gitleaks" \
            "command -v gitleaks" \
            'curl -sSfL https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_8.21.2_linux_x64.tar.gz | tar xz -C /usr/local/bin gitleaks 2>/dev/null || curl -sSfL https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_8.21.2_linux_x64.tar.gz | tar xz -C ~/.local/bin gitleaks' \
            "Secrets detection (API keys, passwords, tokens)"
    else
        warn "Gitleaks: install manually from https://github.com/gitleaks/gitleaks"
    fi

    # Trivy
    if $HAS_BREW; then
        install_tool "Trivy" \
            "command -v trivy" \
            "brew install trivy" \
            "Dependency CVEs, container scanning, misconfigs"
    elif [ "$OS" = "linux" ]; then
        install_tool "Trivy" \
            "command -v trivy" \
            'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin 2>/dev/null || curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b ~/.local/bin' \
            "Dependency CVEs, container scanning, misconfigs"
    else
        warn "Trivy: install manually from https://aquasecurity.github.io/trivy"
    fi
}

# ============================================================
# RUST TOOLS
# ============================================================
install_rust() {
    echo ""
    echo -e "${BLUE}━━━ Rust Tools ━━━${NC}"

    if ! $HAS_CARGO; then
        warn "cargo not found. Install Rust first: https://rustup.rs"
        return
    fi

    install_tool "cargo-audit" \
        "cargo audit --version" \
        "cargo install cargo-audit" \
        "Dependency vulnerability scanner (RustSec database)"

    install_tool "cargo-deny" \
        "cargo deny --version" \
        "cargo install cargo-deny" \
        "License checks, banned crates, duplicate deps, advisories"

    install_tool "cargo-machete" \
        "cargo machete --version" \
        "cargo install cargo-machete" \
        "Find unused dependencies in Cargo.toml"

    install_tool "cargo-geiger" \
        "cargo geiger --version" \
        "cargo install cargo-geiger" \
        "Audit unsafe code usage across dependency tree"

    # clippy comes with rustup, just verify
    if rustup component list --installed 2>/dev/null | grep -q clippy; then
        ok "clippy already installed (via rustup)"
    else
        info "Installing clippy..."
        rustup component add clippy
        ok "clippy installed"
        INSTALLED=$((INSTALLED + 1))
    fi

    # cargo-deny needs a deny.toml — create a starter if missing
    if [ -f "Cargo.toml" ] && [ ! -f "deny.toml" ]; then
        echo ""
        info "Creating starter deny.toml for cargo-deny..."
        cat > deny.toml << 'DENY_EOF'
# cargo-deny configuration
# Docs: https://embarkstudios.github.io/cargo-deny/

[advisories]
vulnerability = "deny"
unmaintained = "warn"
yanked = "warn"
notice = "warn"

[licenses]
unlicensed = "deny"
allow = [
    "MIT",
    "Apache-2.0",
    "BSD-2-Clause",
    "BSD-3-Clause",
    "ISC",
    "Unicode-DFS-2016",
    "Zlib",
]

[bans]
multiple-versions = "warn"
wildcards = "allow"

[sources]
unknown-registry = "warn"
unknown-git = "warn"
allow-registry = ["https://github.com/rust-lang/crates.io-index"]
allow-git = []
DENY_EOF
        ok "deny.toml created (edit to match your license requirements)"
    fi
}

# ============================================================
# RUBY TOOLS
# ============================================================
install_ruby() {
    echo ""
    echo -e "${BLUE}━━━ Ruby Tools ━━━${NC}"

    if ! $HAS_GEM; then
        warn "gem not found. Install Ruby first."
        return
    fi

    install_tool "Brakeman" \
        "command -v brakeman" \
        "gem install brakeman" \
        "Rails SAST (SQL injection, XSS, mass assignment)"

    install_tool "bundler-audit" \
        "command -v bundler-audit" \
        "gem install bundler-audit" \
        "Known CVEs in Ruby gems"

    install_tool "RuboCop" \
        "command -v rubocop" \
        "gem install rubocop" \
        "Code quality, style, complexity"
}

# ============================================================
# PYTHON TOOLS
# ============================================================
install_python() {
    echo ""
    echo -e "${BLUE}━━━ Python Tools ━━━${NC}"

    if ! $HAS_PIP; then
        warn "pip not found. Install Python first."
        return
    fi

    install_tool "Bandit" \
        "command -v bandit" \
        "$PIP_CMD install bandit" \
        "Python SAST (hardcoded passwords, injection, unsafe functions)"

    install_tool "pip-audit" \
        "command -v pip-audit" \
        "$PIP_CMD install pip-audit" \
        "Known CVEs in Python packages"
}

# ============================================================
# JS/TS TOOLS
# ============================================================
install_js() {
    echo ""
    echo -e "${BLUE}━━━ JavaScript / TypeScript Tools ━━━${NC}"

    if ! $HAS_NPM; then
        warn "npm not found. Install Node.js first."
        return
    fi

    ok "npm audit — built-in (no install needed)"

    if [ -f "package.json" ]; then
        install_tool "ESLint" \
            "npx eslint --version" \
            "npm install -D eslint eslint-plugin-security" \
            "Code quality + security linting"
    else
        info "No package.json — skipping ESLint project install"
    fi
}

# ============================================================
# DOCKER TOOLS
# ============================================================
install_docker() {
    echo ""
    echo -e "${BLUE}━━━ Docker / Infrastructure ━━━${NC}"

    if $HAS_BREW; then
        install_tool "Hadolint" \
            "command -v hadolint" \
            "brew install hadolint" \
            "Dockerfile linter and security checker"
    elif [ "$OS" = "linux" ]; then
        install_tool "Hadolint" \
            "command -v hadolint" \
            'curl -sSL -o /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 && chmod +x /usr/local/bin/hadolint' \
            "Dockerfile linter and security checker"
    fi
}

# ============================================================
# PHP TOOLS
# ============================================================
install_php() {
    echo ""
    echo -e "${BLUE}━━━ PHP Tools ━━━${NC}"

    if ! command -v php &>/dev/null; then
        warn "php not found. Install PHP first."
        return
    fi

    if ! command -v composer &>/dev/null; then
        warn "composer not found. Install Composer first: https://getcomposer.org"
        return
    fi

    ok "composer audit — built-in (Composer 2.4+, no install needed)"

    if [ -f "composer.json" ]; then
        # PHPStan (project-level via composer)
        install_tool "PHPStan" \
            "test -f vendor/bin/phpstan || command -v phpstan" \
            "composer require --dev phpstan/phpstan" \
            "Static analysis (type errors, logic bugs, dead code)"

        # PHP-CS-Fixer or Pint
        if grep -q "laravel" composer.json 2>/dev/null; then
            install_tool "Laravel Pint" \
                "test -f vendor/bin/pint" \
                "composer require --dev laravel/pint" \
                "Code style fixer (Laravel standard)"
        else
            install_tool "PHP-CS-Fixer" \
                "test -f vendor/bin/php-cs-fixer || command -v php-cs-fixer" \
                "composer require --dev friendsofphp/php-cs-fixer" \
                "Code style and formatting fixer"
        fi

        # Psalm (alternative static analysis)
        # install_tool "Psalm" \
        #     "test -f vendor/bin/psalm" \
        #     "composer require --dev vimeo/psalm" \
        #     "Static analysis with taint detection"
    else
        info "No composer.json — skipping project-level PHP tools"
    fi

    # PHPStan starter config
    if [ -f "vendor/bin/phpstan" ] && [ ! -f "phpstan.neon" ] && [ ! -f "phpstan.neon.dist" ]; then
        info "Creating starter phpstan.neon..."
        cat > phpstan.neon << 'PHPSTAN_CONF'
parameters:
    level: 6
    paths:
        - app
        - src
    excludePaths:
        - vendor
PHPSTAN_CONF
        ok "Created phpstan.neon (level 6)"
    fi
}

# ============================================================
# AUTO-DETECT
# ============================================================
auto_detect() {
    info "Auto-detecting project languages..."
    echo ""

    local detected=()

    if [ -f "Cargo.toml" ]; then
        detected+=("rust")
        ok "Detected: Rust (Cargo.toml)"
    fi
    if [ -f "Gemfile" ]; then
        detected+=("ruby")
        ok "Detected: Ruby (Gemfile)"
    fi
    if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "Pipfile" ]; then
        detected+=("python")
        ok "Detected: Python"
    fi
    if [ -f "package.json" ]; then
        detected+=("js")
        ok "Detected: JavaScript/TypeScript (package.json)"
    fi
    if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
        detected+=("docker")
        ok "Detected: Docker"
    fi
    if [ -f "composer.json" ]; then
        detected+=("php")
        ok "Detected: PHP (composer.json)"
    fi

    if [ ${#detected[@]} -eq 0 ]; then
        warn "No project files detected. Installing core tools only."
    fi

    install_core

    for lang in "${detected[@]}"; do
        case $lang in
            rust)   install_rust ;;
            ruby)   install_ruby ;;
            python) install_python ;;
            js)     install_js ;;
            php)    install_php ;;
            docker) install_docker ;;
        esac
    done
}

# ============================================================
# MAIN
# ============================================================
echo ""
echo "🔧 Scanner Tools Installer"
echo "=========================="
echo "OS: $OS | brew: $HAS_BREW | cargo: $HAS_CARGO | pip: $HAS_PIP | gem: $HAS_GEM | npm: $HAS_NPM"
echo ""

case "${1:-auto}" in
    auto)    auto_detect ;;
    core)    install_core ;;
    rust)    install_core; install_rust ;;
    ruby)    install_core; install_ruby ;;
    python)  install_core; install_python ;;
    js)      install_core; install_js ;;
    php)     install_core; install_php ;;
    docker)  install_core; install_docker ;;
    all)
        install_core
        install_rust
        install_ruby
        install_python
        install_js
        install_php
        install_docker
        ;;
    *)
        echo "Usage: bash install-scanners.sh [auto|core|rust|ruby|python|js|php|docker|all]"
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Installed: ${GREEN}$INSTALLED${NC} | Skipped (already present): — | Failed: ${RED}$FAILED${NC}"
echo ""
echo "Run '/scan' in Claude Code to test your scanners."
echo "Run 'bash .claude/scripts/run-scanners.sh' to run directly."
