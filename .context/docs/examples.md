## Examples

### Example 1: Windows connection via WinRM

This example runs an Ansible playbook against a Windows target over WinRM. The `pywinrm[credssp]` package is pre-installed in the action's Docker image, so no additional setup is required.

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

The `ansible-playbook` command passes the inventory file and injects the Windows administrator password via the `-e` flag, keeping the secret out of the repository. Because `pywinrm[credssp]` is bundled in the image, WinRM connections work without any additional pip install steps.

---

### Example 2: Linux connection via SSH

This example covers both playbook and ad-hoc command execution against Linux targets over SSH.

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

The first step writes the SSH private key to disk (sourced from a GitHub secret), then sets restrictive permissions so that Ansible's SSH client accepts it. The playbook step executes `ansible-playbook` against all hosts, and the ad-hoc step demonstrates how to run a single module directly with `ansible ... -m ping`.

---

### Example 3: Connection via GitHub Actions self-hosted runner

A self-hosted runner is a machine you deploy and manage yourself to run GitHub Actions workflows. It connects to GitHub and picks up jobs intended for its runner group. Self-hosted runners are useful when you need access to internal networks, on-premises infrastructure, or resources not exposed to the public internet. For more details, see the [GitHub documentation on self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners).

When a job targets a self-hosted runner, the `eftechcombr/ansible-cli-github-action` container runs directly on that machine. Because this action is Docker-based, the runner only needs Docker installed -- it does not need Ansible or Python installed on the host itself. The action's image provides everything required.

Use a self-hosted runner label in the `runs-on` field to target your runner fleet:

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

Because the workflow runs on a self-hosted runner inside the internal network, it can resolve `db-primary.internal.example.com` and `db-replica.internal.example.com` -- hosts that would not be reachable from GitHub-hosted runners. The action's Docker image supplies Ansible and all dependencies, so no additional setup is needed on the runner host.
