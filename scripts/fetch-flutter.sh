#!/usr/bin/env bash
# Download and verify a pinned Flutter SDK (macOS).
# The SDK is stored in .flutter-sdk/ (git-ignored).
# Supports x86_64 and arm64.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/flutter_version.env"

SDK_DIR="$PROJECT_ROOT/.flutter-sdk"

# Detect host architecture.
case "$(uname -m)" in
    x86_64|amd64)  ARCH="_x64" ;;
    arm64|aarch64) ARCH="_arm64" ;;
    *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

ARCHIVE="flutter_macos${ARCH}_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.zip"
URL="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/macos/$ARCHIVE"

if [ -d "$SDK_DIR/flutter" ] && "$SDK_DIR/flutter/bin/flutter" --version 2>/dev/null | grep -q "$FLUTTER_VERSION"; then
    echo "Flutter $FLUTTER_VERSION already present in $SDK_DIR"
    exit 0
fi

echo "Downloading Flutter $FLUTTER_VERSION ($FLUTTER_CHANNEL) for $(uname -m)..."
mkdir -p "$SDK_DIR"
cd "$SDK_DIR"

if ! curl -fLO "$URL"; then
    echo "ERROR: Failed to download $URL"
    rm -f "$ARCHIVE"
    exit 1
fi

# Select the correct hash for this architecture.
HASH=""
if [ "$ARCH" = "_arm64" ] && [ -n "${FLUTTER_SHA256_ARM64:-}" ]; then
    HASH="$FLUTTER_SHA256_ARM64"
elif [ "$ARCH" = "_x64" ] && [ -n "${FLUTTER_SHA256_X64:-}" ]; then
    HASH="$FLUTTER_SHA256_X64"
fi

if [ -n "$HASH" ]; then
    echo "Verifying checksum..."
    echo "$HASH  $ARCHIVE" | shasum -a 256 -c -
else
    COMPUTED="$(shasum -a 256 "$ARCHIVE" | cut -d' ' -f1)"
    echo ""
    echo "WARNING: No SHA-256 hash set for $(uname -m) in flutter_version.env."
    echo "Archive downloaded but NOT verified. Add this hash and re-run:"
    echo ""
    if [ "$ARCH" = "_x64" ]; then
        echo "  FLUTTER_SHA256_X64=\"$COMPUTED\""
    else
        echo "  FLUTTER_SHA256_ARM64=\"$COMPUTED\""
    fi
    echo ""
    echo "Proceeding with unverified archive (first-time setup only)."
fi

echo "Extracting..."
unzip -qo "$ARCHIVE"
rm "$ARCHIVE"

echo "Flutter SDK ready at $SDK_DIR/flutter"
echo "Version:"
"$SDK_DIR/flutter/bin/flutter" --version
