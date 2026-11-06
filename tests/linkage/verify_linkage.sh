#!/usr/bin/env bash
# Verifies how the given ELF binary is linked. Each expectation is one of:
#   fully_static: the binary has no dynamic loader and doesn't need any shared libraries.
#   needs:<suffix>: the binary has a DT_NEEDED entry that ends with suffix.
#   lacks:<suffix>: the binary has no DT_NEEDED entry that ends with suffix.
set -euo pipefail

readelf=$1
binary=$2
shift 2

dynamic=$("$readelf" -d "$binary")

fail() {
  echo "FAIL: $binary: $1" >&2
  echo "$dynamic" >&2
  exit 1
}

for expectation in "$@"; do
  case "$expectation" in
    fully_static)
      if "$readelf" -l "$binary" | grep -q "INTERP"; then
        fail "has a dynamic loader"
      fi
      if grep -q "(NEEDED)" <<<"$dynamic"; then
        fail "needs shared libraries"
      fi
      ;;
    needs:*)
      grep -qF "${expectation#needs:}]" <<<"$dynamic" || fail "doesn't need ${expectation#needs:}"
      ;;
    lacks:*)
      if grep -qF "${expectation#lacks:}]" <<<"$dynamic"; then
        fail "needs ${expectation#lacks:}"
      fi
      ;;
    *)
      echo "unknown expectation: $expectation" >&2
      exit 2
      ;;
  esac
done
