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
#   copilot-auth    → ~/.config/copilot   (Copilot CLI tokens)
#   gh-auth         → ~/.config/gh        (gh CLI hosts.yml)
#   copilot-keyring → ~/.local/share/keyrings  (gnome-keyring data)
sudo chown -R "$(id -u):$(id -g)" \
  "$HOME/.local" \
  "$HOME/.config/copilot" \
  "$HOME/.config/gh" \
  2>/dev/null || true

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
# gh CLI and Copilot CLI look for a system keyring (libsecret) to store tokens.
# Without it they print: "The system vault ... is not available."
# gnome-keyring-daemon runs headless via D-Bus and satisfies the libsecret interface.
# Keyring data lands in ~/.local/share/keyrings/ which is mounted as a named
# volume (copilot-keyring) so it survives container rebuilds.
echo "  › Installing keyring support (gnome-keyring, dbus-x11)..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends gnome-keyring dbus-x11 > /dev/null 2>&1

# One-time keyring initialisation: create the default (login) keyring with an
# empty password so gnome-keyring can store secrets headlessly without a GUI
# prompt. The keyring file lands in ~/.local/share/keyrings/ which is mounted
# as the copilot-keyring named volume and survives container rebuilds.
echo "  › Initializing default keyring..."
if command -v dbus-launch &>/dev/null; then
  (
    eval "$(dbus-launch --sh-syntax 2>/dev/null)" 2>/dev/null || exit 0
    eval "$(gnome-keyring-daemon --start --components=secrets 2>/dev/null)" 2>/dev/null || true
    # --unlock creates the login keyring file with an empty password on first run.
    echo -n "" | gnome-keyring-daemon --unlock >/dev/null 2>&1 || true
    sleep 1
    kill "${DBUS_SESSION_BUS_PID:-}" 2>/dev/null || true
  ) 2>/dev/null || true
fi

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
  # --start and --unlock are incompatible in gnome-keyring 46+; run separately.
  eval "$(gnome-keyring-daemon --start --components=secrets 2>/dev/null)" 2>/dev/null || true
  # Unlock (or create) the default keyring with an empty password.
  echo -n "" | gnome-keyring-daemon --unlock >/dev/null 2>&1 || true
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
