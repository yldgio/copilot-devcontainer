#!/usr/bin/env bash
# install.sh — copies .devcontainer/ and .mcp.json into the current directory.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.sh | bash -s -- --version v1.0.0
#   curl -fsSL https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.sh | bash -s -- --force
set -euo pipefail

REPO="yldgio/copilot-devcontainer"
VERSION="main"
FORCE=false
DEST="$(pwd)"

# ── Parse arguments ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --force)   FORCE=true;   shift   ;;
    *) echo "❌  Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── Conflict check ───────────────────────────────────────────────────────────
if [[ -d "$DEST/.devcontainer" && "$FORCE" == "false" ]]; then
  echo ""
  echo "❌  .devcontainer/ already exists in $DEST"
  echo "    Use --force to overwrite:"
  echo ""
  echo "    curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- --force"
  echo ""
  exit 1
fi

# ── Build tarball URL ─────────────────────────────────────────────────────────
# Accepts branch name, tag, or full commit SHA — GitHub resolves all three.
URL="https://github.com/$REPO/archive/$VERSION.tar.gz"

# ── Download + extract to temp dir ───────────────────────────────────────────
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo ""
echo "  › Downloading $REPO@$VERSION ..."
curl -fsSL "$URL" | tar -xz -C "$TMP"

SRC=$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | head -1)
if [[ -z "$SRC" ]]; then
  echo "❌  Failed to extract archive." >&2
  exit 1
fi
if [[ ! -d "$SRC/.devcontainer" ]]; then
  echo "❌  .devcontainer/ not found in archive. Wrong version?" >&2
  exit 1
fi

# ── Install (stage first, then move atomically) ───────────────────────────────
echo "  › Installing files into $DEST ..."
STAGE=$(mktemp -d)
trap 'rm -rf "$TMP" "$STAGE"' EXIT

cp -r "$SRC/.devcontainer" "$STAGE/"
cp    "$SRC/.mcp.json"     "$STAGE/"

if [[ "$FORCE" == "true" ]]; then
  rm -rf "$DEST/.devcontainer"
  rm -f  "$DEST/.mcp.json"
fi

mv "$STAGE/.devcontainer" "$DEST/"
mv "$STAGE/.mcp.json"     "$DEST/"

echo ""
echo "✅  Dev container files installed successfully."
echo "    Open this folder in VS Code and choose:"
echo "    Dev Containers: Reopen in Container"
echo ""
