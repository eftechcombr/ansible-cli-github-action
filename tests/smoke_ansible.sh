#!/bin/sh
set -e

. /tmp/ansible_smoke_image 2>/dev/null || IMG_LABEL="ansible-cli-smoke:test"

echo "=== smoke_ansible: Ansible CLI tools ==="

echo "  -> ansible --version"
docker run --rm "$IMG_LABEL" "ansible --version"

echo "  -> ansible-playbook --version"
docker run --rm "$IMG_LABEL" "ansible-playbook --version"

echo "  -> ansible-inventory --help"
docker run --rm "$IMG_LABEL" "ansible-inventory --help"

echo "PASS: smoke_ansible"
