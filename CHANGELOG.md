# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 1.0.0 (2026-04-20)


### Features

* add README/AGENTS, fix docker startup, automate MCP config ([087d090](https://github.com/yldgio/copilot-devcontainer/commit/087d0900ea4edbdee3b8a0784986a688a1407dfd))
* add remote one-liner installer (npx / bash / PowerShell) ([44235d6](https://github.com/yldgio/copilot-devcontainer/commit/44235d64905339fdcf1426ef0ee96b0b94fd8c49))
* update install-plugins script to include additional Copilot CLI plugins ([981146c](https://github.com/yldgio/copilot-devcontainer/commit/981146cfff7683df4bc3d66389189fec576e28d5))
* use official Copilot CLI installer, add optional scripts ([737ef49](https://github.com/yldgio/copilot-devcontainer/commit/737ef492c0f55ee0d622e7a4b9b0eedaf03b11db))


### Bug Fixes

* ci workflow fixes (release-please token, PS abort exit code) ([a06dc7e](https://github.com/yldgio/copilot-devcontainer/commit/a06dc7e86c276a8897495e19dabf5d4de3fef44d))
* make Copilot CLI install robust in postCreateCommand ([b5a755c](https://github.com/yldgio/copilot-devcontainer/commit/b5a755cc2da2a233c8786271d70ff36da1249d91))

## [Unreleased]

### Added

- Remote installer: `install.mjs` (npx), `install.sh` (bash), `install.ps1` (PowerShell) — copies devcontainer files into any repo with a one-liner
- `package.json` — enables `npx github:yldgio/copilot-devcontainer` invocation
- GitHub Actions: `release-please.yml` (automated versioning) and `test-install.yml` (CI tests for all 3 installers)

### Changed

- Removed `python:1` devcontainer feature — Python 3.12 now installed and managed by UV (`uv python install 3.12`), removing the redundant double install
- Removed `azure` and `awesome-copilot` MCP servers from `.mcp.json`
- Removed `install-skills.sh` — skills catalogue not included; use a custom script if needed

### Removed

- `devcontainer-lock.json` removed from version control (regenerated automatically by VS Code)
- `install-skills.sh` script removed from `.devcontainer/scripts/`

## [1.1.0] - 2026-04-20

### Changed

- Copilot CLI install method: replaced `npm install -g @github/copilot` with the official
  binary installer (`curl -fsSL https://gh.io/copilot-install | bash`) — no npm dependency,
  checksum-validated, installs to `$HOME/.local/bin`
- Skills catalogue no longer cloned automatically at container creation — left to the developer
- `setup.sh` simplified: PATH export moved before all installs, cleaner next-steps message

### Added

- `.devcontainer/scripts/install-skills.sh` — optional script to clone the skills catalogue
- `.devcontainer/scripts/install-plugins.sh` — optional script to install Copilot CLI plugins

## [1.0.0] - 2026-04-20

### Added

- Dev container based on `mcr.microsoft.com/devcontainers/base:ubuntu-24.04`
- Features: Git, GitHub CLI, Node.js LTS, Python 3.12, Docker CLI (`docker-outside-of-docker`)
- VS Code extensions: Copilot, Copilot Chat, Python, Pylance, Docker, GitLens
- `setup.sh`: installs UV, GitHub Copilot CLI, and sparse-clones the skills catalogue
- MCP servers: `context7`, `microsoft-docs`, `azure`, `awesome-copilot`
- `.vscode/mcp.json` auto-generated from `.mcp.json` at container creation
- `README.md`, `AGENTS.md`, and full GitHub collaboration docs

### Changed

- Replaced `docker-in-docker` with `docker-outside-of-docker` to eliminate intermittent ~60 s `resolveAuthority` timeout on container startup
