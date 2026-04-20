#!/usr/bin/env bash
# Dev container setup script — runs once as the 'vscode' user after container creation.
set -euo pipefail

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "━━━ Copilot Dev Container Setup ━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. PATH ─────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"

# ── 2. UV (Python package manager) ─────────────────────────────────────────
echo "  › Installing UV..."
curl -LsSf https://astral.sh/uv/install.sh | sh

# ── 3. GitHub Copilot CLI ───────────────────────────────────────────────────
# Official install script from https://docs.github.com/en/copilot/how-tos/set-up/install-copilot-cli
# Installs the binary to $HOME/.local/bin (default for non-root users).
echo "  › Installing GitHub Copilot CLI..."
if ! command -v copilot &>/dev/null; then
  curl -fsSL https://gh.io/copilot-install | bash
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
echo "  Next steps:"
echo "    1. Authenticate: copilot  →  /login"
echo "    2. Optional extras:  bash .devcontainer/scripts/install-skills.sh"
echo "                         bash .devcontainer/scripts/install-plugins.sh"
