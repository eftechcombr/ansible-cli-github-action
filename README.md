# Ansible CLI Github Action

This action is based on the `python:3.11-slim` image.  
You can execute all Ansible-related commands: `ansible`, `ansible-playbook`, `ansible-galaxy`, and others.  
You can also execute standard Linux commands as the base image includes a shell environment.

## Inputs

### `command`

**Required** Command to execute. Default `"ansible-playbook"`.

## Examples

### 1. Windows connection via WinRM

Run a playbook against a Windows target over WinRM. The `pywinrm[credssp]` package is pre-installed in the action's Docker image.

**Inventory (`inventory.ini`):**
```ini
[windows]
windows-server-01.example.com

[windows:vars]
ansible_connection=winrm
ansible_winrm_transport=ntlm
ansible_user=Administrator
ansible_password={{ windows_admin_password }}
ansible_winrm_server_cert_validation=ignore
```

**Playbook (`win-ping.yml`):**
```yaml
---
- name: Verify Windows host connectivity
  hosts: windows
  tasks:
    - name: Test WinRM connection
      ansible.windows.win_ping:
```

**Workflow (`.github/workflows/windows-check.yml`):**
```yaml
name: Windows Connectivity Check

on:
  schedule:
    - cron: "0 6 * * *"
  workflow_dispatch:

jobs:
  winrm-ping:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run WinRM ping playbook
        uses: eftechcombr/ansible-cli-github-action@master
        with:
          command: >
            ansible-playbook win-ping.yml
            -i inventory.ini
            -e windows_admin_password=${{ secrets.WINDOWS_ADMIN_PASSWORD }}
```

---

### 2. Linux connection via SSH

Connect to Linux targets over SSH using a playbook or ad-hoc commands.

**Inventory (`inventory.yml`):**
```yaml
all:
  hosts:
    web-01.example.com:
    web-02.example.com:
  vars:
    ansible_connection: ssh
    ansible_user: ubuntu
    ansible_ssh_private_key_file: /tmp/ssh_key
```

**Playbook (`ping.yml`):**
```yaml
---
- name: Verify Linux host connectivity
  hosts: all
  tasks:
    - name: Test SSH connection
      ansible.builtin.ping:
```

**Workflow (`.github/workflows/linux-check.yml`):**
```yaml
name: Linux Connectivity Check

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  ssh-ping:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install SSH key
        run: |
          mkdir -p /tmp
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > /tmp/ssh_key
          chmod 600 /tmp/ssh_key

      - name: Run playbook
        uses: eftechcombr/ansible-cli-github-action@master
        with:
          command: >
            ansible-playbook ping.yml
            -i inventory.yml

      - name: Ad-hoc ping test
        uses: eftechcombr/ansible-cli-github-action@master
        with:
          command: ansible all -i inventory.yml -m ping
```

---

### 3. Connection via GitHub Actions self-hosted runner

A self-hosted runner is a machine you deploy and manage yourself to run GitHub Actions workflows. Use one when you need access to internal networks or resources not exposed to the public internet. Because this action is Docker-based, the runner only needs Docker installed -- not Ansible or Python.

Target your runner with a label in `runs-on`:
```yaml
runs-on: [self-hosted, linux, production]
```

**Inventory (`inventory.yml`):**
```yaml
all:
  hosts:
    db-primary.internal.example.com:
    db-replica.internal.example.com:
  vars:
    ansible_connection: ssh
    ansible_user: admin
    ansible_ssh_private_key_file: /etc/runner/keys/ansible_rsa
```

**Playbook (`health-check.yml`):**
```yaml
---
- name: Database infrastructure health check
  hosts: all
  tasks:
    - name: Ensure PostgreSQL is accepting connections
      ansible.builtin.wait_for:
        port: 5432
        host: "{{ inventory_hostname }}"
        timeout: 10

    - name: Collect uptime
      ansible.builtin.shell: uptime
      register: result

    - name: Report uptime
      ansible.builtin.debug:
        msg: "{{ inventory_hostname }} uptime: {{ result.stdout }}"
```

**Workflow (`.github/workflows/internal-health.yml`):**
```yaml
name: Internal Infrastructure Health Check

on:
  schedule:
    - cron: "*/15 * * * *"
  workflow_dispatch:

jobs:
  health-check:
    runs-on: [self-hosted, linux, production]
    steps:
      - uses: actions/checkout@v4

      - name: Run health check playbook against internal hosts
        uses: eftechcombr/ansible-cli-github-action@master
        with:
          command: >
            ansible-playbook health-check.yml
            -i inventory.yml
```

Because the workflow runs on a self-hosted runner inside the internal network, it can resolve `db-primary.internal.example.com` -- hosts that would not be reachable from GitHub-hosted runners. The action's Docker image supplies Ansible and all dependencies, so no additional setup is needed on the runner host.

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
