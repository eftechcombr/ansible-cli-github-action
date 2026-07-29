#!/bin/sh
set -e

. /tmp/ansible_smoke_image 2>/dev/null || IMG_LABEL="ansible-cli-smoke:test"

echo "=== smoke_python: Python dependency imports ==="

echo "  -> import winrm"
docker run --rm "$IMG_LABEL" "python -c \"import winrm; print('winrm version:', winrm.__version__)\""

echo "  -> import ansible"
docker run --rm "$IMG_LABEL" "python -c \"import ansible; print('ansible loaded ok')\""

echo "PASS: smoke_python"
