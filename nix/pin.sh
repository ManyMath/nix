#!/usr/bin/env bash
# Pin nixpkgs to the current flake.lock revision.
set -euo pipefail

FLAKE_DIR="${NIX_FLAKE_DIR:-$(cd "$(dirname "$0")" && pwd)}"
cd "$FLAKE_DIR"

echo "Updating flake.lock..."
nix flake update
echo "Pinned. Commit flake.lock to lock this revision."
