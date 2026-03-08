#!/usr/bin/env bash
# Download and verify a pinned Flutter SDK for web development.
# Flutter web uses the same SDK as the host platform (macOS or Linux).
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

case "$(uname -s)" in
    Darwin)
        echo "macOS detected -- using macOS Flutter SDK for web development."
        exec "$PROJECT_ROOT/scripts/fetch-flutter.sh" "$@"
        ;;
    Linux)
        echo "Linux detected -- using Linux Flutter SDK for web development."
        exec "$PROJECT_ROOT/scripts/fetch-flutter-linux.sh" "$@"
        ;;
    *)
        echo "ERROR: Unsupported OS: $(uname -s)"
        echo "Flutter web builds are supported on macOS and Linux."
        exit 1
        ;;
esac
