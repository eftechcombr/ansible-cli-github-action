#!/bin/sh
set -e

. /tmp/ansible_smoke_image 2>/dev/null || IMG_LABEL="ansible-cli-smoke:test"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== smoke_playbook: Ansible playbook parsing and local run ==="

echo "  -> syntax check"
docker run --rm -v "$SCRIPT_DIR:/tests:ro" "$IMG_LABEL" \
  "ansible-playbook --syntax-check /tests/test.yml"

echo "  -> ping localhost"
docker run --rm -v "$SCRIPT_DIR:/tests:ro" "$IMG_LABEL" \
  "ansible-playbook -i 'localhost,' -c local /tests/test.yml"

echo "PASS: smoke_playbook"
