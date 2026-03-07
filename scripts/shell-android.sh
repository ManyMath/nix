#!/usr/bin/env bash
# Enter a development shell for Android Flutter development.
#
# Usage:
#   ./scripts/shell-android.sh              # uses system Java + Android SDK
#   ./scripts/shell-android.sh --pinned     # uses Nix shell (fully reproducible)
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Locate Flutter SDK.
if [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
    FLUTTER_DIR="$PROJECT_ROOT/.flutter-sdk/flutter"
elif command -v flutter &>/dev/null; then
    FLUTTER_DIR="$(dirname "$(dirname "$(command -v flutter)")")"
else
    echo "Flutter SDK not found. Run scripts/fetch-flutter.sh first."
    exit 1
fi

# Locate Android SDK.
if [ -d "$PROJECT_ROOT/.android-sdk" ]; then
    ANDROID_DIR="$PROJECT_ROOT/.android-sdk"
elif [ -d "$HOME/Library/Android/sdk" ]; then
    ANDROID_DIR="$HOME/Library/Android/sdk"
elif [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME" ]; then
    ANDROID_DIR="$ANDROID_HOME"
else
    echo "Android SDK not found. Run scripts/fetch-android-sdk.sh first."
    exit 1
fi

# Locate Java.
if [ -n "${JAVA_HOME:-}" ] && [ -d "$JAVA_HOME" ]; then
    JAVA="$JAVA_HOME"
elif [ -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home" ]; then
    JAVA="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
else
    echo "Java not found. Set JAVA_HOME or install Android Studio."
    exit 1
fi

export PROJECT_ROOT

if [ "${1:-}" = "--pinned" ]; then
    echo "Using pinned Nix shell + Android SDK"
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
    exec nix develop "$PROJECT_ROOT/nix" --command bash --init-file <(cat <<INITEOF
export PATH="$FLUTTER_DIR/bin:$JAVA/bin:$ANDROID_DIR/platform-tools:$ANDROID_DIR/cmdline-tools/latest/bin:\$PATH"
export FLUTTER_ROOT="$FLUTTER_DIR"
export ANDROID_HOME="$ANDROID_DIR"
export ANDROID_SDK_ROOT="$ANDROID_DIR"
export JAVA_HOME="$JAVA"
export PROJECT_ROOT="$PROJECT_ROOT"
echo "Ready. Flutter + Android SDK provided."
echo "Try: flutter doctor"
INITEOF
)
else
    echo "Using system Java + Android SDK"
    exec bash --init-file <(cat <<INITEOF
export PATH="$FLUTTER_DIR/bin:$JAVA/bin:$ANDROID_DIR/platform-tools:$ANDROID_DIR/cmdline-tools/latest/bin:\$PATH"
export FLUTTER_ROOT="$FLUTTER_DIR"
export ANDROID_HOME="$ANDROID_DIR"
export ANDROID_SDK_ROOT="$ANDROID_DIR"
export JAVA_HOME="$JAVA"
export PROJECT_ROOT="$PROJECT_ROOT"
echo "Ready. Flutter + Android SDK provided."
echo "Try: flutter doctor"
INITEOF
)
fi
