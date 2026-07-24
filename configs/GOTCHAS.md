# Known gotchas (collected from tool docs and practitioner reports)

## rtk

- Name collision: crates.io has an unrelated "rtk" (Rust Type Kit). Test with
  `rtk gain` — if it fails but `rtk --version` works, wrong package. Fix:
  `cargo install --git https://github.com/rtk-ai/rtk`.
- Hook ordering: if other PreToolUse hooks match `Bash` (context injection,
  wakatime, etc.), rtk's hook must be the LAST entry in the hooks array, or an
  earlier hook that mishandles stdin starves it.
- Subagent gap: PreToolUse hooks do not fire for agents spawned via the Agent
  tool — only the main session gets rewrites. Budget for that in measurements.
- Coverage gap: only the Bash tool is hooked. Claude Code built-ins (Read,
  Grep, Glob) bypass rtk entirely — that traffic belongs to L2/L3.

## MCP layers (token-savior / ooples)

- Tool schemas are injected every turn. ooples ships 74 tools; count that as
  standing overhead in benchmarks. token-savior's single profile is leaner.
- Never run both — duplicate bash-compaction + read-caching confuses the agent
  and doubles schema cost.
- token-savior bash compaction overlaps rtk. If both installed, disable one
  side's bash handling.

## Style plugins (L4)

- Exactly one. Stacked style files conflict and each costs input every turn.
- Terse styles can backfire on heavy reasoning models (thinking tokens spent
  deliberating the rules) — ponytail's own benchmarks note this. Measure.
- drona23's file warns about itself: if the instruction file grows, it can
  cost more than it saves.

## L5 (claude-token-optimizer)

- Re-run after major doc churn; stale lazy-load indexes quietly rot.

## General

- Restart Claude Code after ANY MCP/plugin/hook change.
- Verify live layers with /mcp (servers connected) and /hooks where available.
