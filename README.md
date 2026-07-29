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


## Enabling WinRM on Windows Nodes for Ansible

WinRM (Windows Remote Management) is Microsoft's implementation of the WS-Management protocol. Ansible uses WinRM to communicate with Windows hosts because Windows does not ship with an SSH server by default. Before you can manage a Windows node with Ansible, WinRM must be enabled and configured on that node.

### 1. Enable WinRM on the Windows node

Run the following commands in an **elevated PowerShell** session (Run as Administrator) on each Windows target:

```powershell
# Quick configuration of WinRM listener
winrm quickconfig -q

# Enable WSMan CredSSP (required for credential delegation)
Enable-WSManCredSSP -Role Server -Force
```

`winrm quickconfig` does the following:
- Starts the WinRM service and sets it to auto-start.
- Creates an HTTP listener on port `5985`.
- Adds a firewall exception for WS-Management traffic.

### 2. Configure the firewall

If the firewall rules are not created automatically, or if you need HTTPS access on port `5986`, add them manually:

```powershell
New-NetFirewallRule -DisplayName "Allow WinRM TCP 5985 (HTTP)"  -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
New-NetFirewallRule -DisplayName "Allow WinRM TCP 5986 (HTTPS)" -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
```

| Port | Protocol | Use |
|------|----------|-----|
| 5985 | HTTP     | Default WinRM listener (can be encrypted via Kerberos/NTLM) |
| 5986 | HTTPS    | WinRM over SSL (requires a certificate) |

### 3. Set up HTTPS with a self-signed certificate (optional but recommended)

For production environments, use HTTPS with a valid certificate signed by a trusted CA. For testing, you can create a self-signed certificate:

```powershell
# Create a self-signed certificate
$cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My `
    -DnsName "$env:COMPUTERNAME" -FriendlyName "WinRM HTTPS"

# Create the HTTPS listener
New-Item -Path WSMan:\Localhost\Listener -Transport HTTPS -Address * `
    -CertificateThumbprint $cert.Thumbprint -Force
```

When using a self-signed certificate, set `ansible_winrm_server_cert_validation=ignore` in your Ansible inventory to bypass certificate validation.

### 4. Verify WinRM is listening

On the Windows node itself, confirm the listeners are active:

```powershell
winrm enumerate winrm/config/Listener
```

You should see output similar to:

```
Listener
    Address = *
    Transport = HTTP
    Port = 5985
    Enabled = true
    ...

Listener
    Address = *
    Transport = HTTPS
    Port = 5986
    Enabled = true
    ...
```

### 5. Test WinRM connectivity from the control node

From the Ansible control node (or the GitHub Actions runner), verify you can reach the Windows host over WinRM **before** running playbooks:

```bash
# Test HTTP (port 5985)
ansible windows -i inventory.ini -m ansible.windows.win_ping

# Or use the ansible-cli action locally via Docker
docker run --rm eftechcombr/ansible-cli-github-action \
    ansible windows -i inventory.ini -m ansible.windows.win_ping
```

If connectivity fails, check that:
- The Windows node is reachable from the runner (no firewall blocking).
- The WinRM service is running (`Get-Service WinRM`).
- The `ansible_user` has the necessary permissions.
- CredSSP or the chosen transport (NTLM, Kerberos) is correctly configured.

### 6. Inventory variables for Windows nodes

When using the `ansible-cli` action with Windows targets, your inventory must include the following variables:

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

| Variable | Value | Purpose |
|----------|-------|---------|
| `ansible_connection` | `winrm` | Tells Ansible to use the WinRM connection plugin instead of SSH. |
| `ansible_winrm_transport` | `ntlm` / `credssp` / `kerberos` | Authentication protocol. NTLM works for most environments; CredSSP is needed for credential delegation (e.g., when the playbook needs to pass credentials to a second host). |
| `ansible_user` | `Administrator` | Local or domain user with admin privileges. |
| `ansible_password` | `{{ password_variable }}` | The user's password (use secrets in CI). |
| `ansible_winrm_server_cert_validation` | `ignore` | Required when using a self-signed certificate. Omit or set to `validate` for CA-signed certs. |

### 7. Common issues and tips

**Python fork-safety on macOS**  
If you are developing or testing locally on macOS with zsh, you may encounter crashes when Ansible spawns subprocesses. Add this to your `.zshrc`:

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

**pywinrm is pre-installed**  
The `ansible-cli-github-action` Docker image includes `pywinrm[credssp]`, so no additional Python packages are needed when running inside GitHub Actions. For local testing, install it with:

```bash
python3 -m venv env
source env/bin/activate
pip install pywinrm[credssp] ansible
```

**Transport selection**  
- **NTLM** — Simplest; works across domains; does not support double-hop (passing credentials to a second machine).
- **CredSSP** — Enables double-hop; requires `Enable-WSManCredSSP -Role Server -Force` on the Windows host.
- **Kerberos** — Best for domain-joined hosts; provides the strongest security but requires additional setup (keytab or `kinit`).

**Reference links**  
- [Ansible Windows WinRM guide](https://docs.ansible.com/ansible/latest/os_guide/windows_winrm.html)
- [Homebrew and Python PEP 668](https://docs.brew.sh/Homebrew-and-Python#pep-668-python312-and-virtual-environments)


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
