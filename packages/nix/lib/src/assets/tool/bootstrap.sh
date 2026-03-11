#!/usr/bin/env bash
set -euo pipefail

find_project_root() {
    local tool_root="$1"
    local candidate

    candidate="$(dirname "$tool_root")"
    while [ "$candidate" != "/" ]; do
        if [ -f "$candidate/pubspec.yaml" ]; then
            printf '%s\n' "$candidate"
            return
        fi
        candidate="$(dirname "$candidate")"
    done

    if [ -f "$tool_root/pubspec.yaml" ]; then
        printf '%s\n' "$tool_root"
        return
    fi

    printf '%s\n' "$tool_root"
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL_ROOT="${TOOL_ROOT:-$SCRIPT_DIR}"
TOOL_ROOT="$(cd "$TOOL_ROOT" && pwd)"

if [ -n "${PROJECT_ROOT:-}" ]; then
    PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
else
    PROJECT_ROOT="$(find_project_root "$TOOL_ROOT")"
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
echo "Toolkit dir: $TOOL_ROOT"
echo "Project root: $PROJECT_ROOT"
echo

copy_if_missing "$TOOL_ROOT/flutter_version.env.example" \
    "$PROJECT_ROOT/flutter_version.env" \
    "flutter_version.env"
copy_if_missing "$TOOL_ROOT/android_sdk_version.env.example" \
    "$PROJECT_ROOT/android_sdk_version.env" \
    "android_sdk_version.env"
copy_if_missing "$TOOL_ROOT/nix.yaml.example" \
    "$PROJECT_ROOT/nix.yaml.example" \
    "nix.yaml.example"

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
