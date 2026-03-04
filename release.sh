#!/bin/bash
set -e

# Release script — creates a GitHub release and updates the Homebrew formula.
#
# Usage:
#   bash release.sh              # Release current VERSION
#   bash release.sh 2.2.0        # Release specific version
#
# Prerequisites:
#   - gh CLI installed and authenticated
#   - Homebrew tap repo cloned alongside this repo:
#     ~/homebrew-ai-dev-team/  (or set TAP_REPO env var)

VERSION="${1:-$(cat VERSION)}"
TAP_REPO="${TAP_REPO:-$HOME/homebrew-ai-dev-team}"
REPO_OWNER="aitechnerd"
REPO_NAME="ai-dev-team"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🚀 Releasing ai-dev-team v$VERSION"
echo "═══════════════════════════════════════"
echo ""

# Validate
if ! command -v gh &>/dev/null; then
    echo "❌ GitHub CLI (gh) required. Install: brew install gh"
    exit 1
fi

if [ ! -d "$TAP_REPO" ]; then
    echo "❌ Tap repo not found at $TAP_REPO"
    echo "   Clone it: gh repo clone $REPO_OWNER/homebrew-$REPO_NAME $TAP_REPO"
    exit 1
fi

# Update VERSION file
echo "$VERSION" > VERSION
echo -e "${GREEN}✅${NC} VERSION set to $VERSION"

# Commit, tag, push
git add -A
git commit -m "v$VERSION" --allow-empty
git tag -a "v$VERSION" -m "Release v$VERSION"
git push origin main --tags
echo -e "${GREEN}✅${NC} Tagged and pushed v$VERSION"

# Create GitHub release
gh release create "v$VERSION" \
    --title "v$VERSION" \
    --notes "See [CHANGELOG.md](https://github.com/$REPO_OWNER/$REPO_NAME/blob/main/CHANGELOG.md) for details." \
    --latest
echo -e "${GREEN}✅${NC} GitHub release created"

# Get the tarball SHA256
echo ""
echo "Calculating SHA256..."
TARBALL_URL="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/tags/v$VERSION.tar.gz"
SHA256=$(curl -sL "$TARBALL_URL" | shasum -a 256 | cut -d' ' -f1)
echo -e "${GREEN}✅${NC} SHA256: $SHA256"

# Update formula
FORMULA="$TAP_REPO/ai-dev-team.rb"
if [ -f "$FORMULA" ]; then
    # Update URL
    sed -i.bak "s|archive/refs/tags/v[0-9.]*\.tar\.gz|archive/refs/tags/v$VERSION.tar.gz|" "$FORMULA"
    # Update SHA256
    sed -i.bak "s|sha256 \"[a-f0-9]*\"|sha256 \"$SHA256\"|" "$FORMULA"
    rm -f "$FORMULA.bak"
    echo -e "${GREEN}✅${NC} Formula updated"

    # Commit and push tap
    cd "$TAP_REPO"
    git add -A
    git commit -m "ai-dev-team v$VERSION"
    git push origin main
    echo -e "${GREEN}✅${NC} Tap repo pushed"
else
    echo -e "${YELLOW}⚠️${NC}  Formula not found at $FORMULA"
    echo "   Update manually with SHA256: $SHA256"
fi

echo ""
echo "═══════════════════════════════════════"
echo -e "${GREEN}Done!${NC} Users can now run:"
echo "  brew upgrade ai-dev-team"
echo "  ai-team update"
