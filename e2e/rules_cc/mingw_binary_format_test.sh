#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${BINARY:-}" ]]; then
  echo "BINARY env var must point at the built mingw binary" >&2
  exit 1
fi

pattern="${EXPECTED_PATTERN:-PE32\+ executable (console) x86-64}"

if ! file "$BINARY" | grep -Eq "$pattern"; then
  echo "Expected $BINARY to match pattern '$pattern', got:" >&2
  file "$BINARY" >&2
  exit 1
fi

echo "✅ $BINARY is a PE32+ executable"
