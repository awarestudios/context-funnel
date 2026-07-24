#!/usr/bin/env bash
# Context & Token Reduction Stack — bootstrap
# Recommended stack: rtk + token-savior + code-review-graph + graphify
#                    + nadimtuhin claude-token-optimizer + ONE style plugin
#
# Usage:
#   ./bootstrap.sh                 # install recommended stack (global pieces)
#   ./bootstrap.sh --repo <path>   # additionally set up a specific repo
#   ./bootstrap.sh --style caveman|ponytail|none   (default: none — install manually)
#   ./bootstrap.sh --mcp ooples    # use ooples token-optimizer-mcp instead of token-savior
set -euo pipefail

STYLE="none"
MCP="token-savior"
REPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --style) STYLE="$2"; shift 2 ;;
    --mcp)   MCP="$2";   shift 2 ;;
    --repo)  REPO="$2";  shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------- prerequisites ----------
log "Checking prerequisites"
for bin in node npm python3 pip3; do
  have "$bin" || { echo "missing: $bin — install it first"; exit 1; }
done
have claude || echo "WARN: 'claude' CLI not found — MCP registration steps will be skipped"

# ---------- Layer 1: rtk ----------
log "Layer 1: rtk (command output compression)"
if ! have rtk; then
  if have brew; then
    brew install rtk
  else
    echo "Homebrew not found; installing rtk from source (requires cargo)"
    have cargo && cargo install --git https://github.com/rtk-ai/rtk \
      || echo "SKIP rtk: install brew or cargo, then: brew install rtk && rtk init -g"
  fi
fi
if have rtk; then
  # sanity check: crates.io has an unrelated 'rtk' (Rust Type Kit)
  if rtk gain >/dev/null 2>&1 || rtk --help 2>/dev/null | grep -qi token; then
    rtk init -g && echo "rtk configured globally for Claude Code"
  else
    echo "WARN: this 'rtk' looks like the wrong package (Rust Type Kit)."
    echo "      Fix: cargo install --git https://github.com/rtk-ai/rtk"
  fi
fi

# ---------- Layer 2: MCP caching/nav ----------
log "Layer 2: MCP server ($MCP)"
if [[ "$MCP" == "token-savior" ]]; then
  pip3 install --upgrade "token-savior-recall[mcp]"
  if have claude; then
    claude mcp add --transport stdio --scope user token-savior -- \
      python3 -m token_savior_recall 2>/dev/null \
      || echo "NOTE: verify the exact server launch command in token-savior's README and adjust 'claude mcp add' if needed"
  fi
elif [[ "$MCP" == "ooples" ]]; then
  if have claude; then
    claude mcp add --transport stdio --scope user token-optimizer -- \
      npx -y @ooples/token-optimizer-mcp@latest
  fi
  echo "NOTE: ooples injects 74 tool schemas per turn — heavier baseline than token-savior."
else
  echo "SKIP Layer 2 (unknown --mcp value: $MCP)"
fi

# ---------- Layer 3: retrieval ----------
log "Layer 3: graph retrieval (code-review-graph + graphify)"
pip3 install --upgrade code-review-graph
code-review-graph install || echo "WARN: code-review-graph auto-config failed; run 'code-review-graph install' manually"

pip3 install --upgrade graphifyy
graphify install || echo "WARN: graphify install failed; re-run 'graphify install' manually"

# ---------- Layer 4: output style ----------
log "Layer 4: output style ($STYLE)"
case "$STYLE" in
  caveman)
    have claude && claude plugin marketplace add JuliusBrussee/caveman \
      && claude plugin install caveman@caveman ;;
  ponytail)
    echo "Ponytail installs via Claude Code plugin marketplace — see:"
    echo "  https://github.com/DietrichGebert/ponytail (INSTALL section)"
    echo "Requires node on the non-interactive shell PATH for its lifecycle hooks." ;;
  none)
    echo "No style plugin installed. Pick ONE later (caveman | ponytail |"
    echo "drona23/claude-token-efficient | alexgreensh/token-optimizer)." ;;
  *) echo "unknown style: $STYLE" ;;
esac

# ---------- Layer 5 + per-repo setup ----------
if [[ -n "$REPO" ]]; then
  log "Per-repo setup: $REPO"
  cd "$REPO"
  npx -y claude-token-optimizer init      # L5: restructure docs for lazy loading
  code-review-graph build                 # L3: parse this codebase into the graph
  echo "Repo configured: $REPO"
else
  log "Layer 5: run per-repo when ready"
  echo "For each project:  cd <repo> && npx claude-token-optimizer init && code-review-graph build"
fi

log "Done"
cat <<'EOF'
Next steps:
  1. Restart Claude Code so MCP/plugin changes load.
  2. Baseline: run a typical task, note /cost.
  3. In each main repo: ./bootstrap.sh --repo /path/to/repo
  4. After a week, decide on optional add-ons:
       headroom:  uv tool install --python 3.13 "headroom-ai[all]" && headroom wrap claude
       claude-context (needs OpenAI key + Zilliz Cloud) — only for huge codebases.
Remember: one tool per layer. Every extra MCP server and rule file costs input
tokens on every single turn.
EOF
