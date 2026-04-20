#!/usr/bin/env bash
# Optional: sparse-clone the skills catalogue from github/awesome-copilot.
# The Copilot CLI auto-discovers skills/ at the git root (v1.0.11+).
# Run manually after container creation: bash .devcontainer/scripts/install-skills.sh
set -euo pipefail

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ -d "$WORKSPACE/skills" ]; then
  echo "skills/ already exists — nothing to do."
  exit 0
fi

echo "  › Cloning skills catalogue from github/awesome-copilot..."
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

git clone --depth=1 --filter=blob:none --sparse \
  https://github.com/github/awesome-copilot.git "$TMP"
git -C "$TMP" sparse-checkout set skills
cp -r "$TMP/skills" "$WORKSPACE/skills"

echo "✅ Skills catalogue installed at $WORKSPACE/skills"
