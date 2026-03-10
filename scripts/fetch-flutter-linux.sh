#!/usr/bin/env bash
# Download and verify a pinned Flutter SDK (Linux).
# The SDK is stored in .flutter-sdk/ (git-ignored).
# Supports x86_64 and aarch64.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/flutter_version.env"

SDK_DIR="$PROJECT_ROOT/.flutter-sdk"

# Detect host architecture.
case "$(uname -m)" in
    x86_64|amd64)  ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

ARCHIVE="flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
URL="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/$ARCHIVE"

if [ -d "$SDK_DIR/flutter" ] && "$SDK_DIR/flutter/bin/flutter" --version 2>/dev/null | grep -q "$FLUTTER_VERSION"; then
    echo "Flutter $FLUTTER_VERSION already present in $SDK_DIR"
    exit 0
fi

echo "Downloading Flutter $FLUTTER_VERSION ($FLUTTER_CHANNEL) for Linux ${ARCH}..."
mkdir -p "$SDK_DIR"
cd "$SDK_DIR"

if ! curl -fLO "$URL"; then
    echo "ERROR: Failed to download $URL"
    rm -f "$ARCHIVE"
    exit 1
fi

# Select the correct hash for this architecture.
HASH=""
if [ "$ARCH" = "arm64" ] && [ -n "${FLUTTER_SHA256_LINUX_ARM64:-}" ]; then
    HASH="$FLUTTER_SHA256_LINUX_ARM64"
elif [ "$ARCH" = "x64" ] && [ -n "${FLUTTER_SHA256_LINUX_X64:-}" ]; then
    HASH="$FLUTTER_SHA256_LINUX_X64"
fi

if [ -n "$HASH" ]; then
    echo "Verifying checksum..."
    echo "$HASH  $ARCHIVE" | sha256sum -c -
else
    COMPUTED="$(sha256sum "$ARCHIVE" | cut -d' ' -f1)"
    echo ""
    echo "ERROR: No SHA-256 hash set for Linux ${ARCH} in flutter_version.env."
    echo "Computed hash for downloaded archive:"
    echo ""
    if [ "$ARCH" = "x64" ]; then
        echo "  FLUTTER_SHA256_LINUX_X64=\"$COMPUTED\""
    else
        echo "  FLUTTER_SHA256_LINUX_ARM64=\"$COMPUTED\""
    fi
    echo ""
    if [ "${1:-}" = "--allow-unverified" ]; then
        echo "Proceeding without verification (--allow-unverified)."
    else
        echo "Add the hash to flutter_version.env and re-run."
        echo "To skip verification (first-time only): $0 --allow-unverified"
        rm -f "$ARCHIVE"
        exit 1
    fi
fi

echo "Extracting..."
tar -xJf "$ARCHIVE"
rm "$ARCHIVE"

echo "Flutter SDK ready at $SDK_DIR/flutter"
echo "Version:"
"$SDK_DIR/flutter/bin/flutter" --version
