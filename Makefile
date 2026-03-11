NIX_FLUTTER_DIR ?= .
include $(NIX_FLUTTER_DIR)/Makefile.inc

.PHONY: bootstrap setup shell shell-pinned build-macos build-macos-fast \
	setup-android setup-android-linux shell-android shell-android-pinned \
	build-android setup-linux shell-linux shell-linux-pinned build-linux \
	build-linux-fast setup-web shell-web shell-web-pinned build-web \
	build-web-fast hash-web verify-web verify-example-web pin sync clean

bootstrap: nix-bootstrap

setup: nix-setup

shell: nix-shell

shell-pinned: nix-shell-pinned

build-macos: nix-build-macos

build-macos-fast: nix-build-macos-fast

setup-android: nix-setup-android

setup-android-linux: nix-setup-android-linux

shell-android: nix-shell-android

shell-android-pinned: nix-shell-android-pinned

build-android: nix-build-android

setup-linux: nix-setup-linux

shell-linux: nix-shell-linux

shell-linux-pinned: nix-shell-linux-pinned

build-linux: nix-build-linux

build-linux-fast: nix-build-linux-fast

setup-web: nix-setup-web

shell-web: nix-shell-web

shell-web-pinned: nix-shell-web-pinned

build-web: nix-build-web

build-web-fast: nix-build-web-fast

hash-web:
	./tool/hash_web_release.sh

verify-web:
	./tool/hash_web_release.sh --check

verify-example-web: build-web verify-web

pin: nix-pin

sync: nix-sync

clean: nix-clean
