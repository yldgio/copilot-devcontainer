#!/usr/bin/env bash
# clear-auth.sh — Remove persisted Copilot CLI auth from the named Docker volume.
#
# Use this when you want to:
#   - Log out and revoke the stored session
#   - Opt-out of persistent auth for this container
#   - Reset auth for security reasons (e.g. token rotation, shared machine)
#
# Run inside the container:
#   bash .devcontainer/scripts/clear-auth.sh
#
# To permanently opt-out (never persist auth):
#   Remove the "mounts" block from .devcontainer/devcontainer.json and rebuild.
set -euo pipefail

AUTH_DIR="$HOME/.copilot"
KEYRING_DIR="$HOME/.local/share/keyrings"

if [[ ! -d "$AUTH_DIR" && ! -d "$KEYRING_DIR" ]]; then
  echo "ℹ️  No Copilot auth data found — nothing to clear."
  exit 0
fi

echo "⚠️  This will remove all Copilot CLI auth data from the persistent volumes:"
echo "    • $AUTH_DIR  (loggedInUsers, settings)"
echo "    • $KEYRING_DIR  (OAuth token stored in gnome-keyring)"
echo "    You will need to re-authenticate with: copilot → /login"
echo ""
read -rp "    Continue? [y/N] " confirm
if [[ "${confirm,,}" != "y" ]]; then
  echo "    Aborted."
  exit 0
fi

find "${AUTH_DIR:?}" -mindepth 1 -delete
find "${KEYRING_DIR:?}" -mindepth 1 -delete
echo ""
echo "✅ Auth cleared. Both persistent volumes are now empty."
echo "   To permanently disable auth persistence, remove the 'mounts' block"
echo "   from .devcontainer/devcontainer.json and rebuild the container."
echo ""
echo "   To re-authenticate:  copilot  →  /login"
