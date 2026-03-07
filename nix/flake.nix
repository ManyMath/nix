{
  description = "Reproducible Flutter dev environment for macOS/iOS via Nix.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              ruby cocoapods
              git curl unzip
              cmake ninja pkg-config
            ];

            shellHook = ''
              # --- Neutralise Nix compiler/linker env so Xcode builds work ---
              # mkShell brings in clang-wrapper, cctools-binutils-wrapper, and
              # xcbuild shims that conflict with the native Xcode toolchain
              # Flutter requires.  We only want Nix for ancillary tools
              # (ruby, cocoapods, git, …), not for C/C++/Swift compilation.
              unset SDKROOT NIX_CC NIX_BINTOOLS
              unset NIX_CFLAGS_COMPILE NIX_LDFLAGS
              unset NIX_ENFORCE_NO_NATIVE NIX_HARDENING_ENABLE
              unset NIX_DONT_SET_RPATH NIX_DONT_SET_RPATH_FOR_BUILD
              unset NIX_NO_SELF_RPATH NIX_IGNORE_LD_THROUGH_GCC
              unset NIX_BINTOOLS_WRAPPER_TARGET_HOST_aarch64_apple_darwin
              unset NIX_CC_WRAPPER_TARGET_HOST_aarch64_apple_darwin
              unset NIX_PKG_CONFIG_WRAPPER_TARGET_TARGET_aarch64_apple_darwin
              unset MACOSX_DEPLOYMENT_TARGET NIX_APPLE_SDK_VERSION
              unset CC CXX LD AR NM RANLIB OBJCOPY OBJDUMP AS STRIP SIZE
              unset CMAKE_INCLUDE_PATH CMAKE_LIBRARY_PATH
              unset NIXPKGS_CMAKE_PREFIX_PATH CONFIG_SHELL
              unset LD_DYLD_PATH HOST_PATH

              # Strip Nix compiler/linker/xcbuild paths from PATH so Xcode
              # finds its own toolchain.  Keep only Nix paths for the tools
              # we actually want (ruby, cocoapods, git, curl, cmake, etc.).
              CLEAN_PATH=""
              IFS=':' read -ra PARTS <<< "$PATH"
              for p in "''${PARTS[@]}"; do
                case "$p" in
                  *clang-wrapper*|*clang-16*|*cctools-binutils*|*xcbuild*|*apple-sdk*|*compiler-rt*|*libcxx*) continue ;;
                  *) CLEAN_PATH="''${CLEAN_PATH:+$CLEAN_PATH:}$p" ;;
                esac
              done
              export PATH="/usr/bin:$CLEAN_PATH"

              if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
                export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
              fi

              echo "Nix dev shell (${system})"
              if [ -z "''${PROJECT_ROOT:-}" ]; then
                echo "Tip: use scripts/shell-macos.sh or set PROJECT_ROOT"
              elif [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                echo "Flutter SDK: $FLUTTER_ROOT"
              fi
            '';
          };
        }
      );
    };
}
