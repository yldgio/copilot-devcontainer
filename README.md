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

---

## Workspace mount

By default the Dev Containers spec bind-mounts the folder that contains `.devcontainer/` into the container at `/workspaces/<folder-name>`. No extra configuration is needed — your files are mounted directly, nothing is copied.

```
Host: <your project folder>
Container: /workspaces/<folder-name>   (bind-mounted)
```

To use this dev container with a different project, copy the `.devcontainer/` folder into that project's root and rebuild. See **[Install in your repo](#install-in-your-repo)** for a one-liner.

---

## Install in your repo

Copy the devcontainer files into any existing repository without cloning this one.

### npx (Node.js 18+, cross-platform)

```bash
npx github:yldgio/copilot-devcontainer
```

Pinned to a release:

```bash
npx github:yldgio/copilot-devcontainer#v1.0.0
```

With `--force` to overwrite an existing `.devcontainer/`:

```bash
npx github:yldgio/copilot-devcontainer -- --force
```

### bash (Linux / macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.sh | bash
```

Pinned version:

```bash
curl -fsSL https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.sh | bash -s -- --version v1.0.0
```

Force overwrite:

```bash
curl -fsSL https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.sh | bash -s -- --force
```

### PowerShell (Windows / PS 5+)

```powershell
irm https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.ps1 | iex
```

Pinned version (download first, then run with parameters):

```powershell
irm https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.ps1 -OutFile tmp_install.ps1
.\tmp_install.ps1 -Version v1.0.0
Remove-Item tmp_install.ps1
```

Or via environment variable:

```powershell
$env:DEVCONTAINER_VERSION = "v1.0.0"; irm https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.ps1 | iex
```

### What gets installed

| Path | Description |
|------|-------------|
| `.devcontainer/devcontainer.json` | Container definition |
| `.devcontainer/setup.sh` | Post-create setup script |
| `.devcontainer/scripts/install-plugins.sh` | Optional: install Copilot CLI plugins |
| `.mcp.json` | MCP server configuration |

The installer aborts if `.devcontainer/` already exists. Use `--force` / `-Force` to overwrite.

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

### 3. Run the setup wizard (recommended)

```bash
bash .devcontainer/scripts/setup-copilot.sh
```

The wizard is intentionally simple and guides you through opt-in steps:

1. Plugin management
	- new container: add recommended/extra plugins
	- existing container: add/remove plugins
2. BYOK setup or adjustment
3. Offline mode setup or adjustment

Each step can be skipped independently.

### 4. (Optional) legacy plugin-only script

```bash
bash .devcontainer/scripts/install-plugins.sh
```

> The legacy script is kept for backwards compatibility. Prefer `setup-copilot.sh`.

### 5. Use MCP servers

MCP servers are available immediately in both the Copilot CLI and VS Code Copilot Chat.
