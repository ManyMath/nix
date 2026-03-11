# Makefile.inc: include this from your host project's Makefile.
# Usage:
#   NIX_FLUTTER_DIR ?= nix
#   include $(NIX_FLUTTER_DIR)/Makefile.inc

NIX_FLUTTER_DIR ?= nix
NIX_FLUTTER_SCRIPTS := $(NIX_FLUTTER_DIR)/scripts
NIX_FLUTTER_FLAKE := $(CURDIR)/$(NIX_FLUTTER_DIR)/nix
NIX_FLUTTER_BOOTSTRAP := $(NIX_FLUTTER_DIR)/bootstrap.sh
NIX_DART_BIN := $(shell command -v nix_dart 2>/dev/null)
NIX_DART_READY := $(if $(and $(NIX_DART_BIN),$(wildcard $(CURDIR)/nix.yaml)),yes,)

.PHONY: nix-bootstrap nix-setup nix-shell nix-shell-pinned \
	nix-build-macos nix-build-macos-fast nix-setup-android \
	nix-setup-android-linux nix-shell-android nix-shell-android-pinned \
	nix-build-android nix-setup-linux nix-shell-linux \
	nix-shell-linux-pinned nix-build-linux nix-build-linux-fast \
	nix-setup-web nix-shell-web nix-shell-web-pinned \
	nix-build-web nix-build-web-fast nix-pin nix-sync nix-clean

nix-bootstrap:
	PROJECT_ROOT="$(CURDIR)" $(NIX_FLUTTER_BOOTSTRAP)

nix-setup:
ifdef NIX_DART_READY
	nix_dart setup && nix_dart sync
else
	PROJECT_ROOT="$(CURDIR)" $(NIX_FLUTTER_SCRIPTS)/fetch-flutter.sh
endif

nix-shell:
ifdef NIX_DART_READY
	nix_dart shell macos
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/shell-macos.sh
endif

nix-shell-pinned:
ifdef NIX_DART_READY
	nix_dart shell macos
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/shell-macos.sh --pinned
endif

nix-build-macos:
ifdef NIX_DART_READY
	nix_dart build macos
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/build-macos.sh
endif

nix-build-macos-fast:
ifdef NIX_DART_READY
	nix_dart build macos --refresh
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/build-macos.sh --refresh
endif

nix-setup-android:
ifdef NIX_DART_READY
	nix_dart setup android && nix_dart sync
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/fetch-android-sdk.sh
endif

nix-setup-android-linux:
ifdef NIX_DART_READY
	nix_dart setup android && nix_dart sync
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" nix develop "$(NIX_FLUTTER_FLAKE)#android" --command $(NIX_FLUTTER_SCRIPTS)/fetch-android-sdk.sh
endif

nix-shell-android:
ifdef NIX_DART_READY
	nix_dart shell android
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/shell-android.sh
endif

nix-shell-android-pinned:
ifdef NIX_DART_READY
	nix_dart shell android
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/shell-android.sh --pinned
endif

nix-build-android:
ifdef NIX_DART_READY
	nix_dart build android
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/build-android.sh
endif

nix-setup-linux:
ifdef NIX_DART_READY
	nix_dart setup linux && nix_dart sync
else
	PROJECT_ROOT="$(CURDIR)" $(NIX_FLUTTER_SCRIPTS)/fetch-flutter-linux.sh
endif

nix-shell-linux:
ifdef NIX_DART_READY
	nix_dart shell linux
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/shell-linux.sh
endif

nix-shell-linux-pinned:
ifdef NIX_DART_READY
	nix_dart shell linux
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/shell-linux.sh --pinned
endif

nix-build-linux:
ifdef NIX_DART_READY
	nix_dart build linux
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/build-linux.sh
endif

nix-build-linux-fast:
ifdef NIX_DART_READY
	nix_dart build linux --refresh
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/build-linux.sh --refresh
endif

nix-setup-web:
ifdef NIX_DART_READY
	nix_dart setup web && nix_dart sync
else
	PROJECT_ROOT="$(CURDIR)" $(NIX_FLUTTER_SCRIPTS)/fetch-flutter-web.sh
endif

nix-shell-web:
ifdef NIX_DART_READY
	nix_dart shell web
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/shell-web.sh
endif

nix-shell-web-pinned:
ifdef NIX_DART_READY
	nix_dart shell web
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/shell-web.sh --pinned
endif

nix-build-web:
ifdef NIX_DART_READY
	nix_dart build web
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/build-web.sh
endif

nix-build-web-fast:
ifdef NIX_DART_READY
	nix_dart build web --refresh
else
	PROJECT_ROOT="$(CURDIR)" NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_SCRIPTS)/build-web.sh --refresh
endif

nix-pin:
ifdef NIX_DART_READY
	nix_dart pin
else
	NIX_FLAKE_DIR="$(NIX_FLUTTER_FLAKE)" $(NIX_FLUTTER_DIR)/nix/pin.sh
endif

nix-sync:
ifdef NIX_DART_READY
	nix_dart sync
else
ifdef NIX_DART_BIN
	@echo "nix_dart is available, but nix.yaml was not found in $(CURDIR)."
	@echo "Run: nix_dart init --from-existing"
	@echo "Or continue using the shell-script workflow without nix_dart."
else
	@echo "nix_dart not found. Install with: dart pub global activate nix"
	@echo "Then run: nix_dart init --from-existing"
endif
endif

nix-clean:
	rm -rf .flutter-sdk .android-sdk build ios/Pods macos/Pods
