#!/usr/bin/env bash
# Optional: install recommended Copilot CLI plugins.
# Requires authentication first: copilot → /login
# Run manually after container creation: bash .devcontainer/scripts/install-plugins.sh
set -euo pipefail

echo "  › Installing Copilot CLI plugins..."
echo "  (make sure you have run 'copilot' → '/login' first)"
echo ""

copilot plugin marketplace add github/awesome-copilot
copilot plugin install anvil@awesome-copilot

echo ""
echo "✅ Plugins installed."
echo "   Run 'copilot' and '/plugins' to verify."
