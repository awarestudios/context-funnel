# Context & Token Reduction Workflow

A layered pipeline that cuts token consumption for Claude Code (and other agents)
using verified open-source tools. Every repo below was checked against its actual
README — descriptions here reflect what each tool really does, not marketing copy.

## The Golden Rule

**Do not install all 12 repos.** They cluster into 5 functional layers with heavy
overlap. Every MCP server adds its tool schemas to your context on every turn
(ooples/token-optimizer-mcp ships 74 tools), and every instruction file is
re-injected each session. Stacking overlapping optimizers *increases* your
baseline token burn. Pick **one tool per layer**.

```
 ┌─────────────────────────────────────────────────────────┐
 │ L5  Session/docs structure   nadimtuhin/claude-token-…  │  what loads at startup
 ├─────────────────────────────────────────────────────────┤
 │ L4  Output style             caveman | ponytail | drona │  how the agent talks
 ├─────────────────────────────────────────────────────────┤
 │ L3  Retrieval-not-reads      code-review-graph |        │  what enters context
 │                              graphify | claude-context  │
 ├─────────────────────────────────────────────────────────┤
 │ L2  Caching + structural nav token-savior | ooples MCP  │  repeated-read dedup
 ├─────────────────────────────────────────────────────────┤
 │ L1  Command-output compress  rtk  (+ headroom proxy)    │  raw tool output
 └─────────────────────────────────────────────────────────┘
```

---

## Layer 1 — Command Output Compression

**Pick: `rtk-ai/rtk`** (Rust CLI proxy, 60–90% reduction on tool output)

rtk wraps the commands your agent runs (`git`, `ls`, `cargo`, test runners) and
compresses their output before it ever reaches the context window.

```bash
brew install rtk        # macOS (your Mac Mini)
rtk init -g             # configures Claude Code globally
```

⚠️ Name collision: a different "rtk" (Rust Type Kit) exists on crates.io. If
`rtk gain` fails you installed the wrong one — use
`cargo install --git https://github.com/rtk-ai/rtk` instead.

**Optional add-on: `headroomlabs-ai/headroom`** — a message-stream compressor
that sits between the agent and the API. Complementary to rtk (rtk compresses
command output, headroom compresses the whole message payload):

```bash
uv tool install --python 3.13 "headroom-ai[all]"
headroom wrap claude      # one command; undo with: headroom unwrap claude
```

Run rtk for a week first, measure, then add headroom only if you still need more.

---

## Layer 2 — Caching & Structural Navigation (MCP)

**Pick ONE:**

| Tool | Stack | Strengths | Cost of admission |
|---|---|---|---|
| `Mibayy/token-savior` | Python 3.11+ | Single lean profile, structural code nav, bash compaction, 97.9% on tsbench at −80% tokens | Small tool schema |
| `ooples/token-optimizer-mcp` | Node 18+ | Cached payloads, diffs on repeated reads, savings reports, SQLite persistence | **74 tools** = large schema injected every turn |

**Recommendation: token-savior.** Its single-profile design means the MCP
overhead itself is small — which is the whole point of this exercise.

```bash
pip install "token-savior-recall[mcp]"
# then add to Claude Code MCP config (see bootstrap.sh)
```

If you prefer staying all-Node and want the diff-on-reread caching:

```bash
claude mcp add --transport stdio --scope user token-optimizer -- npx -y @ooples/token-optimizer-mcp@latest
```

Do **not** run both — overlapping bash-compaction and read-caching tools confuse
the agent and double the schema cost. Note L1 overlap too: token-savior's bash
compaction partially duplicates rtk. If you run rtk + token-savior, disable
token-savior's bash compaction feature if its config allows.

---

## Layer 3 — Retrieval Instead of File Reads

The biggest single win: stop `cat`-ing whole files into context.

**Pick based on need:**

- **`tirth8205/code-review-graph`** (pip, fully local) — parses your codebase
  into a graph; MCP tools like `get_impact_radius` and `get_review_context`
  return only the nodes relevant to a change. Best for your trading repos where
  reviews touch narrow slices of a large system.

  ```bash
  pip install code-review-graph
  code-review-graph install     # auto-configures Claude Code MCP + hooks
  code-review-graph build       # run inside each repo (phase-omega, etc.)
  ```

- **`Graphify-Labs/graphify`** (Claude Code skill, local, multimodal) — builds a
  knowledge graph of any folder (code, PDFs, notes, screenshots); claims 71.5×
  fewer tokens per query vs raw reads. Best for mixed research/notes folders.

  ```bash
  pip install graphifyy && graphify install
  # then in Claude Code:  /graphify .
  ```

- **`zilliztech/claude-context`** (semantic vector search MCP) — powerful, but
  requires an OpenAI API key for embeddings AND a Milvus/Zilliz Cloud vector DB.
  Skip unless you want semantic search across a very large codebase and accept
  the external dependencies — it conflicts with a local-first setup.

**Recommendation: code-review-graph for code repos + graphify for everything
else.** They coexist fine (different triggers: MCP tools vs `/graphify` skill).

---

## Layer 4 — Output Style (Terseness)

Four repos do the same job here. **Pick exactly ONE** — stacked style
instructions conflict and each file costs input tokens every turn.

| Tool | Approach | Claimed savings |
|---|---|---|
| `JuliusBrussee/caveman` | Plugin/rule file, 5 "grunt levels" | −65% output tokens |
| `DietrichGebert/ponytail` | Plugin + lifecycle hooks, "lazy senior dev" — minimal *code*, not golfed | 80–94% less code on some tasks (see their own caveats) |
| `drona23/claude-token-efficient` | One drop-in instruction file | modest; warns it can cost more than it saves if the file grows |
| `alexgreensh/token-optimizer` | Full Claude Code plugin (skills + OpenClaw integration) | varies |

**Recommendation: ponytail** for code-heavy work — its rule is "write only what
the task needs, never cut validation/error handling/security," which matters for
trading systems. Caveman if you want maximum terseness in chat responses too.

```bash
# ponytail (Claude Code plugin; needs node on non-interactive PATH for hooks)
# See repo INSTALL for the plugin marketplace command

# caveman alternative:
claude plugin marketplace add JuliusBrussee/caveman && claude plugin install caveman@caveman
```

⚠️ Ponytail's own docs note that terse styles can backfire on heavy reasoning
models (thinking tokens deliberating the rules). Benchmark on your actual model.

---

## Layer 5 — Session & Docs Structure

**Pick: `nadimtuhin/claude-token-optimizer`** — restructures your project docs so
Claude loads ~800 tokens of essentials at startup instead of thousands of lines
of stale CLAUDE.md, session notes, and completed-task history. Everything else
becomes load-on-demand.

```bash
npx claude-token-optimizer init    # run once per repo
```

This is zero-conflict with every other layer and arguably the best
effort-to-savings ratio in the whole stack. Do this first.

---

## Deployment Order

1. **L5 first** (`npx claude-token-optimizer init`) — instant, no moving parts.
2. **L1** (`brew install rtk && rtk init -g`) — global, benefits every repo.
3. **L3** (`code-review-graph` in your main repos, `graphify` for notes).
4. **L4** (one style plugin) — measure a few sessions before/after.
5. **L2** (token-savior) — last, because caching matters most once the rest of
   the pipeline defines what gets read at all.
6. Optional: headroom wrap, claude-context — only if measurements say you need them.

## Measuring

- `code-review-graph` attaches `context_savings` metadata to its MCP responses
  (verifiable against tiktoken with `--verify`).
- ooples MCP (if chosen) records every optimization in SQLite.
- Baseline manually: note session token usage in Claude Code (`/cost`) for a
  typical task before installing each layer, and after. Add layers only when the
  previous one shows real savings — every layer has a standing context cost.
