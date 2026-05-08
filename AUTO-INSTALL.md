# AUTO-INSTALL — Agent Installation Guide

This is the authoritative autonomous-installation guide for the `copilot-devcontainer` template. It covers every step from prerequisites through post-install verification. All commands are copy-paste ready and sourced from the actual installer scripts; no additional context is needed.

---

## §1 Prerequisites Detection

Run these checks before choosing an install path.

### 1.1 Detect the Host OS

| Shell | Detection command | Expected output |
|---|---|---|
| bash / zsh (Linux / macOS) | `uname -s` | `Linux` or `Darwin` |
| Git Bash / WSL on Windows | `uname -o` | `Msys`, `Cygwin`, or `GNU/Linux` |
| PowerShell | `$env:OS` | `Windows_NT` |

If OS cannot be determined, use the npx installer — it is cross-platform.

### 1.2 Check Docker

```bash
docker info 2>/dev/null | head -1
```

**Success:** a line starting with `Client:`. **Failure:** empty output or `Cannot connect to the Docker daemon`. Fix: start Docker Desktop (or `sudo systemctl start docker` on Linux) before continuing.

### 1.3 Check VS Code and the Dev Containers Extension

```bash
code --version 2>/dev/null || echo "VS Code CLI not in PATH"
code --list-extensions 2>/dev/null | grep ms-vscode-remote.remote-containers \
  || echo "Dev Containers extension not installed"
```

If the extension is missing:

```bash
code --install-extension ms-vscode-remote.remote-containers
```

### 1.4 Check GitHub Authentication

```bash
gh auth status 2>/dev/null || echo "GitHub CLI not authenticated"
```

Authentication is required only if the repository is private.

### 1.5 Check Node.js (for npx installer)

```bash
node --version 2>/dev/null || echo "Node.js not found"
```

Minimum: Node.js 18. If absent, use the bash or PowerShell installer instead.

---

## §2 Installation Decision Tree

Follow these steps in order:

1. **Is the current directory the cloned `copilot-devcontainer` repo itself?**
   - Yes → skip to §4 (the devcontainer files are already present).
   - No → continue.

2. **Does `.devcontainer/` already exist in the target directory?**
   - Yes, keep it → abort. Do not overwrite without explicit intent.
   - Yes, replace it → use the `--force` variant in §3.
   - No → use a standard install.

3. **Do you need a pinned release?**
   - Yes → add `--version <tag>` (e.g. `--version v1.0.0`).
   - No → omit the flag (defaults to `main`).

4. **What runtime is available?**
   - Node.js 18+ → prefer **§3.1 (npx)**.
   - bash + curl (Linux / macOS) → use **§3.2 (bash)**.
   - PowerShell 5+ (Windows) → use **§3.3 (PowerShell)**.

---

## §3 Installer Commands

### 3.1 npx (Node.js 18+, all platforms)

```bash
# Standard
npx github:yldgio/copilot-devcontainer

# Pinned version
npx github:yldgio/copilot-devcontainer#v1.0.0

# Force overwrite
npx github:yldgio/copilot-devcontainer -- --force
```

### 3.2 bash (Linux / macOS)

```bash
# Standard
curl -fsSL https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.sh | bash

# Pinned version
curl -fsSL https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.sh | bash -s -- --version v1.0.0

# Force overwrite
curl -fsSL https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.sh | bash -s -- --force
```

### 3.3 PowerShell (Windows, PS 5+)

```powershell
# Standard
irm https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.ps1 | iex

# Pinned version (env-var, compatible with irm | iex)
$env:DEVCONTAINER_VERSION = "v1.0.0"; irm https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.ps1 | iex

# Force overwrite
$env:DEVCONTAINER_FORCE = "1"; irm https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.ps1 | iex
```

### 3.4 What gets installed

| Path | Purpose |
|---|---|
| `.devcontainer/devcontainer.json` | Container definition (Ubuntu 24.04, features, extensions) |
| `.devcontainer/setup.sh` | Post-create script: installs UV, Python 3.12, Copilot CLI |
| `.devcontainer/scripts/install-plugins.sh` | Optional: installs Copilot CLI marketplace plugins |
| `.mcp.json` | MCP server config for Copilot CLI and VS Code Copilot Chat |

### 3.5 Expected success output

```
✅  Dev container files installed successfully.
    Open this folder in VS Code and choose:
    Dev Containers: Reopen in Container
```

---

## §4 Open in Dev Container

1. Open the project folder in VS Code: `code .`
2. VS Code detects `.devcontainer/devcontainer.json` and shows a **"Reopen in Container"** notification — click it.
3. Alternatively, open the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`) and run **`Dev Containers: Reopen in Container`**.

There is no direct CLI flag to reopen in a container; use the VS Code UI or Command Palette.

**What `setup.sh` does during first build** (runs automatically as `postCreateCommand`):

1. Creates `~/.local/bin` and adds it to `$PATH` in `.bashrc`
2. Installs UV via `curl -LsSf https://astral.sh/uv/install.sh | sh`
3. Installs Python 3.12 via `uv python install 3.12`
4. Installs the GitHub Copilot CLI binary to `~/.local/bin/copilot` via the official installer at `https://gh.io/copilot-install`

Expected final output:

```
✅ Setup complete.

  Next steps:
    1. Authenticate: copilot  →  /login
    2. Optional: bash .devcontainer/scripts/install-plugins.sh  (requires login first)
```

---

## §5 Authenticate GitHub Copilot CLI

Authentication requires a human to complete a browser OAuth flow. The agent should instruct the user rather than attempting to automate it.

**Open the Copilot TUI** (inside the container terminal):

```bash
copilot
```

**Log in** at the `>` prompt:

```
/login
```

The TUI prints a device code and URL. The user opens the URL in a browser, enters the code, and authorises the GitHub App.

**Verify** (after OAuth is complete, exit the TUI with `/exit` or `Ctrl+C`):

```bash
copilot --version
```

A version string confirms the binary is working. To confirm authentication specifically, re-enter the TUI — a successful login means `/login` no longer prompts for a code.

---

## §6 Optional: Install Copilot CLI Plugins

Must be done after authentication (§5). Run inside the container:

```bash
bash .devcontainer/scripts/install-plugins.sh
```

Installs three marketplace plugins:

| Plugin | Purpose |
|---|---|
| `microsoft/azure-skills` | Azure CLI and resource management |
| `github/awesome-copilot` | Community-curated skills |
| `microsoft/work-iq` | Productivity workflows |

To verify plugins are installed, open the Copilot TUI and type `/plugins`.

To browse a marketplace from the command line:

```bash
copilot plugin marketplace browse MARKETPLACE-NAME
```

To install a specific plugin from the TUI:

```
/plugin install azure@azure-skills
/plugin install workiq@work-iq
```

Expected final output from the script:

```
✅ Plugins installed.
   Run 'copilot' and '/plugins' to verify.
```

---

## §7 Verification Checklist

Run these commands **inside the container** in order. Each should return a version string.

```bash
# 1. Copilot CLI
command -v copilot && copilot --version

# 2. UV
uv --version

# 3. Python (via UV)
uv run python --version

# 4. GitHub CLI
gh --version

# 5. Docker (host engine, via shared socket)
docker info 2>/dev/null | grep "Server Version"
```

If any command fails, see §8.

Optionally verify MCP server reachability (requires network):

```bash
curl -fsSL https://mcp.context7.com/mcp --max-time 5 -o /dev/null -w "%{http_code}\n" || echo "unreachable"
```

---

## §8 Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `Cannot connect to the Docker daemon` | Docker Desktop / service stopped | Start Docker Desktop; on Linux: `sudo systemctl start docker` |
| `❌  .devcontainer/ already exists` | Prior install or existing config | Add `--force` flag to the installer |
| `copilot: command not found` after install | `~/.local/bin` not in PATH | `export PATH="$HOME/.local/bin:$PATH"`, then re-open the terminal |
| `uv: command not found` | PATH not refreshed | `source ~/.bashrc` or open a new terminal tab |
| Container startup takes > 2 minutes | Wrong Docker feature | Verify `devcontainer.json` uses `docker-outside-of-docker`, not `docker-in-docker` |
| PowerShell execution policy blocks download | Default policy | Use `irm ... \| iex` (bypasses for this invocation), or run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| `npx` fails with version error | Node.js < 18 | Use the bash or PowerShell installer; or upgrade: `nvm install --lts` |
| Dev Containers extension missing | Extension not installed | `code --install-extension ms-vscode-remote.remote-containers` |
| `❌  Failed to extract archive` | Network issue or wrong version tag | Re-run without `--version`, or verify the tag exists at `https://github.com/yldgio/copilot-devcontainer/releases` |

**Where to find container build errors:** VS Code → Output panel → "Dev Containers" channel.

---

---

## §9 Persistent Auth & Advanced Configuration

### 9.1 Persistent Authentication

Copilot CLI auth data (`~/.config/copilot/`) is stored in a named Docker volume (`copilot-auth`) so you only need to log in once. Auth survives container rebuilds and image updates.

**How it works:** `devcontainer.json` declares a named volume mount:

```json
"mounts": [
  { "source": "copilot-auth", "target": "/home/vscode/.config/copilot", "type": "volume" }
]
```

**Opt-out (temporary) — clear stored auth:**

```bash
bash .devcontainer/scripts/clear-auth.sh
```

**Opt-out (permanent) — disable auth persistence:**

Remove the `"mounts"` block from `.devcontainer/devcontainer.json` and rebuild the container. Auth will be ephemeral (lost on rebuild).

**Re-authenticate:**

```
copilot → /login
```

### 9.2 BYOK — Bring Your Own Key

Use your own Azure OpenAI, OpenAI-compatible, or local model instead of GitHub's hosted Copilot model.

`devcontainer.json` uses `${localEnv:VAR_NAME}` to read variables from your **host** environment (the shell where VS Code runs). You must export the variables before opening VS Code — they are not loaded from a file automatically.

**Option A — per-session (export before opening VS Code):**

```bash
export COPILOT_BYOK_API_KEY=sk-...
export COPILOT_BYOK_ENDPOINT=https://<your-resource>.openai.azure.com/
code .
```

**Option B — permanent (add to your shell profile):**

Add to `~/.bashrc`, `~/.zshrc`, or your PowerShell `$PROFILE`:

```bash
export COPILOT_BYOK_API_KEY=sk-...
export COPILOT_BYOK_ENDPOINT=https://<your-resource>.openai.azure.com/
```

Then restart VS Code and rebuild the container.

**Option C — direnv (auto-export on directory entry):**

```bash
cp .devcontainer/.env.local.example .devcontainer/.env.local
# edit .env.local, fill in your values (using `export VAR=value` syntax)
# install direnv and run: direnv allow
```

`.devcontainer/.env.local.example` lists all supported variables. `.devcontainer/.env.local` is gitignored — your keys are never committed.

After rebuilding, run post-login setup:

```bash
bash .devcontainer/scripts/setup-copilot.sh
```

### 9.3 Offline / Air-Gapped Mode

To prevent Copilot from making network requests (useful for network-isolated or regulated environments), export `COPILOT_OFFLINE=true` in your host environment before opening VS Code:

```bash
export COPILOT_OFFLINE=true
code .
```

Or add it permanently to your shell profile. Then rebuild the container.

The `COPILOT_OFFLINE` variable is injected into the container via `containerEnv` (using `${localEnv:COPILOT_OFFLINE}`). The setup script reports its status at startup.

### 9.4 Copilot Setup Script

After first login, run the setup script to install base plugins and apply BYOK/offline config:

```bash
bash .devcontainer/scripts/setup-copilot.sh
```

This replaces the older `install-plugins.sh` (kept for backwards compatibility).

---

> The installation workflow above is also available as an agent skill at `.agents/skills/install-devcontainer/SKILL.md`.
