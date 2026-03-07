#!/usr/bin/env bash
# Pin nixpkgs to the current flake.lock revision.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT/nix"

echo "Updating flake.lock..."
nix flake update
echo "Pinned. Commit nix/flake.lock to lock this revision."
