#!/usr/bin/env bash
# Enter a reproducible Nix development shell for Flutter web development.
#
# Usage:
#   ./scripts/shell-web.sh              # uses flake.lock as-is
#   ./scripts/shell-web.sh --pinned     # uses pinned flake.lock (fully reproducible)
#   ./scripts/shell-web.sh --refresh    # updates flake inputs to latest, then enters shell
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SDK_DIR="$PROJECT_ROOT/.flutter-sdk/flutter"

if [ ! -d "$SDK_DIR" ]; then
    echo "Flutter SDK not found. Run scripts/fetch-flutter-web.sh first."
    exit 1
fi

export PROJECT_ROOT

FLAKE_DIR="${NIX_FLAKE_DIR:-$PROJECT_ROOT/nix}"
NIX_ARGS=()

if [ "${1:-}" = "--pinned" ]; then
    echo "Using pinned nixpkgs from nix/flake.lock (reproducible)"
elif [ "${1:-}" = "--refresh" ]; then
    echo "Refreshing nixpkgs inputs to latest..."
    NIX_ARGS+=(--refresh)
else
    echo "Using nixpkgs from nix/flake.lock"
fi

exec nix develop ${NIX_ARGS[@]+"${NIX_ARGS[@]}"} "$FLAKE_DIR#web" --command bash --init-file <(cat <<INITEOF
export PATH="$SDK_DIR/bin:\$PATH"
export FLUTTER_ROOT="$SDK_DIR"
export PROJECT_ROOT="$PROJECT_ROOT"
echo "Ready. Flutter web deps provided by Nix."
echo "Try: flutter doctor"
echo "Build: flutter build web --release"
echo "Serve: python3 -m http.server 8080 -d build/web"
INITEOF
)
