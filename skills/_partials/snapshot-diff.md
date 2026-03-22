### Snapshot Diff (Before/After Evidence)

Capture what changed in the accessibility tree after an action:

```bash
# 1. Take "before" snapshot
playwright-cli snapshot
BEFORE=$(ls -t .playwright-cli/page-*.yml | head -1)

# 2. Perform the action
playwright-cli click e8

# 3. Take "after" snapshot
playwright-cli snapshot
AFTER=$(ls -t .playwright-cli/page-*.yml | head -1)

# 4. Diff the two snapshots
diff "$BEFORE" "$AFTER"
```

This shows exactly what appeared, disappeared, or changed in the DOM — much more
precise than comparing screenshots. Use for:
- Verifying a button click produced the expected state change
- Confirming form submission updated the page
- Detecting unintended side effects (elements that changed when they shouldn't)
- Before/after evidence in QA reports

**Dead button:** If `diff` shows no changes after clicking, the button is dead.
**Unexpected side effect:** If `diff` shows elements changing that shouldn't, that's a regression.
