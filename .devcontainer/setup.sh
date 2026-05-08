#!/usr/bin/env bash
# Dev container setup script — runs once as the 'vscode' user after container creation.
set -euo pipefail

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_BIN="$HOME/.local/bin"

echo "━━━ Copilot Dev Container Setup ━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 0. Fix volume-mount ownership ───────────────────────────────────────────
# Docker creates named-volume mount-point directories as root before this
# script runs, even when remoteUser is set. Reclaim ownership for every
# directory used as a volume target so the vscode user can read/write them.
#   copilot-auth    → ~/.copilot              (Copilot CLI data dir: tokens, settings)
#   gh-auth         → ~/.config/gh            (gh CLI hosts.yml)
#   copilot-keyring → ~/.local/share/keyrings (gnome-keyring data)
mkdir -p "$HOME/.copilot" "$HOME/.config/gh"
sudo chown -R "$(id -u):$(id -g)" \
  "$HOME/.local" \
  "$HOME/.copilot" \
  "$HOME/.config/gh" \
  2>/dev/null || true

# ── 0b. Fix shell script permissions ────────────────────────────────────────
# Ensure all .sh files in the workspace are executable and owned by vscode.
# Git on Windows strips execute bits; this restores them inside the container.
find "$WORKSPACE" -name "*.sh" -exec sudo chown vscode:vscode {} + 2>/dev/null || true
find "$WORKSPACE" -name "*.sh" -exec chmod +x {} +

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

# ── 3. Keyring support ─────────────────────────────────────────────────────
# gh CLI and Copilot CLI use libsecret to store tokens in a system keyring.
# gnome-keyring-daemon satisfies the libsecret D-Bus interface headlessly.
# Keyring data lands in ~/.local/share/keyrings/ which is mounted as a named
# volume (copilot-keyring) so it survives container rebuilds.
#
# gnome-keyring 46 cannot CREATE a new login collection headlessly — that
# requires gcr-prompter (a GTK3 GUI dialog). We work around this by
# pre-populating the collection descriptor file on first run. The file uses
# the text format gnome-keyring 46 writes for empty-password keyrings; the
# daemon loads it at startup and auto-unlocks it (empty password = no prompt).
echo "  › Installing keyring support (gnome-keyring, dbus-x11)..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends gnome-keyring dbus-x11 > /dev/null 2>&1

# Pre-create the login keyring collection if the volume is empty (first build).
# gnome-keyring reads this file and exposes the collection via D-Bus with no
# password prompt. Secrets are encrypted on disk by the daemon once items are
# stored. Guard with -f so a rebuild never overwrites existing keyring data.
KEYRING_DIR="$HOME/.local/share/keyrings"
mkdir -p "$KEYRING_DIR"
if [ ! -f "$KEYRING_DIR/login.keyring" ]; then
  cat > "$KEYRING_DIR/login.keyring" << 'KEYRINGEOF'
[keyring]
display-name=login
ctime=0
mtime=0
lock-on-idle=false
lock-after=false
KEYRINGEOF
  chmod 600 "$KEYRING_DIR/login.keyring"
  # "default" aliases the default collection name — must match display-name above
  echo "login" > "$KEYRING_DIR/default"
  echo "  ✓ Login keyring pre-initialized (empty-password, auto-unlocks headlessly)"
fi
unset KEYRING_DIR

# Start gnome-keyring-daemon for each interactive bash session.
if ! grep -qF "gnome-keyring-daemon" "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'BASHRC'

# ── Keyring daemon ───────────────────────────────────────────────────────────
# Provides a libsecret-compatible vault so gh/Copilot CLI can store tokens
# without printing "The system vault is not available."
# The session address is persisted to ~/.dbus-session-env so all shells share
# one D-Bus daemon and one gnome-keyring-daemon instead of spawning new ones.
_DBUS_ENV="$HOME/.dbus-session-env"

# Restore a previously saved session if the socket still exists.
if [ -f "$_DBUS_ENV" ]; then
  # shellcheck disable=SC1090
  . "$_DBUS_ENV"
fi

# Validate the current address; launch a fresh daemon if it's gone.
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] || \
   ! dbus-send --session --dest=org.freedesktop.DBus --type=method_call \
       --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames \
       &>/dev/null; then
  if command -v dbus-launch &>/dev/null; then
    eval "$(dbus-launch --sh-syntax 2>/dev/null)" 2>/dev/null || true
    {
      echo "export DBUS_SESSION_BUS_ADDRESS='${DBUS_SESSION_BUS_ADDRESS:-}'"
      echo "export DBUS_SESSION_BUS_PID='${DBUS_SESSION_BUS_PID:-}'"
    } > "$_DBUS_ENV"
  fi
fi

# Start gnome-keyring if the secrets service isn't on D-Bus yet.
# Guard via D-Bus query: GNOME_KEYRING_CONTROL is always empty in gnome-keyring
# 46+ so the old `-z` check caused a failed restart attempt on every shell open.
if command -v gnome-keyring-daemon &>/dev/null && \
   ! dbus-send --session --dest=org.freedesktop.DBus --type=method_call \
       --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames \
       2>/dev/null | grep -q "org.freedesktop.secrets"; then
  eval "$(gnome-keyring-daemon --start --components=secrets 2>/dev/null)" 2>/dev/null || true
fi

unset _DBUS_ENV
BASHRC
fi

# ── 4. GitHub Copilot CLI ───────────────────────────────────────────────────
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
echo "    1. Run wizard    : bash .devcontainer/scripts/setup-copilot.sh"
echo "       (guides plugins, BYOK, and offline mode — all opt-in)"
echo "    2. Complete auth : copilot  →  /login"
echo ""
echo "  Advanced:"
echo "    BYOK / offline   : copy .devcontainer/.env.local.example → .env.local, set vars, rebuild"
echo "    Clear auth       : bash .devcontainer/scripts/clear-auth.sh"
