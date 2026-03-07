#!/usr/bin/env bash
# Download and set up pinned Android SDK components (macOS).
# Requires Java on PATH (from Nix shell or Android Studio JBR).
# The SDK is stored in .android-sdk/ (git-ignored).
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/android_sdk_version.env"

SDK_DIR="$PROJECT_ROOT/.android-sdk"
CMDLINE_DIR="$SDK_DIR/cmdline-tools/latest"

# Verify Java is available.
if ! command -v java &>/dev/null; then
    echo "ERROR: java not found on PATH."
    echo "Install via Nix shell or set JAVA_HOME to Android Studio's JBR:"
    echo "  export JAVA_HOME=\"/Applications/Android Studio.app/Contents/jbr/Contents/Home\""
    exit 1
fi

# Skip if sdkmanager already present.
if [ -x "$CMDLINE_DIR/bin/sdkmanager" ]; then
    echo "Android cmdline-tools already present at $CMDLINE_DIR"
else
    ARCHIVE="commandlinetools-mac-${ANDROID_CMDLINE_TOOLS_BUILD}_latest.zip"
    URL="https://dl.google.com/android/repository/$ARCHIVE"

    echo "Downloading Android cmdline-tools (build $ANDROID_CMDLINE_TOOLS_BUILD)..."
    mkdir -p "$SDK_DIR"
    cd "$SDK_DIR"

    if ! curl -fLO "$URL"; then
        echo "ERROR: Failed to download $URL"
        rm -f "$ARCHIVE"
        exit 1
    fi

    # Verify checksum if set.
    if [ -n "${ANDROID_CMDLINE_TOOLS_SHA256:-}" ]; then
        echo "Verifying checksum..."
        echo "$ANDROID_CMDLINE_TOOLS_SHA256  $ARCHIVE" | shasum -a 256 -c -
    else
        COMPUTED="$(shasum -a 256 "$ARCHIVE" | cut -d' ' -f1)"
        echo ""
        echo "WARNING: No SHA-256 hash set in android_sdk_version.env."
        echo "Add this to verify future downloads:"
        echo "  ANDROID_CMDLINE_TOOLS_SHA256=\"$COMPUTED\""
        echo ""
    fi

    echo "Extracting..."
    TMPEXTRACT="$(mktemp -d "$SDK_DIR/extract.XXXXXX")"
    unzip -qo "$ARCHIVE" -d "$TMPEXTRACT"
    rm "$ARCHIVE"

    # Google's archive contains a top-level cmdline-tools/ directory.
    # Move its contents to cmdline-tools/latest/ as sdkmanager expects.
    mkdir -p "$SDK_DIR/cmdline-tools"
    if [ -d "$TMPEXTRACT/cmdline-tools" ]; then
        mv "$TMPEXTRACT/cmdline-tools" "$CMDLINE_DIR"
    else
        echo "ERROR: Unexpected archive structure, no cmdline-tools/ in zip."
        rm -rf "$TMPEXTRACT"
        exit 1
    fi
    rm -rf "$TMPEXTRACT"
fi

# Pre-accept licenses for non-interactive use.
LICENSES_DIR="$SDK_DIR/licenses"
mkdir -p "$LICENSES_DIR"
echo -e "\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$LICENSES_DIR/android-sdk-license"
echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > "$LICENSES_DIR/android-sdk-arm-dbt-license"

echo "Installing SDK components via sdkmanager..."
SDKMANAGER="$CMDLINE_DIR/bin/sdkmanager"
"$SDKMANAGER" --sdk_root="$SDK_DIR" \
    "platform-tools" \
    "platforms;$ANDROID_PLATFORM_VERSION" \
    "build-tools;$ANDROID_BUILD_TOOLS_VERSION" \
    "ndk;$ANDROID_NDK_VERSION"

echo ""
echo "Android SDK ready at $SDK_DIR"
echo "Components installed:"
"$SDKMANAGER" --sdk_root="$SDK_DIR" --list_installed 2>/dev/null | grep -E "^  " || true
