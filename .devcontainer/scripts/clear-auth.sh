#!/usr/bin/env bash
# clear-auth.sh — Remove persisted auth from all named Docker volumes.
#
# Clears:
#   - Copilot CLI session  (~/.config/copilot/    → copilot-auth volume)
#   - gh CLI token         (~/.config/gh/          → gh-auth volume)
#   - gnome-keyring data   (~/.local/share/keyrings/ → copilot-keyring volume)
#
# Use this when you want to:
#   - Log out and revoke stored sessions
#   - Reset auth for security reasons (e.g. token rotation, shared machine)
#   - Opt-out of persistent auth for this container
#
# Run inside the container:
#   bash .devcontainer/scripts/clear-auth.sh
#
# To permanently opt-out (never persist auth):
#   Remove the "mounts" block from .devcontainer/devcontainer.json and rebuild.
set -euo pipefail

COPILOT_DIR="$HOME/.config/copilot"
GH_DIR="$HOME/.config/gh"
KEYRING_DIR="$HOME/.local/share/keyrings"

any_found=false
for dir in "$COPILOT_DIR" "$GH_DIR" "$KEYRING_DIR"; do
  [[ -d "$dir" ]] && any_found=true && break
done

if [[ "$any_found" == "false" ]]; then
  echo "ℹ️  No auth data found — nothing to clear."
  exit 0
fi

echo "⚠️  This will remove all persisted auth data:"
echo "    - Copilot CLI session : $COPILOT_DIR"
echo "    - gh CLI token        : $GH_DIR"
echo "    - gnome-keyring data  : $KEYRING_DIR"
echo ""
read -rp "    Continue? [y/N] " confirm
if [[ "${confirm,,}" != "y" ]]; then
  echo "    Aborted."
  exit 0
fi

for dir in "$COPILOT_DIR" "$GH_DIR" "$KEYRING_DIR"; do
  if [[ -d "$dir" ]]; then
    find "${dir:?}" -mindepth 1 -delete
    echo "  ✓ Cleared $dir"
  fi
done

echo ""
echo "✅ Auth cleared. All persistent volumes are now empty."
echo "   To permanently disable auth persistence, remove the 'mounts' block"
echo "   from .devcontainer/devcontainer.json and rebuild the container."
echo ""
echo "   To re-authenticate:"
echo "     Copilot CLI : copilot  →  /login"
echo "     gh CLI      : gh auth login"
