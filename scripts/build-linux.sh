#!/usr/bin/env bash
# Build the Flutter Linux app inside a Nix shell.
# This is a non-interactive build -- suitable for CI.
# Defaults to --pinned for reproducibility.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK_DIR="$PROJECT_ROOT/.flutter-sdk/flutter"

if [ ! -d "$SDK_DIR" ]; then
    echo "Flutter SDK not found. Run scripts/fetch-flutter-linux.sh first."
    exit 1
fi

FLAKE_DIR="$PROJECT_ROOT/nix"

export FLUTTER_NIX_SDK_DIR="$SDK_DIR"
export FLUTTER_NIX_PROJECT_ROOT="$PROJECT_ROOT"

BUILD_CMD='
set -euo pipefail
export PATH="$FLUTTER_NIX_SDK_DIR/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_NIX_SDK_DIR"
cd "$FLUTTER_NIX_PROJECT_ROOT"

echo "--- flutter pub get ---"
flutter pub get

echo "--- flutter build linux ---"
flutter build linux --release

echo "Build complete."
ls -la build/linux/x64/release/bundle/ 2>/dev/null || \
ls -la build/linux/arm64/release/bundle/ 2>/dev/null || true
'

if [ "${1:-}" = "--refresh" ]; then
    echo "Building with latest nixpkgs..."
    nix develop "$FLAKE_DIR#linux" --refresh --command bash -c "$BUILD_CMD"
else
    echo "Building with pinned nixpkgs (from flake.lock)..."
    nix develop "$FLAKE_DIR#linux" --command bash -c "$BUILD_CMD"
fi
