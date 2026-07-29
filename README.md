# Ansible CLI Github Action

This action is based on the `python:3.11-slim` image.  
You can execute all Ansible-related commands: `ansible`, `ansible-playbook`, `ansible-galaxy`, and others.  
You can also execute standard Linux commands as the base image includes a shell environment.

## Inputs

### `command`

**Required** Command to execute. Default `"ansible-playbook"`.

## Example usage

```yaml
uses: eftechcombr/ansible-cli-github-action@latest
with:
  command: "ansible-playbook main.yml"
```

## Testing

Run the smoke test suite locally to verify the Docker image builds and all Ansible tools work correctly:

```bash
tests/smoke_build.sh && tests/smoke_ansible.sh && tests/smoke_python.sh && tests/smoke_shell.sh && tests/smoke_playbook.sh
```

The smoke tests cover:

- Docker image build
- Ansible CLI version checks (`ansible`, `ansible-playbook`, `ansible-inventory`)
- Python dependency imports (`winrm`, `ansible`)
- Shell command passthrough and exit code propagation
- Playbook syntax checking and localhost execution

CI runs these tests automatically on every push and pull request via GitHub Actions.
