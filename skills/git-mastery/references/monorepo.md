# Monorepo Git Patterns

## Sparse Checkout — Work With a Subset

```bash
# Enable sparse checkout
git sparse-checkout init --cone

# Only check out specific directories
git sparse-checkout set packages/frontend packages/shared

# Add more directories later
git sparse-checkout add packages/backend

# Disable (check out everything)
git sparse-checkout disable
```

## Multi-Package Repository Structure

```
monorepo/
├── packages/
│   ├── frontend/       ← package.json, src/
│   ├── backend/        ← package.json, src/
│   └── shared/         ← package.json, src/
├── package.json        ← workspace root
└── .github/
    └── workflows/
        ├── frontend.yml    ← only runs on packages/frontend changes
        └── backend.yml     ← only runs on packages/backend changes
```

## Detecting Changes per Package

```bash
# Files changed between branches
git diff main --name-only

# Filter to specific package
git diff main --name-only -- packages/frontend/

# Changed packages (for CI)
git diff main --name-only | cut -d/ -f1-2 | sort -u
```

## Git Subtree vs Submodule

| Aspect | Subtree | Submodule |
|--------|---------|-----------|
| Simplicity | Simpler for consumers | Requires init/update |
| History | Merged into main repo | Separate repo reference |
| Updates | Pull/push commands | Update + commit pointer |
| Best for | Vendoring, small deps | Large independent repos |

### Submodule Commands
```bash
# Add submodule
git submodule add https://github.com/org/lib.git vendor/lib

# Clone repo with submodules
git clone --recurse-submodules <url>

# Update submodules
git submodule update --remote --merge

# Remove submodule
git submodule deinit vendor/lib
git rm vendor/lib
rm -rf .git/modules/vendor/lib
```

## CODEOWNERS

```
# .github/CODEOWNERS
packages/frontend/     @frontend-team
packages/backend/      @backend-team
packages/shared/       @platform-team
*.md                   @docs-team
.github/               @devops-team
```

## Tagging in Monorepos

```bash
# Package-scoped tags
git tag frontend-v1.2.0
git tag backend-v3.1.0

# Push specific tag
git push origin frontend-v1.2.0

# List tags for a package
git tag -l "frontend-v*"
```
