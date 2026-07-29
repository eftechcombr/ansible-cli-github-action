#!/bin/sh
set -e

. /tmp/ansible_smoke_image 2>/dev/null || IMG_LABEL="ansible-cli-smoke:test"

echo "=== smoke_shell: eval passthrough + exit codes ==="

echo "  -> echo passthrough"
OUTPUT=$(docker run --rm "$IMG_LABEL" "echo hello from ansible")
echo "       output: $OUTPUT"
[ "$OUTPUT" = "hello from ansible" ] || { echo "FAIL: unexpected output"; exit 1; }

echo "  -> exit code propagation (expect exit 42)"
set +e
docker run --rm "$IMG_LABEL" "exit 42"
RC=$?
set -e
echo "       exit code: $RC"
[ "$RC" -eq 42 ] || { echo "FAIL: expected 42, got $RC"; exit 1; }

echo "PASS: smoke_shell"
