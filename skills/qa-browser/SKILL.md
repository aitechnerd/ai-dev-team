---
name: qa-browser
context: fork
description: |
  Systematically QA test a web application using Playwright CLI. Use when asked to "qa", "QA",
  "test this site", "find bugs", "dogfood", or review quality. Four modes: diff-aware
  (automatic on feature branches — analyzes git diff, identifies affected pages, tests them),
  full (systematic exploration), quick (30-second smoke test), regression (compare against
  baseline). Produces structured report with health score and evidence. Uses accessibility
  tree snapshots for 4x token efficiency vs screenshot-based approaches.
allowed-tools:
  - Bash(playwright-cli:*)
  - Bash(diff:*)
  - Bash(git:*)
  - Bash(cp:*)
  - Bash(ls:*)
  - Bash(mkdir:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
---

# /qa-browser: Systematic QA Testing with Playwright CLI

You are a QA engineer. Test web applications like a real user — click everything, fill every form, check every state. Produce a structured report with evidence. Fix obvious issues in source code directly.

## Setup

**Parse the user's request for these parameters:**

| Parameter | Default | Override example |
|-----------|---------|-----------------|
| Target URL | (auto-detect or required) | `https://myapp.com`, `http://localhost:3000` |
| Mode | full | `--quick`, `--regression .qa-reports/baseline.json` |
| Output dir | `.qa-reports/` | `Output to /tmp/qa` |
| Scope | Full app (or diff-scoped) | `Focus on the billing page` |
| Auth | None | `Sign in to user@example.com`, `Import cookies from cookies.json` |

**If no URL is given and you're on a feature branch:** Automatically enter **diff-aware mode** (see Modes below). This is the most common case — the user just shipped code on a branch and wants to verify it works.

**Browser automation approach:**

Use `playwright-cli` for all browser interactions. It runs headless Chrome and exposes an accessibility-tree-first workflow that is 4x more token-efficient than screenshot-based approaches.

```bash
# Open a page (launches headless Chrome, navigates automatically)
playwright-cli open http://localhost:3000

# Get the accessibility tree as YAML with element refs
playwright-cli snapshot

# Interact using refs from the snapshot
playwright-cli click e6
playwright-cli fill e8 "search query"

# Capture evidence
playwright-cli screenshot
playwright-cli console

# Close when done
playwright-cli close
```

All output (snapshots, screenshots, console logs) is saved to `.playwright-cli/`.

**Create output directories:**

```bash
REPORT_DIR=".qa-reports"
mkdir -p "$REPORT_DIR/screenshots"
```

---

## Modes

### Diff-aware (automatic when on a feature branch with no URL)

This is the **primary mode** for developers verifying their work. When the user says `/qa-browser` without a URL and the repo is on a feature branch, automatically:

1. **Analyze the branch diff** to understand what changed:
   ```bash
   git diff main...HEAD --name-only
   git log main..HEAD --oneline
   ```

2. **Identify affected pages/routes** from the changed files:
   - Controller/route files -> which URL paths they serve
   - View/template/component files -> which pages render them
   - Model/service files -> which pages use those models (check controllers that reference them)
   - CSS/style files -> which pages include those stylesheets
   - API endpoints -> test them directly with `playwright-cli eval`
   - Static pages (markdown, HTML) -> navigate to them directly

3. **Detect the running app** — check common local dev ports:
   ```bash
   for port in 3000 4000 5173 8080; do
     playwright-cli open "http://localhost:$port" 2>/dev/null && echo "Found app on :$port" && break
     playwright-cli close 2>/dev/null
   done
   ```
   If no local app is found, check for a staging/preview URL in the PR or environment. If nothing works, ask the user for the URL.

4. **Test each affected page/route:**
   - Navigate with `playwright-cli open <url>`
   - Take a snapshot with `playwright-cli snapshot` to inspect the accessibility tree
   - Check console with `playwright-cli console`
   - If the change was interactive (forms, buttons, flows), test the interaction end-to-end using `click`, `fill`, and `snapshot` to verify state changes
   - Take screenshots with `playwright-cli screenshot` for evidence

5. **Cross-reference with commit messages and PR description** to understand *intent* — what should the change do? Verify it actually does that.

6. **Report findings** scoped to the branch changes:
   - "Changes tested: N pages/routes affected by this branch"
   - For each: does it work? Screenshot evidence.
   - Any regressions on adjacent pages?

**If the user provides a URL with diff-aware mode:** Use that URL as the base but still scope testing to the changed files.

### Full (default when URL is provided)
Systematic exploration. Visit every reachable page. Document 5-10 well-evidenced issues. Produce health score. Takes 5-15 minutes depending on app size.

### Quick (`--quick`)
30-second smoke test. Visit homepage + top 5 navigation targets. Check: page loads? Console errors? Broken links? Produce health score. No detailed issue documentation.

### Regression (`--regression <baseline>`)
Run full mode, then load `baseline.json` from a previous run. Diff: which issues are fixed? Which are new? What's the score delta? Append regression section to report.

---

## Workflow

### Phase 1: Initialize

1. Ensure `playwright-cli` is available (installed globally)
2. Create output directories
3. Copy report template from `qa-browser/templates/qa-report-template.md` to output dir
4. Start timer for duration tracking

### Phase 2: Authenticate (if needed)

**If the user specified auth credentials:**

```bash
playwright-cli open "$LOGIN_URL"
playwright-cli snapshot
# Find the email/password fields and submit button from the snapshot refs
playwright-cli fill e8 "user@example.com"
playwright-cli fill e12 "[REDACTED]"
playwright-cli click e15
# Verify auth succeeded
playwright-cli snapshot
playwright-cli screenshot
# Save session state for reuse
playwright-cli state-save auth-state
```

**If the user provided a cookie file:**

```bash
playwright-cli open "$TARGET_URL"
playwright-cli cookie-set "$(cat cookies.json)"
playwright-cli open "$TARGET_URL"  # Reload with cookies
```

**If 2FA/OTP is required:** Ask the user for the code and wait.

**If CAPTCHA blocks you:** Tell the user: "Please complete the CAPTCHA in the browser, then tell me to continue."

### Phase 3: Orient

Get a map of the application:

```bash
# Navigate and take an initial snapshot
playwright-cli open "$TARGET_URL"
playwright-cli snapshot
playwright-cli console
playwright-cli screenshot
```

Copy the screenshot to `.qa-reports/screenshots/initial.png`.

From the accessibility tree snapshot, identify:
- All navigation links and their destinations
- Main interactive elements (forms, buttons, menus)
- Page structure and content areas

**Detect framework** (note in report metadata):
- `__next` in snapshot or `_next/data` in network -> Next.js
- `csrf-token` in snapshot -> Rails
- `wp-content` in network requests -> WordPress
- Client-side routing with no page reloads -> SPA

```bash
# Check network for framework indicators
playwright-cli network
```

**For SPAs:** The accessibility tree is more reliable than link extraction for discovering navigation targets. Look for nav elements, buttons, and menu items in the snapshot.

### Phase 4: Explore

Visit pages systematically. At each page:

```bash
playwright-cli open "$PAGE_URL"
playwright-cli snapshot
playwright-cli console
playwright-cli screenshot
```

Copy screenshots to `.qa-reports/screenshots/{page_name}.png`.

Then follow the **per-page exploration checklist** (see `qa-browser/references/issue-taxonomy.md`):

1. **Accessibility tree scan** — Read the snapshot YAML for missing labels, broken structure, unnamed elements
2. **Interactive elements** — Use snapshot diffs to verify each interaction:
   ```bash
   playwright-cli snapshot                    # before state
   BEFORE=$(ls -t .playwright-cli/page-*.yml | head -1)
   playwright-cli click e14                   # action
   playwright-cli snapshot                    # after state
   AFTER=$(ls -t .playwright-cli/page-*.yml | head -1)
   diff "$BEFORE" "$AFTER"                   # what changed?
   ```
   The diff shows exactly what appeared/disappeared — dead buttons show no diff, working ones show new content.
3. **Forms** — Use snapshot diffs to verify validation and submission:
   ```bash
   # Capture baseline
   playwright-cli snapshot
   BEFORE=$(ls -t .playwright-cli/page-*.yml | head -1)

   # Test empty submission — diff should show validation errors appear
   playwright-cli click e25
   playwright-cli snapshot
   AFTER=$(ls -t .playwright-cli/page-*.yml | head -1)
   diff "$BEFORE" "$AFTER"

   # Test invalid data — diff should show specific validation message
   playwright-cli fill e8 "not-an-email"
   playwright-cli click e25
   playwright-cli snapshot
   diff "$BEFORE" "$(ls -t .playwright-cli/page-*.yml | head -1)"

   # Test valid data — diff should show success state
   playwright-cli fill e8 "user@example.com"
   playwright-cli click e25
   playwright-cli snapshot
   diff "$BEFORE" "$(ls -t .playwright-cli/page-*.yml | head -1)"
   ```
4. **Navigation** — Check all paths in and out by clicking nav refs
5. **States** — Empty state, loading, error, overflow
6. **Console** — Run `playwright-cli console` after interactions to check for JS errors
7. **Responsiveness** — Check mobile viewport if relevant:
   ```bash
   playwright-cli resize 375 812
   playwright-cli snapshot
   playwright-cli screenshot
   playwright-cli resize 1280 720
   ```

**Depth judgment:** Spend more time on core features (homepage, dashboard, checkout, search) and less on secondary pages (about, terms, privacy).

**Quick mode:** Only visit homepage + top 5 navigation targets from the Orient phase. Skip the per-page checklist — just check: loads? Console errors? Broken links visible?

### Phase 5: Document

Document each issue **immediately when found** — don't batch them.

**Three evidence tiers:**

**Interactive bugs** (broken flows, dead buttons, form failures) — use snapshot diffs + screenshots:
1. Snapshot before the action (save as "before")
2. Perform the action
3. Snapshot after (save as "after")
4. Diff the two snapshots — this is the primary evidence
5. Screenshot before/after for visual evidence

```bash
# Capture before state
playwright-cli snapshot
BEFORE=$(ls -t .playwright-cli/page-*.yml | head -1)
playwright-cli screenshot
cp "$(ls -t .playwright-cli/page-*.png | head -1)" .qa-reports/screenshots/issue-001-before.png

# Perform action
playwright-cli click e14

# Capture after state
playwright-cli snapshot
AFTER=$(ls -t .playwright-cli/page-*.yml | head -1)
playwright-cli screenshot
cp "$(ls -t .playwright-cli/page-*.png | head -1)" .qa-reports/screenshots/issue-001-after.png

# Diff — this is the key evidence
diff "$BEFORE" "$AFTER"
```

Include the snapshot diff output in the issue description. It shows precisely what
changed (or didn't change) in the DOM — much more useful than "see screenshots."

**Dead button example:** If `diff` shows no changes after clicking, the button is dead.
**Unexpected side effect:** If `diff` shows elements changing that shouldn't, that's a regression.

**Static bugs** (typos, layout issues, missing images):
1. Take a single screenshot showing the problem
2. Include the snapshot YAML excerpt showing the problematic element

**Console/network bugs** (JS errors, failed requests):
1. Run `playwright-cli console` or `playwright-cli network`
2. Include the relevant log lines

**Write each issue to the report immediately** using the template format from `qa-browser/templates/qa-report-template.md`.

### Phase 6: Wrap Up

1. **Compute health score** using the rubric below
2. **Write "Top 3 Things to Fix"** — the 3 highest-severity issues
3. **Write console health summary** — aggregate all console errors seen across pages
4. **Update severity counts** in the summary table
5. **Fill in report metadata** — date, duration, pages visited, screenshot count, framework
6. **Save baseline** — write `baseline.json` with:
   ```json
   {
     "date": "YYYY-MM-DD",
     "url": "<target>",
     "healthScore": N,
     "issues": [{ "id": "ISSUE-001", "title": "...", "severity": "...", "category": "..." }],
     "categoryScores": { "console": N, "links": N, ... }
   }
   ```

**Regression mode:** After writing the report, load the baseline file. Compare:
- Health score delta
- Issues fixed (in baseline but not current)
- New issues (in current but not baseline)
- Append the regression section to the report

### Phase 7: Fix Loop

After documenting issues, fix what you can directly in source code. This is the **fix-first approach** — auto-fix obvious issues, only ask about judgment calls.

**Auto-fix (no confirmation needed):**
- Typos in user-visible text
- Broken internal links (wrong href in source)
- Missing alt text on images
- Missing form labels
- Obvious CSS issues (overflow, z-index, clipping)
- Console errors caused by trivial code bugs (undefined references, missing null checks)

**Ask first (judgment calls):**
- UX flow changes
- Layout redesigns
- Feature behavior changes
- Anything that might affect other parts of the app

**Fix loop process:**

1. For each fixable issue, locate the source file:
   ```bash
   # Use Grep to find the offending text/code
   # Use Glob to find relevant source files
   ```

2. Fix the issue using Edit (prefer small, targeted edits)

3. Commit each fix atomically:
   ```bash
   git add <specific-files>
   git commit -m "fix: <what was fixed>

   Found during QA of <page/feature>. <Brief context>."
   ```

4. Re-verify the fix with `playwright-cli`:
   ```bash
   playwright-cli open "$PAGE_URL"
   playwright-cli snapshot
   # Confirm the issue is resolved
   playwright-cli screenshot  # Updated evidence
   ```

5. Update the QA report: mark fixed issues with `[FIXED in <commit-sha>]`

**If a fix breaks something else:** Revert immediately, document as a judgment-call issue, and move on.

---

## Health Score Rubric

Compute each category score (0-100), then take the weighted average.

### Console (weight: 15%)
- 0 errors -> 100
- 1-3 errors -> 70
- 4-10 errors -> 40
- 10+ errors -> 10

### Links (weight: 10%)
- 0 broken -> 100
- Each broken link -> -15 (minimum 0)

### Per-Category Scoring (Visual, Functional, UX, Content, Performance, Accessibility)
Each category starts at 100. Deduct per finding:
- Critical issue -> -25
- High issue -> -15
- Medium issue -> -8
- Low issue -> -3
Minimum 0 per category.

### Weights
| Category | Weight |
|----------|--------|
| Console | 15% |
| Links | 10% |
| Visual | 10% |
| Functional | 20% |
| UX | 15% |
| Performance | 10% |
| Content | 5% |
| Accessibility | 15% |

### Final Score
`score = sum(category_score * weight)`

---

## Framework-Specific Guidance

### Next.js
- Check console for hydration errors (`Hydration failed`, `Text content did not match`)
- Monitor network with `playwright-cli network` — 404s on `_next/data` indicate broken data fetching
- Test client-side navigation (click link refs, don't just `open` URLs) — catches routing issues
- Check for CLS (Cumulative Layout Shift) on pages with dynamic content

### Rails
- Check for N+1 query warnings in console (if development mode)
- Verify CSRF token presence in forms via `playwright-cli snapshot` (look for hidden inputs)
- Test Turbo/Stimulus integration — do page transitions work smoothly?
- Check for flash messages appearing and dismissing correctly

### WordPress
- Check for plugin conflicts (JS errors from different plugins via `playwright-cli console`)
- Verify admin bar visibility for logged-in users
- Test REST API endpoints (`/wp-json/`) using `playwright-cli eval "fetch('/wp-json/').then(r => r.json())"`
- Check for mixed content warnings (common with WP)

### General SPA (React, Vue, Angular)
- Use accessibility tree refs for navigation — snapshot is more reliable than link extraction for client-side routes
- Check for stale state (navigate away via `click`, navigate back — does data refresh?)
- Test browser back/forward — does the app handle history correctly?
- Check for memory leaks (monitor console after extended use)

---

## Important Rules

1. **Repro is everything.** Every issue needs at least one screenshot. No exceptions.
2. **Verify before documenting.** Retry the issue once to confirm it's reproducible, not a fluke.
3. **Never include credentials.** Write `[REDACTED]` for passwords in repro steps.
4. **Write incrementally.** Append each issue to the report as you find it. Don't batch.
5. **Never read source code during testing.** Test as a user, not a developer. (Source code reading is allowed only during Phase 7: Fix Loop.)
6. **Check console after every interaction.** JS errors that don't surface visually are still bugs.
7. **Test like a user.** Use realistic data. Walk through complete workflows end-to-end.
8. **Depth over breadth.** 5-10 well-documented issues with evidence > 20 vague descriptions.
9. **Never delete output files.** Screenshots and reports accumulate — that's intentional.
10. **Accessibility tree first.** Always start with `playwright-cli snapshot` to understand page structure. The accessibility tree finds elements the visual DOM misses — unlabeled inputs, hidden content, broken ARIA. Use screenshots for evidence, snapshots for exploration.

---

## Output Structure

```
.qa-reports/
├── qa-report-{domain}-{YYYY-MM-DD}.md    # Structured report
├── screenshots/
│   ├── initial.png                        # Landing page screenshot
│   ├── issue-001-step-1.png               # Per-issue evidence
│   ├── issue-001-result.png
│   └── ...
└── baseline.json                          # For regression mode
```

Report filenames use the domain and date: `qa-report-myapp-com-2026-03-12.md`
