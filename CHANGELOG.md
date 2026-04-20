# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
