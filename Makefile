# Unified entry point for Nix-based Flutter development.
# All targets wrap the scripts/ directory.

.PHONY: setup shell shell-pinned build-macos build-macos-fast \
        setup-android shell-android shell-android-pinned \
        build-android \
        setup-android-linux \
        setup-linux shell-linux shell-linux-pinned build-linux build-linux-fast \
        setup-web shell-web shell-web-pinned build-web build-web-fast \
        pin clean

# --- macOS/iOS ---

# Fetch Flutter SDK + pin Nix flake (first-time setup).
setup:
	./nix/pin.sh
	./scripts/fetch-flutter.sh

# Interactive dev shell (uses latest nixpkgs).
shell:
	./scripts/shell-macos.sh

# Interactive dev shell (fully pinned: reproducible).
shell-pinned:
	./scripts/shell-macos.sh --pinned

# CI-friendly macOS build (fully pinned, default).
build-macos:
	./scripts/build-macos.sh

# macOS build with latest nixpkgs (faster, less reproducible).
build-macos-fast:
	./scripts/build-macos.sh --refresh

# --- Android ---

# Fetch Flutter (macOS) + Android SDK components (requires Java on PATH).
setup-android: setup
	./scripts/fetch-android-sdk.sh

# Fetch Flutter (Linux) + Android SDK via Nix android shell (provides Java).
setup-android-linux: setup-linux
	nix develop ./nix#android --command ./scripts/fetch-android-sdk.sh

# Interactive Android dev shell.
shell-android:
	./scripts/shell-android.sh

# Interactive Android dev shell (fully pinned via Nix -- provides Java on any OS).
shell-android-pinned:
	./scripts/shell-android.sh --pinned

# CI-friendly Android APK build (Linux: uses Nix android shell; macOS: uses system Java).
build-android:
	./scripts/build-android.sh

# --- Linux desktop ---

# Fetch Flutter SDK for Linux + pin Nix flake (first-time setup).
setup-linux:
	./nix/pin.sh
	./scripts/fetch-flutter-linux.sh

# Interactive Linux dev shell (uses flake.lock as-is).
shell-linux:
	./scripts/shell-linux.sh

# Interactive Linux dev shell (fully pinned -- reproducible).
shell-linux-pinned:
	./scripts/shell-linux.sh --pinned

# CI-friendly Linux build (fully pinned, default).
build-linux:
	./scripts/build-linux.sh

# Linux build with latest nixpkgs (faster, less reproducible).
build-linux-fast:
	./scripts/build-linux.sh --refresh

# --- Web ---

# Fetch Flutter SDK for web (auto-detects macOS or Linux) + pin Nix flake.
setup-web:
	./nix/pin.sh
	./scripts/fetch-flutter-web.sh

# Interactive web dev shell (uses flake.lock as-is).
shell-web:
	./scripts/shell-web.sh

# Interactive web dev shell (fully pinned -- reproducible).
shell-web-pinned:
	./scripts/shell-web.sh --pinned

# CI-friendly web build (fully pinned, default).
build-web:
	./scripts/build-web.sh

# Web build with latest nixpkgs (faster, less reproducible).
build-web-fast:
	./scripts/build-web.sh --refresh

# --- Utility ---

# Re-pin nixpkgs to current versions.
pin:
	./nix/pin.sh

# Remove fetched SDKs and build artifacts.
clean:
	rm -rf .flutter-sdk .android-sdk build ios/Pods macos/Pods
