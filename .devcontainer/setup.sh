#!/usr/bin/env bash
# Dev container setup script — runs once as the 'vscode' user after container creation.
set -euo pipefail

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_BIN="$HOME/.local/bin"

echo "━━━ Copilot Dev Container Setup ━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. PATH ─────────────────────────────────────────────────────────────────
mkdir -p "$INSTALL_BIN"
export PATH="$INSTALL_BIN:$PATH"
# Persist for future interactive shells — guard against duplicate entries.
if ! grep -qF "$INSTALL_BIN" "$HOME/.bashrc" 2>/dev/null; then
  echo "export PATH=\"$INSTALL_BIN:\$PATH\"" >> "$HOME/.bashrc"
fi

# ── 2. UV + Python ─────────────────────────────────────────────────────────
echo "  › Installing UV..."
curl -LsSf https://astral.sh/uv/install.sh | sh

echo "  › Installing Python 3.12 via UV..."
uv python install 3.12

# ── 3. GitHub Copilot CLI ───────────────────────────────────────────────────
# Official binary installer: https://docs.github.com/en/copilot/how-tos/set-up/install-copilot-cli
# We always run the install — it replaces any existing binary safely.
# PREFIX is set explicitly so the binary always lands in $HOME/.local/bin,
# regardless of how id -u behaves inside the container.
echo "  › Installing GitHub Copilot CLI..."
PREFIX="$HOME/.local" curl -fsSL https://gh.io/copilot-install | bash

# Verify the binary is reachable.
if ! command -v copilot &>/dev/null; then
  echo "⚠️  copilot not found in PATH after install. Binary should be at $INSTALL_BIN/copilot"
  ls -la "$INSTALL_BIN/copilot" 2>/dev/null || echo "   Binary missing — install may have failed."
  exit 1
fi
echo "  ✓ copilot $(copilot --version 2>/dev/null || echo '(version unavailable)') at $(command -v copilot)"


echo ""
echo "✅ Setup complete."
echo ""
echo "  Next steps:"
echo "    1. Authenticate  : copilot  →  /login"
echo "    2. Setup plugins : bash .devcontainer/scripts/setup-copilot.sh  (run after login)"
echo ""
echo "  Advanced:"
echo "    BYOK / offline   : copy .devcontainer/.env.local.example → .env.local, set vars, rebuild"
echo "    Clear auth       : bash .devcontainer/scripts/clear-auth.sh"
