#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXPECTED_FILE_DEFAULT="$ROOT_DIR/expected-hashes/web-main.dart.js.sha256"
ARTIFACT="$ROOT_DIR/build/web/main.dart.js"

hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

if [ ! -f "$ARTIFACT" ]; then
    echo "Web release artifact not found. Run: make build-web" >&2
    exit 1
fi

actual_hash="$(hash_file "$ARTIFACT")"

if [ "${1:-}" = "--check" ]; then
    expected_file="${2:-$EXPECTED_FILE_DEFAULT}"
    if [ ! -f "$expected_file" ]; then
        echo "Expected hash file not found: $expected_file" >&2
        exit 1
    fi

    expected_hash="$(awk 'NF { print $1; exit }' "$expected_file")"

    echo "Artifact: $ARTIFACT"
    echo "Actual:   $actual_hash"
    echo "Expected: $expected_hash"

    if [ "$actual_hash" != "$expected_hash" ]; then
        echo "Hash mismatch." >&2
        exit 1
    fi

    echo "Hash verified."
    exit 0
fi

printf '%s\n' "$actual_hash"
