# Platform matrix

| Layer | macOS (Mac Mini) | Linux | Windows |
|---|---|---|---|
| L1 rtk | Full (brew, hook) | Full (binary/cargo, hook) | Degraded natively — hook needs a Unix shell, falls back to instruction-injection. Use WSL for full support. |
| L2 token-savior | pip, full | pip, full | pip works; run under WSL if pairing with rtk |
| L3 code-review-graph | pip, full | pip, full | pip, verify MCP config paths |
| L3 graphify | pip, full | pip, full | Python 3.10+, verify skill install path |
| L4 style plugin | Full | Full | Full (plugin marketplace) |
| L5 claude-token-optimizer | npx, full | npx, full | npx, full |

## Rules of thumb

- Production deploys live on the Mac Mini → treat it as the reference machine;
  benchmark there first.
- Windows: default to WSL for the whole stack. Native Windows gets L4/L5 only
  reliably; L1 degrades to advisory mode.
- Per-repo artifacts (L5 doc structure, graph build config) travel with the
  repo; graph CACHES rebuild locally on each machine (gitignored).
