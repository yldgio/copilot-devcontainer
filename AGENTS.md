# AGENTS.md

Dev container for AI-assisted development with GitHub Copilot CLI.

## Environment

- Ubuntu 24.04 | Node LTS | Python 3.12 (via UV) | Git | GitHub CLI (`gh`)
- Docker CLI via host socket (`docker-outside-of-docker`) — no daemon inside the container
- UV at `~/.local/bin/uv`
- GitHub Copilot CLI: `copilot` — authenticate with `/login` on first use

## Workspace

Host project folder is bind-mounted at `/workspaces/copilot-devcontainer`. Files are live — no copy.

## MCP servers

| Name | Transport | Notes |
|------|-----------|-------|
| `context7` | HTTP | Library docs |
| `microsoft-docs` | HTTP | Microsoft Learn |
| `azure` | npx | Azure CLI ops |
| `awesome-copilot` | Docker | Copilot skills |

Config: `.mcp.json` (CLI) and `.vscode/mcp.json` (VS Code Copilot Chat).

## Skills

`skills/` is **not installed by default** — run `.devcontainer/scripts/install-skills.sh` to clone it. Auto-discovered by Copilot CLI when present.
