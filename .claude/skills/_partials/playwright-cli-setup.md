**Requires:** `playwright-cli` installed globally (`npm install -g @playwright/cli`).

All browser automation uses `playwright-cli` — fast, token-efficient, headless Chrome.
Output (snapshots, screenshots, logs) goes to `.playwright-cli/` in the working directory.

**Key commands:**
| Command | Purpose |
|---------|---------|
| `playwright-cli open <url>` | Open page in headless Chrome |
| `playwright-cli snapshot` | Get YAML accessibility tree with element refs |
| `playwright-cli click <ref>` | Click element by ref (e.g., `e8`) |
| `playwright-cli fill <ref> "text"` | Fill input field by ref |
| `playwright-cli screenshot [ref]` | Save screenshot PNG |
| `playwright-cli console` | View browser console logs |
| `playwright-cli network` | View network requests |
| `playwright-cli resize <w> <h>` | Set viewport size |
| `playwright-cli close` | Close browser session |

**Element refs:** Run `snapshot` to get a YAML tree. Each element has a ref like `e8`, `e21`.
Use refs with `click`, `fill`, and other action commands — no CSS selectors needed.

**Named sessions:** Use `-s=name` for parallel browser contexts (e.g., `-s=admin`, `-s=user`).
