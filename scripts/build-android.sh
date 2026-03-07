#!/usr/bin/env bash
# Build the Flutter Android app.
# This is a non-interactive build -- suitable for CI.
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
