#!/usr/bin/env bash
# Build the Flutter Android APK.
# Non-interactive -- suitable for CI.
# On Linux, uses the pinned Nix android shell to provide Java (JDK 17).
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Detect host OS.
case "$(uname -s)" in
    Darwin) HOST_OS="mac" ;;
    Linux)  HOST_OS="linux" ;;
    *)      echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

# Locate Flutter SDK.
if [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
    FLUTTER_DIR="$PROJECT_ROOT/.flutter-sdk/flutter"
elif command -v flutter &>/dev/null; then
    FLUTTER_DIR="$(dirname "$(dirname "$(command -v flutter)")")"
else
    if [ "$HOST_OS" = "linux" ]; then
        echo "Flutter SDK not found. Run scripts/fetch-flutter-linux.sh first."
    else
        echo "Flutter SDK not found. Run scripts/fetch-flutter.sh first."
    fi
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

FLAKE_DIR="${NIX_FLAKE_DIR:-$PROJECT_ROOT/nix}"

# On Linux, delegate to the Nix android shell which provides JDK 17.
if [ "$HOST_OS" = "linux" ]; then
    export FLUTTER_NIX_FLUTTER_DIR="$FLUTTER_DIR"
    export FLUTTER_NIX_ANDROID_DIR="$ANDROID_DIR"
    export FLUTTER_NIX_PROJECT_ROOT="$PROJECT_ROOT"

    # Single-quoted heredoc: $ signs expand at runtime inside the Nix shell.
    BUILD_CMD='set -euo pipefail
export PATH="$FLUTTER_NIX_FLUTTER_DIR/bin:$JAVA_HOME/bin:$FLUTTER_NIX_ANDROID_DIR/platform-tools:$FLUTTER_NIX_ANDROID_DIR/cmdline-tools/latest/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_NIX_FLUTTER_DIR"
export ANDROID_HOME="$FLUTTER_NIX_ANDROID_DIR"
export ANDROID_SDK_ROOT="$FLUTTER_NIX_ANDROID_DIR"
cd "$FLUTTER_NIX_PROJECT_ROOT"

echo "--- flutter pub get ---"
flutter pub get

echo "--- flutter build apk ---"
flutter build apk --release

echo "Build complete."
ls -la build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || true'

    echo "Building Android APK via Nix android shell..."
    exec nix develop "$FLAKE_DIR#android" --command bash -c "$BUILD_CMD"
fi

# macOS: find Java manually.
if [ -n "${JAVA_HOME:-}" ] && [ -d "$JAVA_HOME" ]; then
    JAVA="$JAVA_HOME"
elif [ -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home" ]; then
    JAVA="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
elif command -v java &>/dev/null; then
    JAVA="$(dirname "$(dirname "$(command -v java)")")"
else
    echo "Java not found. Set JAVA_HOME or install Android Studio."
    exit 1
fi

export PATH="$FLUTTER_DIR/bin:$JAVA/bin:$ANDROID_DIR/platform-tools:$ANDROID_DIR/cmdline-tools/latest/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_DIR"
export ANDROID_HOME="$ANDROID_DIR"
export ANDROID_SDK_ROOT="$ANDROID_DIR"
export JAVA_HOME="$JAVA"

cd "$PROJECT_ROOT"

echo "--- flutter pub get ---"
flutter pub get

echo "--- flutter build apk ---"
flutter build apk --release

echo "Build complete."
ls -la build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || true
