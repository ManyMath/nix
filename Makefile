# Unified entry point for Nix-based Flutter development (macOS/iOS).
# All targets wrap the scripts/ directory.

.PHONY: setup shell shell-pinned build-macos build-macos-fast pin clean

# Fetch Flutter SDK + pin Nix flake (first-time setup).
setup:
	./nix/pin.sh
	./scripts/fetch-flutter.sh

# Interactive dev shell (uses latest nixpkgs).
shell:
	./scripts/shell-macos.sh

# Interactive dev shell (fully pinned -- reproducible).
shell-pinned:
	./scripts/shell-macos.sh --pinned

# CI-friendly macOS build (fully pinned).
build-macos:
	./scripts/build-macos.sh --pinned

# macOS build with latest nixpkgs (faster, less reproducible).
build-macos-fast:
	./scripts/build-macos.sh

# --- Utility targets ---

# Re-pin nixpkgs to current versions.
pin:
	./nix/pin.sh

# Remove fetched SDKs and build artifacts.
clean:
	rm -rf .flutter-sdk build example/build example/ios/Pods example/macos/Pods
