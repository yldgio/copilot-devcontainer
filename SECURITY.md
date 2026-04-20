# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| `main` branch | ✅ |

## Reporting a vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

If you discover a security issue in this project (e.g. a secret accidentally committed, a supply-chain risk in a devcontainer feature, or an unsafe default in `setup.sh`), please report it privately:

1. Go to the **Security** tab of this repository.
2. Click **Report a vulnerability**.
3. Provide as much detail as possible: affected file(s), reproduction steps, and potential impact.

You will receive an acknowledgment within **72 hours** and a resolution or mitigation plan within **14 days**.

## Security considerations for this project

- **MCP servers**: HTTP-based servers (`context7`, `microsoft-docs`) communicate over TLS. Stdio-based servers (`azure`, `awesome-copilot`) run as child processes inside the container with no elevated privileges.
- **Docker socket**: `docker-outside-of-docker` mounts the host's `/var/run/docker.sock`. This gives the container full control over the host Docker daemon — be aware of this when using the container in sensitive environments.
- **`setup.sh`**: Downloads external resources (`uv` installer, npm package, git clone). Review the script before running it in regulated environments.
- **Secrets**: Never commit tokens, credentials, or API keys. Use environment variables or a secrets manager.
