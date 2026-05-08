# AGENTS.md

Dev container for AI-assisted development with GitHub Copilot CLI.

**Installation:** To install and configure this environment, follow the instructions in [AUTO-INSTALL.md](./AUTO-INSTALL.md).

## Environment

- Ubuntu 24.04 | Node LTS | Python 3.12 (via UV) | Git | GitHub CLI (`gh`)
- Docker CLI via host socket (`docker-outside-of-docker`) — no daemon inside the container
- UV at `~/.local/bin/uv`
- GitHub Copilot CLI: `copilot` — authenticate with `/login` on first use

## Authentication Persistence

Copilot CLI auth is stored in a named Docker volume (`copilot-auth`) — login survives container rebuilds.

| Action | Command |
|--------|---------|
| First login | `copilot` → `/login` |
| Clear / opt-out | `bash .devcontainer/scripts/clear-auth.sh` |
| Permanent opt-out | Remove `"mounts"` block from `devcontainer.json`, rebuild |

## Workspace

Host project folder is bind-mounted at `/workspaces/copilot-devcontainer`. Files are live — no copy.

## MCP servers

| Name | Transport | Notes |
|------|-----------|-------|
| `context7` | HTTP | Library docs |
| `microsoft-docs` | HTTP | Microsoft Learn |

Config: `.mcp.json` (CLI) and `.vscode/mcp.json` (VS Code Copilot Chat).

## Advanced Configuration

See `AUTO-INSTALL.md §9` for:
- **BYOK** (Bring Your Own Key): export `COPILOT_BYOK_API_KEY` and `COPILOT_BYOK_ENDPOINT` in your host shell before opening VS Code (see `.devcontainer/.env.local.example` for the full variable reference)
- **Offline mode**: export `COPILOT_OFFLINE=true` in your host shell before opening VS Code
- **Setup wizard**: `bash .devcontainer/scripts/setup-copilot.sh` (new container setup or existing container reconfiguration)
