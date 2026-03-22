---
name: browse
description: |
  General-purpose browser automation using Playwright CLI. Navigate pages, interact with
  elements via accessibility refs, take screenshots, manage sessions, mock network requests.
  Use for ad-hoc browsing, system automations, deploy verification, form filling, data extraction.
  Much faster and cheaper than screenshot-based approaches — uses YAML accessibility snapshots.
allowed-tools:
  - Bash(playwright-cli:*)
  - Bash(diff:*)
  - Bash(cp:*)
  - Bash(ls:*)
  - Read
---

# Browse: Browser Automation with Playwright CLI

General-purpose browser automation via `playwright-cli`. Uses accessibility tree snapshots
(YAML with element refs) instead of screenshots for fast, cheap interaction.

## Core Workflow

```
open URL  ->  snapshot  ->  interact (click/fill/etc)  ->  snapshot  ->  ...  ->  close
```

Every interaction follows this loop:

1. **Open** a page: `playwright-cli open https://example.com`
2. **Snapshot** to see the page structure: `playwright-cli snapshot`
3. **Read the snapshot** YAML to find element refs (e8, e21, etc.)
4. **Interact** using refs: `playwright-cli click e8` or `playwright-cli fill e12 "hello"`
5. **Snapshot again** to verify the result
6. **Close** when done: `playwright-cli close`

## Element Refs

Snapshots produce YAML files in `.playwright-cli/` with an accessibility tree. Each
interactive element gets a ref like `e8`, `e21`, `e134`. Use these refs for all interactions.

```bash
# Take snapshot — returns path to YAML file
playwright-cli snapshot

# Read the YAML to find elements
# (only read when you need to find refs — don't read after every action)
```

Example snapshot excerpt:
```yaml
- button "Sign In" [ref=e8]
- textbox "Email" [ref=e12]
- textbox "Password" [ref=e14]
- link "Forgot password?" [ref=e16]
```

Use refs directly: `playwright-cli click e8`, `playwright-cli fill e12 "user@example.com"`

## Common Patterns

### Navigation

```bash
playwright-cli open https://example.com       # Open URL in new browser
playwright-cli goto https://example.com/about  # Navigate existing browser
playwright-cli go-back                         # Browser back
playwright-cli go-forward                      # Browser forward
playwright-cli reload                          # Refresh page
```

### Form Filling

```bash
playwright-cli snapshot                        # Find form element refs
playwright-cli fill e12 "user@example.com"     # Fill text input
playwright-cli fill e14 "password123"          # Fill password
playwright-cli select e18 "option-value"       # Select dropdown
playwright-cli check e20                       # Check checkbox
playwright-cli uncheck e20                     # Uncheck checkbox
playwright-cli click e8                        # Submit button
playwright-cli snapshot                        # Verify result
```

### Data Extraction

```bash
playwright-cli snapshot                        # Capture page structure
# Read the YAML — all visible text content is in the accessibility tree
# For dynamic data, use eval:
playwright-cli eval "document.querySelector('.price').textContent"
```

### Snapshot Diff (Before/After Evidence)

Capture what changed in the accessibility tree after an action:

```bash
# 1. Take "before" snapshot
playwright-cli snapshot
# Note the file path from output, e.g. .playwright-cli/page-...-before.yml

# 2. Perform the action
playwright-cli click e8

# 3. Take "after" snapshot
playwright-cli snapshot
# Note the file path, e.g. .playwright-cli/page-...-after.yml

# 4. Diff the two snapshots
diff .playwright-cli/page-*-before.yml .playwright-cli/page-*-after.yml
```

This shows exactly what appeared, disappeared, or changed in the DOM — much more
precise than comparing screenshots. Use for:
- Verifying a button click produced the expected state change
- Confirming form submission updated the page
- Detecting unintended side effects (elements that changed when they shouldn't)
- Before/after evidence in QA reports

**Tip:** For named diffs, copy snapshots to meaningful filenames:
```bash
playwright-cli snapshot
cp .playwright-cli/page-*.yml /tmp/before-login.yml
playwright-cli click e15  # submit login
playwright-cli snapshot
cp .playwright-cli/page-*.yml /tmp/after-login.yml
diff /tmp/before-login.yml /tmp/after-login.yml
```

### Screenshots and Visual Verification

```bash
playwright-cli screenshot                      # Full page screenshot
playwright-cli screenshot e42                  # Screenshot specific element
# Screenshots saved as PNG to .playwright-cli/
```

### Multi-Tab

```bash
playwright-cli tab-new https://other-page.com  # Open new tab
playwright-cli tab-list                         # List open tabs
playwright-cli tab-select 2                     # Switch to tab 2
playwright-cli tab-close                        # Close current tab
```

### Auth State (Save/Restore Sessions)

```bash
# Save authenticated state after login
playwright-cli state-save auth-state

# Restore it later (skips login flow)
playwright-cli state-load auth-state
```

### Named Sessions (Parallel Work)

```bash
# Run two browsers side-by-side
playwright-cli -s=admin open https://app.com/admin
playwright-cli -s=user open https://app.com/dashboard

# Each session is independent
playwright-cli -s=admin snapshot
playwright-cli -s=user snapshot

# Close individually
playwright-cli -s=admin close
playwright-cli -s=user close
```

### Network Mocking

```bash
# Mock an API endpoint
playwright-cli route "https://api.example.com/data" '{"status": "ok"}'

# List active routes
playwright-cli route-list

# Remove mock
playwright-cli unroute "https://api.example.com/data"
```

### Cookies and Storage

```bash
playwright-cli cookie-list                     # List all cookies
playwright-cli cookie-set name=val domain=.example.com
playwright-cli cookie-delete name
playwright-cli localstorage-get key
playwright-cli localstorage-set key value
```

## Efficiency Tips

- **Snapshot sparingly.** Only take a snapshot when you need to discover element refs.
  If you already know the ref from a previous snapshot, just use it.
- **Read snapshots lazily.** The snapshot command returns a file path. Only read the
  file when you need to find specific elements — don't read after every action.
- **Use eval for extraction.** When you need specific data that's easier to grab via
  JS than parsing the accessibility tree, use `playwright-cli eval`.
- **Screenshots are for humans.** Use them for visual verification or to show the user
  what a page looks like. For interaction, always prefer snapshots.
- **State save/load for auth.** If you need to log in repeatedly, save the state once
  and reload it. Much faster than re-authenticating.

## Output Directory

All output files go to `.playwright-cli/` in the working directory:
- Snapshots: YAML files with accessibility tree and element refs
- Screenshots: PNG files
- Console logs: .log files

**Add `.playwright-cli/` to `.gitignore`** — these are ephemeral working files.

## Quick Reference

| Action | Command |
|--------|---------|
| Open browser | `playwright-cli open <url>` |
| Navigate | `playwright-cli goto <url>` |
| Snapshot (a11y tree) | `playwright-cli snapshot` |
| Click element | `playwright-cli click <ref>` |
| Fill input | `playwright-cli fill <ref> "text"` |
| Select option | `playwright-cli select <ref> "value"` |
| Check/uncheck | `playwright-cli check <ref>` / `uncheck <ref>` |
| Press key | `playwright-cli press Enter` |
| Hover | `playwright-cli hover <ref>` |
| Screenshot | `playwright-cli screenshot [ref]` |
| Evaluate JS | `playwright-cli eval "expression"` |
| New tab | `playwright-cli tab-new <url>` |
| List tabs | `playwright-cli tab-list` |
| Switch tab | `playwright-cli tab-select <n>` |
| Save state | `playwright-cli state-save <name>` |
| Load state | `playwright-cli state-load <name>` |
| Mock route | `playwright-cli route "<url>" '<json>'` |
| Named session | `playwright-cli -s=<name> <command>` |
| Close browser | `playwright-cli close` |
| Close all | `playwright-cli close-all` |

## Debugging

```bash
playwright-cli console                         # View console output
playwright-cli network                         # View network requests
playwright-cli devtools-start                  # Open Chrome DevTools
playwright-cli tracing-start                   # Start trace recording
playwright-cli tracing-stop                    # Stop and save trace
```
