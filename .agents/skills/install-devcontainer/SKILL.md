---
name: install-devcontainer
description: >
  Install and configure the copilot-devcontainer setup in a target project.
  Use when asked to: set up a devcontainer, configure GitHub Copilot CLI,
  bootstrap an AI-assisted development environment, install Copilot CLI plugins,
  or add devcontainer files to an existing repo. Keywords: devcontainer setup,
  copilot CLI install, GitHub Copilot configure, AI dev environment, MCP servers.
---

# install-devcontainer

This skill installs the `yldgio/copilot-devcontainer` template into a target project and walks through all post-install configuration steps, including Copilot CLI authentication and optional plugin setup.

---

## Step 1 — Detect Environment

```bash
# OS
uname -s 2>/dev/null || echo "Windows — use PowerShell installer"

# Docker
docker info 2>/dev/null | head -1 || echo "WARN: Docker not running — start it before proceeding"

# Node.js (for npx installer, requires v18+)
node --version 2>/dev/null || echo "Node.js unavailable"

# Conflict check
test -d .devcontainer \
  && echo "CONFLICT: .devcontainer/ exists — use --force if intentional" \
  || echo "OK: no conflict"
```

**Decision rules:**

- `uname` returns `Linux` or `Darwin` and Node.js 18+ is present → use **npx** (Option A)
- `uname` returns `Linux` or `Darwin` and Node.js is absent → use **bash** (Option B)
- On Windows → use **PowerShell** (Option C)
- `.devcontainer/` exists and replacement is intended → add `--force`

---

## Step 2 — Run the Installer

Pick **one** option based on Step 1:

```bash
# Option A: npx (preferred, Node.js 18+ required)
npx github:yldgio/copilot-devcontainer

# Option B: bash (Linux / macOS)
curl -fsSL https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.sh | bash
```

```powershell
# Option C: PowerShell (Windows)
irm https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.ps1 | iex
```

**Force overwrite** variants (when `.devcontainer/` already exists):

```bash
npx github:yldgio/copilot-devcontainer -- --force
curl -fsSL https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.sh | bash -s -- --force
```

```powershell
$env:DEVCONTAINER_FORCE = "1"; irm https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.ps1 | iex
```

Expected: `✅  Dev container files installed successfully.`

---

## Step 3 — Open in Dev Container

Notify the user:

> Installer complete. Open this folder in VS Code, then use the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`) and run **`Dev Containers: Reopen in Container`**. The `postCreateCommand` will run `setup.sh` automatically — wait for it to complete before proceeding.

Expected final line from `setup.sh`:

```
✅ Setup complete.
```

---

## Step 4 — Authenticate Copilot CLI

Inside the container terminal:

```bash
copilot
```

At the TUI prompt:

```
/login
```

Instruct the user: "A browser OAuth flow will open. Complete the GitHub authorization to continue."

Verify after OAuth:

```bash
copilot --version
```

---

## Step 5 — Install Plugins (optional)

Requires authentication from Step 4.

```bash
bash .devcontainer/scripts/install-plugins.sh
```

Installs: `microsoft/azure-skills`, `github/awesome-copilot`, `microsoft/work-iq`.

Verify inside the TUI: type `/plugins`.

---

## Step 6 — Verify the Full Setup

Run inside the container:

```bash
command -v copilot && copilot --version
uv --version
uv run python --version
gh --version
docker info 2>/dev/null | grep "Server Version"
```

All five commands should return version strings.

---

## Quick Troubleshooting

| Problem | Fix |
|---|---|
| `copilot: command not found` | `export PATH="$HOME/.local/bin:$PATH"` |
| `uv: command not found` | `source ~/.bashrc` then retry |
| Docker not running | Start Docker Desktop before running the installer |
| `.devcontainer/` already exists | Re-run installer with `--force` |

For full troubleshooting, see `AUTO-INSTALL.md §8`.
