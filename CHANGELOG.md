# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
