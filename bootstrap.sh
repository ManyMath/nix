#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -n "${PROJECT_ROOT:-}" ]; then
    PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
elif [ -f "$SCRIPT_DIR/../pubspec.yaml" ] && [ ! -d "$SCRIPT_DIR/../scripts" ]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    PROJECT_ROOT="$SCRIPT_DIR"
fi

copy_if_missing() {
    local src="$1"
    local dst="$2"
    local label="$3"
    if [ -f "$dst" ]; then
        echo "  $label already exists, skipping."
    else
        cp "$src" "$dst"
        echo "  created $label"
    fi
}

echo "=== nix bootstrap ==="
echo "Toolkit dir: $SCRIPT_DIR"
echo "Project root: $PROJECT_ROOT"
echo

copy_if_missing "$SCRIPT_DIR/flutter_version.env.example" \
    "$PROJECT_ROOT/flutter_version.env" \
    "flutter_version.env"
copy_if_missing "$SCRIPT_DIR/android_sdk_version.env.example" \
    "$PROJECT_ROOT/android_sdk_version.env" \
    "android_sdk_version.env"

echo
echo "Next steps:"
echo "  1. Run the setup target for your host OS:"
echo "     make nix-setup          # macOS/iOS"
echo "     make nix-setup-linux    # Linux desktop"
echo "     make nix-setup-web      # Web"
echo "  2. If you want the Dart CLI bridge, install it and import the existing setup:"
echo "     dart pub global activate nix"
echo "     nix_dart init --from-existing"
echo
