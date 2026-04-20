# Copilot Dev Container

A reusable dev container for AI-assisted development with GitHub Copilot CLI, pre-configured MCP servers, and a full Python/Node/Docker toolchain.

## What's Included

### Runtime (devcontainer features)

| Feature | Version |
|---------|---------|
| Ubuntu | 24.04 |
| Git | 1.x |
| GitHub CLI (`gh`) | 1.x |
| Node.js | LTS |
| Docker CLI | docker-outside-of-docker |

### Tools installed on first creation (`setup.sh`)

| Tool | How |
|------|-----|
| **UV** | `curl https://astral.sh/uv/install.sh` → `~/.local/bin/uv` |
| **Python 3.12** | `uv python install 3.12` (managed by UV) |
| **GitHub Copilot CLI** | official installer `curl -fsSL https://gh.io/copilot-install \| bash` → `~/.local/bin/copilot` |

### VS Code extensions

- `github.copilot` + `github.copilot-chat` — AI completions and chat
- `ms-python.python` + `ms-python.vscode-pylance` — Python support
- `ms-azuretools.vscode-docker` — Docker management UI
- `eamodio.gitlens` — enhanced Git history

### MCP servers

`.mcp.json` is the single source of truth. `setup.sh` auto-generates `.vscode/mcp.json` (different root key required by VS Code) at container creation. The generated file is excluded from git.

| File | Used by | Key |
|------|---------|-----|
| `.mcp.json` | GitHub Copilot CLI | `mcpServers` |
| `.vscode/mcp.json` *(generated)* | VS Code Copilot Chat | `servers` |

| Server | Transport | Purpose |
|--------|-----------|---------|
| `context7` | HTTP | Library and framework documentation |
| `microsoft-docs` | HTTP | Microsoft Learn documentation |
| `azure` | stdio / npx | Azure CLI operations |
| `awesome-copilot` | stdio / Docker | Copilot skills catalogue |

> **Note:** `awesome-copilot` requires Docker. It works because the container uses `docker-outside-of-docker` (see below).

### Skills catalogue

Not installed automatically. Run the optional script when needed:

```bash
bash .devcontainer/scripts/install-skills.sh
```

This sparse-clones `github/awesome-copilot` into `skills/` at the workspace root. The Copilot CLI auto-discovers this directory (v1.0.11+). The `skills/` directory is excluded from git.

---

## Workspace mount

By default the Dev Containers spec bind-mounts the folder that contains `.devcontainer/` into the container at `/workspaces/<folder-name>`. No extra configuration is needed — your files are mounted directly, nothing is copied.

```
Host: <your project folder>
Container: /workspaces/<folder-name>   (bind-mounted)
```

To use this dev container with a different project, copy the `.devcontainer/` folder into that project's root and rebuild.

---

## Why `docker-outside-of-docker` instead of `docker-in-docker`

`docker-in-docker` starts a full `dockerd` daemon **inside** the container on every startup. This caused intermittent ~60-second connection timeouts in VS Code (`resolveAuthority` timeout), making the container fail to load roughly one time in three.

`docker-outside-of-docker` mounts the host's Docker socket (`/var/run/docker.sock`) instead. No daemon is started, so container startup is near-instant.

**Trade-off:** containers you run from inside the dev container are siblings on the host, not nested children. For typical workflows (`docker build`, `docker run`, `docker compose`) this makes no practical difference.

---

## Getting started

### 1. Open in dev container

Open the project in VS Code and choose **Dev Containers: Reopen in Container**. The `postCreateCommand` runs `setup.sh` automatically on first creation.

### 2. Authenticate Copilot CLI

```bash
copilot
/login
```

### 3. (Optional) install skills and plugins

```bash
bash .devcontainer/scripts/install-skills.sh   # skills catalogue
bash .devcontainer/scripts/install-plugins.sh  # Copilot CLI plugins (requires login first)
```

### 4. Use MCP servers

MCP servers are available immediately in both the Copilot CLI and VS Code Copilot Chat. Servers that require `docker` or `npx` work out of the box thanks to the pre-installed toolchain.
