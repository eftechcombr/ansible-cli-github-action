#!/bin/sh
set -e

echo "=== smoke_build: Docker image build ==="

IMG_LABEL="ansible-cli-smoke:test"

docker build -t "$IMG_LABEL" .

echo "PASS: smoke_build"
echo "IMG_LABEL=$IMG_LABEL" > /tmp/ansible_smoke_image
