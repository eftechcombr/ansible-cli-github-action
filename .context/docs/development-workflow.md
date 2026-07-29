---
type: doc
name: development-workflow
description: Day-to-day engineering processes, branching, and contribution guidelines
category: workflow
generated: 2026-07-29
status: filled
---

# Development Workflow

## Prerequisites

- Docker
- Git

## Local Development

1. Clone the repository
2. Build the Docker image:
   ```bash
   docker compose build
   ```
3. Run the full smoke test suite:
   ```bash
   tests/smoke_build.sh && tests/smoke_ansible.sh && tests/smoke_python.sh && tests/smoke_shell.sh && tests/smoke_playbook.sh
   ```
4. Or test a single command:
   ```bash
   docker run --rm eftechcombr/ansible-cli-github-action "ansible --version"
   ```

## Making Changes

- Edit the appropriate file (`Dockerfile`, `entrypoint.sh`, `requirements.txt`, `action.yml`)
- Rebuild and run the smoke test suite locally
- Update `README.md` if the interface changes
- Verify all five smoke tests pass before committing

## CI/CD

The repository has two workflows (see `.github/workflows/`):

- **test.yaml** — Runs automatically on every push (any branch) and pull request (targeting master). Executes all five smoke tests: build, ansible CLI, Python imports, shell passthrough, and playbook execution. Can also be triggered manually via `workflow_dispatch`.
- **build.yaml** — Manually triggered workflow that builds the Docker image using `docker/build-push-action` (no push).

## Contribution Guidelines

- Follow conventional commits for PR titles
- Test changes locally with the full smoke test suite
- Ensure all five smoke tests pass
- Update `README.md` for any interface or input changes
