---
type: doc
name: tooling
description: Scripts, IDE settings, automation, and developer productivity tips
category: tooling
generated: 2026-07-29
status: filled
---

# Tooling

## Docker Compose

`docker-compose.yaml` provides a quick way to build and tag the image:

```bash
docker compose build
```

## VS Code Settings

`.vscode/settings.json` contains:

```json
{
    "kiroAgent.configureMCP": "Enabled"
}
```

## GitHub Actions

The CI workflow runs automatically:

- **Test** (`.github/workflows/test.yaml`) — triggered on every push (any branch) and pull request (targeting master). Runs all five smoke tests: build, ansible CLI, Python imports, shell passthrough, and playbook execution. Also supports manual trigger via `workflow_dispatch`.
- **Build** (`.github/workflows/build.yaml`) — manually triggered workflow that builds the Docker image using `docker/build-push-action` (no push to registry).

## Smoke Tests

Five standalone shell scripts live in `tests/`:

| Script | What It Tests |
|---|---|
| `smoke_build.sh` | Docker image builds successfully |
| `smoke_ansible.sh` | Ansible CLI tools are present and runnable |
| `smoke_python.sh` | Python dependencies (`winrm`, `ansible`) are importable |
| `smoke_shell.sh` | Command passthrough and exit code propagation |
| `smoke_playbook.sh` | Playbook syntax checking and localhost execution |

Run the full suite:

```bash
tests/smoke_build.sh && tests/smoke_ansible.sh && tests/smoke_python.sh && tests/smoke_shell.sh && tests/smoke_playbook.sh
```

## Quick Reference

```bash
# Build locally
docker compose build
# or
docker build -t ansible-cli-smoke:test .

# Run all smoke tests
tests/smoke_build.sh && tests/smoke_ansible.sh && tests/smoke_python.sh && tests/smoke_shell.sh && tests/smoke_playbook.sh

# Run a command
docker run --rm eftechcombr/ansible-cli-github-action "ansible --version"

# Interactive shell (for debugging)
docker run --rm -it --entrypoint /bin/bash eftechcombr/ansible-cli-github-action
```

## No Package Manager

This project has no `package.json` — all dependencies are Python-based and managed via `requirements.txt`.
