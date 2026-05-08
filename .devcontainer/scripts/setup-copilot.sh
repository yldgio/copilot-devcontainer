#!/usr/bin/env bash
# setup-copilot.sh — Interactive Copilot CLI setup wizard.
#
# Supports:
#   - New container first-run customization
#   - Existing container reconfiguration
#
# Configures (all optional):
#   - Copilot marketplace plugins (add / remove)
#   - BYOK (Bring Your Own Key)
#   - COPILOT_OFFLINE mode
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVCONTAINER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_LOCAL="$DEVCONTAINER_DIR/.env.local"
COPILOT_CONFIG_DIR="$HOME/.copilot"
BYOK_CONFIG="$COPILOT_CONFIG_DIR/byok.env"

DEFAULT_MARKETPLACES=(
  "microsoft/azure-skills"
  "github/awesome-copilot"
  "microsoft/work-iq"
)

NON_INTERACTIVE="false"
SETUP_MODE=""
PLUGIN_DEFERRED="false"
SUMMARY_LINES=()

add_summary() {
  SUMMARY_LINES+=("$1")
}

print_header() {
  echo "━━━ Copilot CLI Setup Wizard ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

usage() {
  cat <<EOF
Usage:
  bash .devcontainer/scripts/setup-copilot.sh [options]

Options:
  --non-interactive   Run without prompts using current environment values.
  --new               Assume new-container flow (interactive mode only).
  --existing          Assume existing-container flow (interactive mode only).
  -h, --help          Show this help message.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --non-interactive)
        NON_INTERACTIVE="true"
        shift
        ;;
      --new)
        SETUP_MODE="new"
        shift
        ;;
      --existing)
        SETUP_MODE="existing"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "❌ Unknown option: $1"
        echo "   Run with --help for usage."
        exit 1
        ;;
    esac
  done
}

ensure_env_file() {
  if [[ ! -f "$ENV_LOCAL" ]]; then
    cat > "$ENV_LOCAL" <<EOF
# .env.local — local environment exports for devcontainer.
# Generated/updated by .devcontainer/scripts/setup-copilot.sh
# This file is gitignored by default.
EOF
    chmod 600 "$ENV_LOCAL" 2>/dev/null || true
  fi
}

read_export_value() {
  local key="$1"
  local file="$2"

  if [[ ! -f "$file" ]]; then
    return 0
  fi

  local line
  line="$(grep -E "^[[:space:]]*export[[:space:]]+${key}=" "$file" 2>/dev/null | tail -n1 || true)"
  line="${line#*=}"
  line="${line%\"}"
  line="${line#\"}"
  printf '%s' "$line"
}

upsert_export() {
  local key="$1"
  local value="$2"
  local tmp
  tmp="$(mktemp)"

  awk -v key="$key" -v val="$value" '
    BEGIN { updated=0 }
    {
      if ($0 ~ "^[[:space:]]*export[[:space:]]+" key "=") {
        if (!updated) {
          print "export " key "=\"" val "\""
          updated=1
        }
        next
      }
      print
    }
    END {
      if (!updated) print "export " key "=\"" val "\""
    }
  ' "$ENV_LOCAL" > "$tmp"

  mv "$tmp" "$ENV_LOCAL"
  chmod 600 "$ENV_LOCAL" 2>/dev/null || true
}

remove_export() {
  local key="$1"
  local tmp
  tmp="$(mktemp)"

  awk -v key="$key" '
    {
      if ($0 ~ "^[[:space:]]*export[[:space:]]+" key "=") next
      print
    }
  ' "$ENV_LOCAL" > "$tmp"

  mv "$tmp" "$ENV_LOCAL"
  chmod 600 "$ENV_LOCAL" 2>/dev/null || true
}

prompt_yes_no() {
  local prompt="$1"
  local default="$2"
  local answer
  local hint="[y/N]"

  if [[ "$default" == "y" ]]; then
    hint="[Y/n]"
  fi

  while true; do
    read -r -p "${prompt} ${hint}: " answer
    answer="${answer:-$default}"
    case "${answer,,}" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

prompt_setup_mode() {
  if [[ -n "$SETUP_MODE" ]]; then
    return
  fi

  echo ""
  echo "Choose setup mode:"
  echo "  1) New container (first-time customization)"
  echo "  2) Existing container (adjust current settings)"

  local choice
  while true; do
    read -r -p "Select [1/2] (default 1): " choice
    choice="${choice:-1}"
    case "$choice" in
      1)
        SETUP_MODE="new"
        return
        ;;
      2)
        SETUP_MODE="existing"
        return
        ;;
      *)
        echo "Please enter 1 or 2."
        ;;
    esac
  done
}

verify_copilot() {
  if ! command -v copilot &>/dev/null; then
    echo "❌ copilot not found. Run .devcontainer/setup.sh first."
    exit 1
  fi
}

can_manage_plugins() {
  copilot plugin marketplace list >/dev/null 2>&1
}

install_plugin() {
  local plugin="$1"
  if copilot plugin marketplace add "$plugin" >/dev/null 2>&1; then
    echo "    ✓ Added $plugin"
    return 0
  fi

  echo "    ⚠ Could not add $plugin"
  return 1
}

remove_plugin() {
  local plugin="$1"
  if copilot plugin marketplace remove "$plugin" >/dev/null 2>&1; then
    echo "    ✓ Removed $plugin"
    return 0
  fi

  echo "    ⚠ Could not remove $plugin"
  return 1
}

trim() {
  local s="$1"
  s="${s#${s%%[![:space:]]*}}"
  s="${s%${s##*[![:space:]]}}"
  printf '%s' "$s"
}

split_csv() {
  local csv="$1"
  IFS=',' read -r -a __items <<< "$csv"
  for raw in "${__items[@]}"; do
    local clean
    clean="$(trim "$raw")"
    if [[ -n "$clean" ]]; then
      echo "$clean"
    fi
  done
}

configure_plugins_interactive() {
  echo ""
  echo "Step 1/3 — Plugin management"

  if ! prompt_yes_no "Configure Copilot marketplace plugins now?" "n"; then
    echo "  ↷ Skipped plugin management"
    add_summary "Plugins: skipped"
    return
  fi

  if ! can_manage_plugins; then
    echo "  ⚠ Plugin operations require authentication/network access."
    echo "    Run: copilot  then  /login"
    echo "    You can rerun this wizard afterwards to add/remove plugins."
    PLUGIN_DEFERRED="true"
    add_summary "Plugins: deferred (login required)"
    return
  fi

  echo ""
  if prompt_yes_no "Install recommended marketplaces (azure-skills, awesome-copilot, work-iq)?" "n"; then
    for plugin in "${DEFAULT_MARKETPLACES[@]}"; do
      install_plugin "$plugin" || true
    done
  else
    echo "  ↷ Skipped recommended marketplaces"
  fi

  local additional
  read -r -p "Add extra marketplace IDs (comma-separated, or blank to skip): " additional
  if [[ -n "$(trim "$additional")" ]]; then
    while IFS= read -r plugin; do
      install_plugin "$plugin" || true
    done < <(split_csv "$additional")
  fi

  if [[ "$SETUP_MODE" == "existing" ]]; then
    local to_remove
    read -r -p "Remove marketplace IDs (comma-separated, or blank to skip): " to_remove
    if [[ -n "$(trim "$to_remove")" ]]; then
      while IFS= read -r plugin; do
        remove_plugin "$plugin" || true
      done < <(split_csv "$to_remove")
    fi
  fi

  echo ""
  echo "  Installed marketplaces:"
  copilot plugin marketplace list 2>/dev/null || true
  add_summary "Plugins: updated"
}

configure_plugins_non_interactive() {
  echo ""
  echo "Step 1/3 — Plugin management (non-interactive)"
  if ! can_manage_plugins; then
    echo "  ⚠ Skipping plugins (requires login/network)."
    add_summary "Plugins: skipped (login/network required)"
    PLUGIN_DEFERRED="true"
    return
  fi

  for plugin in "${DEFAULT_MARKETPLACES[@]}"; do
    install_plugin "$plugin" || true
  done
  add_summary "Plugins: ensured recommended marketplaces"
}

write_byok_runtime_config() {
  local api_key="$1"
  local endpoint="$2"

  mkdir -p "$COPILOT_CONFIG_DIR"
  cat > "$BYOK_CONFIG" <<EOF
# BYOK configuration — generated by setup-copilot.sh
# Stored in the persistent auth volume (if mounted).
export COPILOT_BYOK_API_KEY="${api_key}"
EOF

  if [[ -n "$endpoint" ]]; then
    echo "export COPILOT_BYOK_ENDPOINT=\"${endpoint}\"" >> "$BYOK_CONFIG"
  fi

  chmod 600 "$BYOK_CONFIG" 2>/dev/null || true
}

configure_byok_interactive() {
  local current_key="${COPILOT_BYOK_API_KEY:-$(read_export_value "COPILOT_BYOK_API_KEY" "$ENV_LOCAL")}"
  local current_endpoint="${COPILOT_BYOK_ENDPOINT:-$(read_export_value "COPILOT_BYOK_ENDPOINT" "$ENV_LOCAL")}"

  echo ""
  echo "Step 2/3 — BYOK (Bring Your Own Key)"

  if ! prompt_yes_no "Configure or adjust BYOK now?" "n"; then
    echo "  ↷ Skipped BYOK"
    add_summary "BYOK: skipped"
    return
  fi

  if ! prompt_yes_no "Enable BYOK for this workspace?" "y"; then
    remove_export "COPILOT_BYOK_API_KEY"
    remove_export "COPILOT_BYOK_ENDPOINT"
    if [[ -f "$BYOK_CONFIG" ]]; then
      rm -f "$BYOK_CONFIG"
    fi
    echo "  ✓ BYOK disabled"
    add_summary "BYOK: disabled"
    return
  fi

  local api_key=""
  local endpoint="$current_endpoint"

  if [[ -n "$current_key" ]]; then
    if prompt_yes_no "Reuse existing API key (${current_key:0:6}…)?" "y"; then
      api_key="$current_key"
    fi
  fi

  while [[ -z "$api_key" ]]; do
    read -r -s -p "Enter BYOK API key: " api_key
    echo ""
    api_key="$(trim "$api_key")"
    if [[ -z "$api_key" ]]; then
      echo "  API key is required when BYOK is enabled."
    fi
  done

  local endpoint_prompt=""
  if [[ -n "$current_endpoint" ]]; then
    read -r -p "Endpoint (Enter=keep current, NONE=clear): " endpoint_prompt
    endpoint_prompt="$(trim "$endpoint_prompt")"
    if [[ "${endpoint_prompt^^}" == "NONE" ]]; then
      endpoint=""
    elif [[ -n "$endpoint_prompt" ]]; then
      endpoint="$endpoint_prompt"
    fi
  else
    read -r -p "Endpoint (optional, leave blank to skip): " endpoint_prompt
    endpoint="$(trim "$endpoint_prompt")"
  fi

  upsert_export "COPILOT_BYOK_API_KEY" "$api_key"
  if [[ -n "$endpoint" ]]; then
    upsert_export "COPILOT_BYOK_ENDPOINT" "$endpoint"
  else
    remove_export "COPILOT_BYOK_ENDPOINT"
  fi
  write_byok_runtime_config "$api_key" "$endpoint"

  echo "  ✓ BYOK configured"
  echo "    Key      : ${api_key:0:6}…"
  if [[ -n "$endpoint" ]]; then
    echo "    Endpoint : $endpoint"
  else
    echo "    Endpoint : (not set)"
  fi
  add_summary "BYOK: configured"
}

configure_byok_non_interactive() {
  echo ""
  echo "Step 2/3 — BYOK (non-interactive)"

  if [[ -n "${COPILOT_BYOK_API_KEY:-}" ]]; then
    upsert_export "COPILOT_BYOK_API_KEY" "$COPILOT_BYOK_API_KEY"
    if [[ -n "${COPILOT_BYOK_ENDPOINT:-}" ]]; then
      upsert_export "COPILOT_BYOK_ENDPOINT" "$COPILOT_BYOK_ENDPOINT"
    fi
    write_byok_runtime_config "$COPILOT_BYOK_API_KEY" "${COPILOT_BYOK_ENDPOINT:-}"
    echo "  ✓ BYOK configured from environment"
    add_summary "BYOK: configured from environment"
  else
    echo "  ↷ Skipped BYOK (COPILOT_BYOK_API_KEY not set)"
    add_summary "BYOK: skipped"
  fi
}

configure_offline_interactive() {
  local current_offline
  current_offline="${COPILOT_OFFLINE:-$(read_export_value "COPILOT_OFFLINE" "$ENV_LOCAL")}"

  echo ""
  echo "Step 3/3 — Offline mode"

  if ! prompt_yes_no "Configure offline mode now?" "n"; then
    echo "  ↷ Skipped offline mode"
    add_summary "Offline mode: skipped"
    return
  fi

  local default_enable="n"
  if [[ "$current_offline" == "true" ]]; then
    default_enable="y"
  fi

  if prompt_yes_no "Enable COPILOT_OFFLINE=true?" "$default_enable"; then
    upsert_export "COPILOT_OFFLINE" "true"
    echo "  ✓ Offline mode enabled"
    add_summary "Offline mode: enabled"
  else
    upsert_export "COPILOT_OFFLINE" "false"
    echo "  ✓ Offline mode disabled"
    add_summary "Offline mode: disabled"
  fi
}

configure_offline_non_interactive() {
  echo ""
  echo "Step 3/3 — Offline mode (non-interactive)"
  if [[ "${COPILOT_OFFLINE:-}" == "true" ]]; then
    upsert_export "COPILOT_OFFLINE" "true"
    echo "  ✓ Offline mode enabled from environment"
    add_summary "Offline mode: enabled from environment"
  else
    echo "  ↷ Left unchanged (set COPILOT_OFFLINE=true to enable)"
    add_summary "Offline mode: unchanged"
  fi
}

print_next_steps() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Copilot CLI setup complete."
  echo ""
  echo "Summary:"
  for line in "${SUMMARY_LINES[@]}"; do
    echo "  - $line"
  done

  echo ""
  echo "Config file: $ENV_LOCAL"

  if [[ "$SETUP_MODE" == "new" ]]; then
    echo ""
    echo "Next steps (new container):"
    echo "  1. Run: copilot"
    echo "  2. In the TUI run: /login"
    echo "  3. Verify plugins: /plugins"
  elif [[ "$PLUGIN_DEFERRED" == "true" ]]; then
    echo ""
    echo "Next steps (plugins deferred):"
    echo "  1. Run: copilot"
    echo "  2. In the TUI run: /login"
    echo "  3. Re-run: bash .devcontainer/scripts/setup-copilot.sh --existing"
  fi

  echo ""
  echo "Browse plugins : copilot plugin marketplace browse azure-skills"
  echo "Install plugin : copilot  →  /plugin install azure@azure-skills"
}

main() {
  parse_args "$@"
  print_header
  verify_copilot
  ensure_env_file

  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    SETUP_MODE="existing"
    configure_plugins_non_interactive
    configure_byok_non_interactive
    configure_offline_non_interactive
    print_next_steps
    exit 0
  fi

  prompt_setup_mode

  echo ""
  if [[ "$SETUP_MODE" == "new" ]]; then
    echo "Mode: New container setup"
  else
    echo "Mode: Existing container reconfiguration"
  fi

  configure_plugins_interactive
  configure_byok_interactive
  configure_offline_interactive
  print_next_steps
}

main "$@"
