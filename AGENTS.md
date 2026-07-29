# AGENTS.md

## Dev environment tips
- Build the Docker image with `docker build -t ansible-cli-smoke:test .` before running tests.
- Use `docker compose build` for the Compose-based build.

## Testing instructions
- Run all smoke tests: `tests/smoke_build.sh && tests/smoke_ansible.sh && tests/smoke_python.sh && tests/smoke_shell.sh && tests/smoke_playbook.sh`
- Or run individual tests: `tests/smoke_build.sh` (must run first — sets image tag), then any of `tests/smoke_ansible.sh`, `tests/smoke_python.sh`, `tests/smoke_shell.sh`, `tests/smoke_playbook.sh`
- CI runs all smoke tests via `.github/workflows/test.yaml` on every push and PR.

## PR instructions
- Follow Conventional Commits (for example, `feat(scaffolding): add doc links`).
- Cross-link new scaffolds in `docs/README.md` and `agents/README.md` so future agents can find them.
- Attach sample CLI output or generated markdown when behaviour shifts.
- Confirm the built artefacts in `dist/` match the new source changes.

## Repository map
- `action.yml` — GitHub Action metadata (inputs, branding, Docker runtime config)
- `docker-compose.yaml` — local dev convenience for building and tagging the image
- `Dockerfile` — builds the container from `python:3.11-slim`
- `entrypoint.sh` — container entrypoint, executes `eval $1`
- `README.md` — user-facing documentation
- `requirements.txt` — Python dependencies (`ansible`, `pywinrm[credssp]`)
- `tests/` — smoke test scripts and test fixtures

## AI Context References
- Documentation index: `.context/docs/README.md`
- Agent playbooks: `.context/agents/README.md`
- Contributor guide: `CONTRIBUTING.md`
