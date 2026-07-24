# context-funnel

A measured, cross-platform token-reduction stack for Claude Code and other
coding agents. One tool per layer, benchmarked before the next layer goes in.

Not another install-everything stack. Every MCP server and instruction file
costs input tokens on every turn — this repo treats each layer as provisional
until `/cost` numbers prove it pays for itself.

## Quick start

```bash
./bootstrap.sh                          # global layers (rtk, MCP, retrieval)
./bootstrap.sh --repo /path/to/project  # per-repo setup (docs + graph build)
```

Then read `WORKFLOW.md` for the full layer model, alternates, and deployment
order. Log before/after numbers in `benchmarks/` using the template.

## Layout

- `WORKFLOW.md` — the 5-layer model, tool picks, alternates, rationale
- `bootstrap.sh` — installer (flags: `--style`, `--mcp`, `--repo`)
- `configs/` — known gotchas and config notes per tool
- `benchmarks/` — per-layer, per-machine `/cost` measurements
- `platform/` — macOS / Linux / Windows-WSL differences

## Philosophy

1. One tool per layer. Overlapping optimizers raise baseline burn.
2. Baseline first. No layer ships without a before/after number.
3. Local-first. No layer requires a cloud API key or hosted vector DB.
4. Reversible. Every layer documents its uninstall.
