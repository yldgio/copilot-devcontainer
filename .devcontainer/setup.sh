#!/usr/bin/env bash
# Dev container setup script — runs once as the 'vscode' user after container creation.
set -euo pipefail

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "━━━ Copilot Dev Container Setup ━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. UV (Python package manager) ─────────────────────────────────────────
echo "  › Installing UV..."
curl -LsSf https://astral.sh/uv/install.sh | sh
# Make uv available for the rest of this script and for all future bash sessions.
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"

# ── 2. GitHub Copilot CLI ───────────────────────────────────────────────────
echo "  › Installing GitHub Copilot CLI..."
# Use the full package path to avoid matching unrelated 'copilot' binaries (e.g. AWS Copilot).
if ! npm list -g @github/copilot &>/dev/null; then
  npm install -g @github/copilot
fi

# ── 3. Skills catalogue (project-local, auto-discovered by Copilot CLI) ────
# Sparse-clone only the skills/ tree from github/awesome-copilot.
# The CLI discovers skills/ at the git root automatically (v1.0.11+).
if [ ! -d "$WORKSPACE/skills" ]; then
  echo "  › Cloning skills catalogue..."
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  git clone --depth=1 --filter=blob:none --sparse \
    https://github.com/github/awesome-copilot.git "$TMP"
  git -C "$TMP" sparse-checkout set skills
  cp -r "$TMP/skills" "$WORKSPACE/skills"
fi

# ── 4. VS Code MCP config (generated from .mcp.json) ───────────────────────
# .mcp.json is the single source of truth (Copilot CLI uses "mcpServers").
# VS Code Copilot Chat reads .vscode/mcp.json with key "servers".
# The file is generated here and excluded from git (.gitignore).
echo "  › Generating .vscode/mcp.json from .mcp.json..."
python3 - <<'EOF'
import json, pathlib

src = json.loads(pathlib.Path(".mcp.json").read_text())
dst = {"servers": src["mcpServers"]}
vscode_dir = pathlib.Path(".vscode")
vscode_dir.mkdir(exist_ok=True)
(vscode_dir / "mcp.json").write_text(json.dumps(dst, indent=2) + "\n")
EOF

echo ""
echo "✅ Setup complete."
echo ""
echo "  MCP servers are pre-configured in .mcp.json at the project root."
echo ""
echo "  To install plugins, authenticate first:"
echo "    copilot"
echo "    /login"
echo ""
echo "  Then install plugins from the terminal:"
echo "    copilot plugin marketplace add github/awesome-copilot  # if not already registered"
echo "    copilot plugin install anvil@awesome-copilot"
echo "    copilot plugin install azure@azure-skills"
