{
  description = "Reproducible Flutter dev environment for macOS/iOS/Android/Linux/Web using Nix.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nixpkgs-linux.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, nixpkgs-linux }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      linuxSystems  = [ "x86_64-linux" "aarch64-linux" ];
      allSystems    = darwinSystems ++ linuxSystems;
      forAllDarwin  = nixpkgs.lib.genAttrs darwinSystems;
      forAllLinux   = nixpkgs-linux.lib.genAttrs linuxSystems;
      forAllSystems = nixpkgs.lib.genAttrs allSystems;
      pkgsFor = system:
        if builtins.elem system linuxSystems
        then import nixpkgs-linux { inherit system; }
        else import nixpkgs { inherit system; };
    in {
      devShells =
        # Merge per-system shell maps using recursiveUpdate so shells from
        # different forAll* calls are combined rather than overwritten.
        # Plain // is a shallow merge: forAllSystems (web) would clobber
        # the entire x86_64-linux entry from forAllLinux (linux, android).
        builtins.foldl' nixpkgs.lib.recursiveUpdate {} [

        # macOS/iOS shell -- Nix provides tooling, Xcode owns the compiler.
        (forAllDarwin (system:
          let pkgs = import nixpkgs { inherit system; };
          in {
            # Android shell -- provides JDK 17 for Gradle/sdkmanager on macOS.
            android = pkgs.mkShell {
              buildInputs = with pkgs; [
                jdk17
                git curl unzip
              ];

              shellHook = ''
                # Same Nix-vs-Xcode cleanup as default to avoid toolchain conflicts.
                unset SDKROOT NIX_CC NIX_BINTOOLS
                unset NIX_CFLAGS_COMPILE NIX_LDFLAGS
                unset NIX_ENFORCE_NO_NATIVE NIX_HARDENING_ENABLE
                unset NIX_DONT_SET_RPATH NIX_DONT_SET_RPATH_FOR_BUILD
                unset NIX_NO_SELF_RPATH NIX_IGNORE_LD_THROUGH_GCC
                unset NIX_BINTOOLS_WRAPPER_TARGET_HOST_aarch64_apple_darwin
                unset NIX_CC_WRAPPER_TARGET_HOST_aarch64_apple_darwin
                unset NIX_PKG_CONFIG_WRAPPER_TARGET_TARGET_aarch64_apple_darwin
                unset NIX_BINTOOLS_WRAPPER_TARGET_HOST_x86_64_apple_darwin
                unset NIX_CC_WRAPPER_TARGET_HOST_x86_64_apple_darwin
                unset NIX_PKG_CONFIG_WRAPPER_TARGET_TARGET_x86_64_apple_darwin
                unset MACOSX_DEPLOYMENT_TARGET NIX_APPLE_SDK_VERSION
                unset CC CXX LD AR NM RANLIB OBJCOPY OBJDUMP AS STRIP SIZE
                unset CMAKE_INCLUDE_PATH CMAKE_LIBRARY_PATH
                unset NIXPKGS_CMAKE_PREFIX_PATH CONFIG_SHELL
                unset LD_DYLD_PATH HOST_PATH

                CLEAN_PATH=""
                IFS=':' read -ra PARTS <<< "$PATH"
                for p in "''${PARTS[@]}"; do
                  case "$p" in
                    *clang-wrapper*|*clang-[0-9]*|*cctools-binutils*|*xcbuild*|*apple-sdk*|*compiler-rt*|*libcxx*|*pkg-config-wrapper*) continue ;;
                    *) CLEAN_PATH="''${CLEAN_PATH:+$CLEAN_PATH:}$p" ;;
                  esac
                done
                export PATH="/usr/bin:$CLEAN_PATH"

                echo "Nix Android dev shell (${system})"
                if [ -z "''${PROJECT_ROOT:-}" ]; then
                  echo "Tip: use scripts/shell-android.sh --pinned or set PROJECT_ROOT"
                elif [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                  export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                  export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                  echo "Flutter SDK: $FLUTTER_ROOT"
                fi
              '';
            };

            default = pkgs.mkShell {
              buildInputs = with pkgs; [
                ruby cocoapods
                git curl unzip
                cmake ninja pkg-config
              ];

              shellHook = ''
                # Unset Nix compiler/linker env so Xcode builds work.
                # mkShell pulls in clang-wrapper, cctools-binutils-wrapper, and
                # xcbuild shims that conflict with the Xcode toolchain Flutter
                # needs. Nix should only provide tools like ruby, cocoapods,
                # git, cmake, etc.
                unset SDKROOT NIX_CC NIX_BINTOOLS
                unset NIX_CFLAGS_COMPILE NIX_LDFLAGS
                unset NIX_ENFORCE_NO_NATIVE NIX_HARDENING_ENABLE
                unset NIX_DONT_SET_RPATH NIX_DONT_SET_RPATH_FOR_BUILD
                unset NIX_NO_SELF_RPATH NIX_IGNORE_LD_THROUGH_GCC
                unset NIX_BINTOOLS_WRAPPER_TARGET_HOST_aarch64_apple_darwin
                unset NIX_CC_WRAPPER_TARGET_HOST_aarch64_apple_darwin
                unset NIX_PKG_CONFIG_WRAPPER_TARGET_TARGET_aarch64_apple_darwin
                unset NIX_BINTOOLS_WRAPPER_TARGET_HOST_x86_64_apple_darwin
                unset NIX_CC_WRAPPER_TARGET_HOST_x86_64_apple_darwin
                unset NIX_PKG_CONFIG_WRAPPER_TARGET_TARGET_x86_64_apple_darwin
                unset MACOSX_DEPLOYMENT_TARGET NIX_APPLE_SDK_VERSION
                unset CC CXX LD AR NM RANLIB OBJCOPY OBJDUMP AS STRIP SIZE
                unset CMAKE_INCLUDE_PATH CMAKE_LIBRARY_PATH
                unset NIXPKGS_CMAKE_PREFIX_PATH CONFIG_SHELL
                unset LD_DYLD_PATH HOST_PATH

                # Remove Nix compiler/linker/xcbuild paths from PATH so Xcode
                # finds its own toolchain.
                CLEAN_PATH=""
                IFS=':' read -ra PARTS <<< "$PATH"
                for p in "''${PARTS[@]}"; do
                  case "$p" in
                    *clang-wrapper*|*clang-[0-9]*|*cctools-binutils*|*xcbuild*|*apple-sdk*|*compiler-rt*|*libcxx*|*pkg-config-wrapper*) continue ;;
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
        ))

        # Linux shells -- Nix owns the full toolchain (no Xcode needed).
        (forAllLinux (system:
          let pkgs = import nixpkgs-linux { inherit system; };
          in {
            # Android shell -- provides JDK 17 for Gradle/sdkmanager on Linux.
            android = pkgs.mkShell {
              buildInputs = with pkgs; [
                jdk17
                git curl unzip
              ];

              shellHook = ''
                echo "Nix Android dev shell (${system})"
                if [ -z "''${PROJECT_ROOT:-}" ]; then
                  echo "Tip: use scripts/shell-android.sh --pinned or set PROJECT_ROOT"
                elif [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                  export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                  export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                  echo "Flutter SDK: $FLUTTER_ROOT"
                fi
              '';
            };

            linux = pkgs.mkShell {
              buildInputs = with pkgs; [
                # Build toolchain
                clang cmake ninja pkg-config
                # Flutter Linux desktop dependencies (GTK + system libs)
                gtk3 glib pcre2
                util-linux xz
                xorg.libX11 xorg.libXcursor xorg.libXrandr xorg.libXinerama
                xorg.libXi xorg.libXext xorg.libXfixes xorg.libXrender
                mesa libGL
                # Common dev tools
                git curl unzip
              ];

              shellHook = ''
                echo "Nix Linux dev shell (${system})"
                if [ -z "''${PROJECT_ROOT:-}" ]; then
                  echo "Tip: use scripts/shell-linux.sh or set PROJECT_ROOT"
                elif [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                  export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                  export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                  echo "Flutter SDK: $FLUTTER_ROOT"
                fi
              '';
            };
          }
        ))

        # Web shell -- minimal, works on both macOS and Linux.
        # dart2js handles Dart->JS; no native compilation required.
        (forAllSystems (system:
          let pkgs = pkgsFor system;
          in {
            web = pkgs.mkShell {
              buildInputs = with pkgs; [
                git curl unzip
              ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
                chromium   # for flutter drive --browser-name=chrome
              ];

              shellHook = ''
                echo "Nix web dev shell (${system})"
                if [ -z "''${PROJECT_ROOT:-}" ]; then
                  echo "Tip: use scripts/shell-web.sh or set PROJECT_ROOT"
                elif [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                  export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                  export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                  echo "Flutter SDK: $FLUTTER_ROOT"
                fi
              '' + pkgs.lib.optionalString pkgs.stdenv.isLinux ''
                export CHROME_EXECUTABLE="${pkgs.chromium}/bin/chromium"
              '' + pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
                # macOS: set CHROME_EXECUTABLE if Chrome is installed
                if [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
                  export CHROME_EXECUTABLE="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
                fi
              '';
            };
          }
        ))

        ]; # end foldl' list
    };
}
