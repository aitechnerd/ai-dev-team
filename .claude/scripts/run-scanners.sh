#!/usr/bin/env bash
# .claude/scripts/run-scanners.sh
#
# Auto-detects project language(s) and runs available security/quality
# scanners that produce structured reports. Reports are saved to a
# specified output directory (default: docs/features/{active}/scans/).
#
# Usage:
#   bash .claude/scripts/run-scanners.sh [output_dir]
#
# Exit code: 0 always (reports are for agents to interpret, not to block)

set -euo pipefail

# --- Output directory ---
ACTIVE_FILE="docs/features/.active"
if [ -n "${1:-}" ]; then
    OUT_DIR="$1"
elif [ -f "$ACTIVE_FILE" ]; then
    FEATURE=$(cat "$ACTIVE_FILE" | tr -d '[:space:]')
    OUT_DIR="docs/features/$FEATURE/scans"
else
    OUT_DIR="docs/scans"
fi
mkdir -p "$OUT_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SUMMARY_FILE="$OUT_DIR/scan-summary.md"

echo "# Scan Report" > "$SUMMARY_FILE"
echo "**Date:** $TIMESTAMP" >> "$SUMMARY_FILE"
echo "**Directory:** $(pwd)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

TOOLS_RUN=0
TOOLS_FAILED=0

run_tool() {
    local name="$1"
    local cmd="$2"
    local output_file="$3"
    local description="$4"

    echo "🔍 Running $name..."
    if eval "$cmd" > "$output_file" 2>&1; then
        echo "  ✅ $name completed"
        echo "### ✅ $name" >> "$SUMMARY_FILE"
    else
        local exit_code=$?
        echo "  ⚠️  $name found issues (exit $exit_code)"
        echo "### ⚠️  $name (exit $exit_code)" >> "$SUMMARY_FILE"
        TOOLS_FAILED=$((TOOLS_FAILED + 1))
    fi
    echo "- $description" >> "$SUMMARY_FILE"
    echo "- Report: \`$output_file\`" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    TOOLS_RUN=$((TOOLS_RUN + 1))
}

# ============================================================
# MULTI-LANGUAGE TOOLS
# ============================================================

# --- Semgrep (SAST — all languages) ---
if command -v semgrep &>/dev/null; then
    run_tool "Semgrep" \
        "semgrep --config=auto --json --quiet 2>/dev/null || true" \
        "$OUT_DIR/semgrep.json" \
        "Static analysis (SAST) across all languages"
fi

# --- Gitleaks (secrets detection) ---
if command -v gitleaks &>/dev/null; then
    run_tool "Gitleaks" \
        "gitleaks detect --source . --report-format json --report-path /dev/stdout --no-banner 2>/dev/null || true" \
        "$OUT_DIR/gitleaks.json" \
        "Secrets detection (API keys, passwords, tokens)"
fi

# --- Trivy (dependency vulnerabilities + misconfigs) ---
if command -v trivy &>/dev/null; then
    run_tool "Trivy (filesystem)" \
        "trivy fs . --format json --scanners vuln,secret,misconfig --quiet 2>/dev/null || true" \
        "$OUT_DIR/trivy.json" \
        "Dependency CVEs, secrets, misconfigurations"
fi

# ============================================================
# RUST
# ============================================================
if [ -f "Cargo.toml" ]; then
    echo "" >> "$SUMMARY_FILE"
    echo "## Rust" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"

    # cargo audit
    if command -v cargo-audit &>/dev/null || cargo audit --version &>/dev/null 2>&1; then
        run_tool "cargo audit" \
            "cargo audit --json 2>/dev/null || true" \
            "$OUT_DIR/cargo-audit.json" \
            "Known vulnerabilities in Cargo dependencies (RustSec)"
    fi

    # cargo clippy (JSON diagnostics)
    if command -v cargo &>/dev/null; then
        run_tool "cargo clippy" \
            "cargo clippy --message-format=json --quiet -- -W clippy::pedantic -W clippy::nursery 2>/dev/null || true" \
            "$OUT_DIR/cargo-clippy.json" \
            "Lints: correctness, performance, style, complexity"
    fi

    # cargo deny
    if command -v cargo-deny &>/dev/null || cargo deny --version &>/dev/null 2>&1; then
        run_tool "cargo deny" \
            "cargo deny check --format json 2>/dev/null || true" \
            "$OUT_DIR/cargo-deny.json" \
            "License compliance, banned crates, duplicate deps"
    fi

    # cargo geiger (unsafe usage — text output, no JSON)
    if command -v cargo-geiger &>/dev/null || cargo geiger --version &>/dev/null 2>&1; then
        run_tool "cargo geiger" \
            "cargo geiger --output-format ascii 2>/dev/null || true" \
            "$OUT_DIR/cargo-geiger.txt" \
            "Unsafe code usage analysis"
    fi

    # cargo machete (unused deps)
    if command -v cargo-machete &>/dev/null; then
        run_tool "cargo machete" \
            "cargo machete 2>/dev/null || true" \
            "$OUT_DIR/cargo-machete.txt" \
            "Unused dependencies"
    fi
fi

# ============================================================
# RUBY / RAILS
# ============================================================
if [ -f "Gemfile" ]; then
    echo "" >> "$SUMMARY_FILE"
    echo "## Ruby" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"

    # Brakeman (Rails SAST)
    if command -v brakeman &>/dev/null; then
        run_tool "Brakeman" \
            "brakeman -f json --quiet --no-pager 2>/dev/null || true" \
            "$OUT_DIR/brakeman.json" \
            "Rails security: SQL injection, XSS, mass assignment"
    fi

    # bundler-audit
    if command -v bundler-audit &>/dev/null || bundle exec bundler-audit --version &>/dev/null 2>&1; then
        run_tool "bundler-audit" \
            "bundle exec bundler-audit check --format json 2>/dev/null || bundle audit check --format json 2>/dev/null || true" \
            "$OUT_DIR/bundler-audit.json" \
            "Known vulnerabilities in Ruby gems"
    fi

    # RuboCop
    if command -v rubocop &>/dev/null; then
        run_tool "RuboCop" \
            "rubocop --format json 2>/dev/null || true" \
            "$OUT_DIR/rubocop.json" \
            "Code quality, style, complexity"
    fi
fi

# ============================================================
# PYTHON
# ============================================================
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "Pipfile" ]; then
    echo "" >> "$SUMMARY_FILE"
    echo "## Python" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"

    # Bandit (Python SAST)
    if command -v bandit &>/dev/null; then
        run_tool "Bandit" \
            "bandit -r . -f json --exclude .venv,venv,node_modules,.git 2>/dev/null || true" \
            "$OUT_DIR/bandit.json" \
            "Python security: hardcoded passwords, injection, unsafe functions"
    fi

    # pip-audit
    if command -v pip-audit &>/dev/null; then
        run_tool "pip-audit" \
            "pip-audit --format json 2>/dev/null || true" \
            "$OUT_DIR/pip-audit.json" \
            "Known vulnerabilities in Python packages"
    fi
fi

# ============================================================
# JAVASCRIPT / TYPESCRIPT
# ============================================================
if [ -f "package.json" ]; then
    echo "" >> "$SUMMARY_FILE"
    echo "## JavaScript / TypeScript" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"

    # npm audit
    if command -v npm &>/dev/null; then
        run_tool "npm audit" \
            "npm audit --json 2>/dev/null || true" \
            "$OUT_DIR/npm-audit.json" \
            "Known vulnerabilities in npm packages"
    fi

    # ESLint (with security plugin if available)
    if command -v npx &>/dev/null && [ -f ".eslintrc" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ]; then
        run_tool "ESLint" \
            "npx eslint . --format json --quiet 2>/dev/null || true" \
            "$OUT_DIR/eslint.json" \
            "Code quality and security linting"
    fi
fi

# ============================================================
# PHP
# ============================================================
if [ -f "composer.json" ]; then
    echo "" >> "$SUMMARY_FILE"
    echo "## PHP" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"

    # PHPStan
    if command -v phpstan &>/dev/null || [ -f "vendor/bin/phpstan" ]; then
        PHPSTAN_CMD="phpstan"
        [ -f "vendor/bin/phpstan" ] && PHPSTAN_CMD="./vendor/bin/phpstan"
        run_tool "PHPStan" \
            "$PHPSTAN_CMD analyse --error-format=json --no-progress 2>/dev/null || true" \
            "$OUT_DIR/phpstan.json" \
            "Static analysis for PHP"
    fi

    # Composer audit (built-in since Composer 2.4)
    if command -v composer &>/dev/null; then
        run_tool "Composer audit" \
            "composer audit --format=json 2>/dev/null || true" \
            "$OUT_DIR/composer-audit.json" \
            "Known vulnerabilities in PHP packages"
    fi

    # PHP-CS-Fixer (dry-run check)
    if command -v php-cs-fixer &>/dev/null || [ -f "vendor/bin/php-cs-fixer" ]; then
        FIXER_CMD="php-cs-fixer"
        [ -f "vendor/bin/php-cs-fixer" ] && FIXER_CMD="./vendor/bin/php-cs-fixer"
        run_tool "PHP-CS-Fixer" \
            "$FIXER_CMD fix --dry-run --format=json 2>/dev/null || true" \
            "$OUT_DIR/php-cs-fixer.json" \
            "Code style and formatting issues"
    fi
fi

# ============================================================
# DOCKER / INFRASTRUCTURE
# ============================================================
if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    echo "" >> "$SUMMARY_FILE"
    echo "## Docker / Infrastructure" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"

    # Hadolint (Dockerfile linter)
    if command -v hadolint &>/dev/null; then
        run_tool "Hadolint" \
            "hadolint --format json Dockerfile 2>/dev/null || true" \
            "$OUT_DIR/hadolint.json" \
            "Dockerfile best practices and security"
    fi
fi

# ============================================================
# SUMMARY
# ============================================================
echo "" >> "$SUMMARY_FILE"
echo "---" >> "$SUMMARY_FILE"
echo "**Tools run:** $TOOLS_RUN | **With findings:** $TOOLS_FAILED" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

if [ $TOOLS_RUN -eq 0 ]; then
    echo "⚠️  No scanners found. Install tools for your stack:" >> "$SUMMARY_FILE"
    echo "- Multi-language: \`pip install semgrep\`, \`brew install gitleaks trivy\`" >> "$SUMMARY_FILE"
    echo "- Rust: \`cargo install cargo-audit cargo-deny cargo-machete\`" >> "$SUMMARY_FILE"
    echo "- Ruby: \`gem install brakeman bundler-audit\`" >> "$SUMMARY_FILE"
    echo "- Python: \`pip install bandit pip-audit\`" >> "$SUMMARY_FILE"
    echo "- JS/TS: \`npm audit\` (built-in), \`npm i -D eslint eslint-plugin-security\`" >> "$SUMMARY_FILE"
    echo ""
    echo "⚠️  No scanners installed. See $SUMMARY_FILE for install instructions."
else
    echo ""
    echo "✅ Scan complete: $TOOLS_RUN tools run, $TOOLS_FAILED with findings"
    echo "📄 Summary: $SUMMARY_FILE"
    echo "📁 Reports: $OUT_DIR/"
fi
