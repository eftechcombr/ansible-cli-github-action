---
type: doc
name: testing-strategy
description: Test frameworks, patterns, coverage requirements, and quality gates
category: testing
generated: 2026-07-29
status: filled
---

# Testing Strategy

## Approach

This project is a thin Docker-based GitHub Action. Testing focuses on three areas:

1. **Container build** — ensure the Docker image builds successfully
2. **Command execution** — verify that Ansible is installed and runnable inside the container
3. **Runtime behavior** — verify shell passthrough, exit code propagation, and playbook execution

Smoke tests are implemented as standalone shell scripts in `tests/` that can be run locally or in CI.

## Tests

### Local Testing

Build the image first, then run the full smoke test suite:

```bash
tests/smoke_build.sh && tests/smoke_ansible.sh && tests/smoke_python.sh && tests/smoke_shell.sh && tests/smoke_playbook.sh
```

Individual smoke tests can also be run independently:

```bash
tests/smoke_build.sh            # must run first — sets image tag
tests/smoke_ansible.sh          # checks ansible, ansible-playbook, ansible-inventory
tests/smoke_python.sh           # checks Python dependency imports (winrm, ansible)
tests/smoke_shell.sh            # checks eval passthrough and exit code propagation
tests/smoke_playbook.sh         # checks playbook syntax checking and localhost ping
```

Alternatively, build and test with Docker Compose:

```bash
docker compose build
docker run --rm eftechcombr/ansible-cli-github-action "ansible --version"
```

### CI Testing (GitHub Actions)

The workflow in `.github/workflows/test.yaml` runs all five smoke tests automatically on every push (any branch) and pull request (targeting master). It can also be triggered manually via `workflow_dispatch`.

The CI pipeline executes the same checks as the local smoke scripts:

- **smoke_build** — verifies the Docker image is built
- **smoke_ansible** — runs `ansible --version`, `ansible-playbook --version`, `ansible-inventory --help`
- **smoke_python** — imports `winrm` and `ansible` Python packages
- **smoke_shell** — verifies command output passthrough and exit code propagation
- **smoke_playbook** — runs `ansible-playbook --syntax-check` and a ping playbook against localhost

## Quality Gates

- Docker image must build without errors
- `ansible --version` must exit with code 0
- `ansible-playbook --version` must exit with code 0
- `ansible-inventory --help` must exit with code 0
- Python `winrm` and `ansible` module imports must succeed
- Shell command output must pass through correctly
- Shell exit codes must propagate correctly
- Playbook syntax checking must pass
- Playbook must run successfully against localhost with the `local` connection plugin

## What We Don't Test

- Ansible playbook correctness (the action is a runner, not a linter)
- Specific Ansible modules or features (upstream Ansible tests those)
- Remote host connectivity or SSH configuration
- Multi-node playbook orchestration
