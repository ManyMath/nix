/// A starter flake.nix template for new projects.
///
/// This is a trimmed version of the full flake that covers the most common
/// shells. Users can add or remove shells as needed.
///
/// Note on Nix string escaping: inside Nix's ''...'' multi-line strings,
/// bash ${VAR} must be written as ''${VAR} to avoid Nix interpolation.
/// Plain $VAR (no braces) is safe. Actual Nix interpolation like
/// ${pkgs.chromium} is intentional and must NOT be escaped.
const String flakeTemplate = r'''
{
  description = "Reproducible Flutter dev environment using Nix.";

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
        builtins.foldl' nixpkgs.lib.recursiveUpdate {} [

        # macOS/iOS shell -- Nix provides tooling, Xcode owns the compiler.
        (forAllDarwin (system:
          let pkgs = import nixpkgs { inherit system; };
          in {
            android = pkgs.mkShell {
              buildInputs = with pkgs; [ jdk17 git curl unzip ];
              shellHook = ''
                unset SDKROOT NIX_CC NIX_BINTOOLS NIX_CFLAGS_COMPILE NIX_LDFLAGS
                unset CC CXX LD AR NM RANLIB
                CLEAN_PATH=""
                IFS=':' read -ra PARTS <<< "$PATH"
                for p in "''${PARTS[@]}"; do
                  case "$p" in
                    *clang-wrapper*|*cctools-binutils*|*xcbuild*|*apple-sdk*) continue ;;
                    *) CLEAN_PATH="''${CLEAN_PATH:+$CLEAN_PATH:}$p" ;;
                  esac
                done
                export PATH="/usr/bin:$CLEAN_PATH"
                if [ -n "''${PROJECT_ROOT:-}" ] && [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                  export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                  export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                fi
              '';
            };

            default = pkgs.mkShell {
              buildInputs = with pkgs; [ ruby cocoapods git curl unzip cmake ninja pkg-config ];
              shellHook = ''
                unset SDKROOT NIX_CC NIX_BINTOOLS NIX_CFLAGS_COMPILE NIX_LDFLAGS
                unset CC CXX LD AR NM RANLIB
                CLEAN_PATH=""
                IFS=':' read -ra PARTS <<< "$PATH"
                for p in "''${PARTS[@]}"; do
                  case "$p" in
                    *clang-wrapper*|*cctools-binutils*|*xcbuild*|*apple-sdk*) continue ;;
                    *) CLEAN_PATH="''${CLEAN_PATH:+$CLEAN_PATH:}$p" ;;
                  esac
                done
                export PATH="/usr/bin:$CLEAN_PATH"
                if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
                  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
                fi
                if [ -n "''${PROJECT_ROOT:-}" ] && [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                  export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                  export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                fi
              '';
            };
          }
        ))

        # Linux shells -- Nix owns the full toolchain.
        (forAllLinux (system:
          let pkgs = import nixpkgs-linux { inherit system; };
          in {
            android = pkgs.mkShell {
              buildInputs = with pkgs; [ jdk17 git curl unzip ];
              shellHook = ''
                if [ -n "''${PROJECT_ROOT:-}" ] && [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                  export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                  export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                fi
              '';
            };

            linux = pkgs.mkShell {
              buildInputs = with pkgs; [
                clang cmake ninja pkg-config
                gtk3 glib pcre2 util-linux xz
                xorg.libX11 xorg.libXcursor xorg.libXrandr xorg.libXinerama
                xorg.libXi xorg.libXext xorg.libXfixes xorg.libXrender
                mesa libGL
                git curl unzip
              ];
              shellHook = ''
                if [ -n "''${PROJECT_ROOT:-}" ] && [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                  export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                  export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                fi
              '';
            };
          }
        ))

        # Web shell -- works on macOS and Linux.
        (forAllSystems (system:
          let pkgs = pkgsFor system;
          in {
            web = pkgs.mkShell {
              buildInputs = with pkgs; [
                git curl unzip
              ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ chromium ];
              shellHook = ''
                if [ -n "''${PROJECT_ROOT:-}" ] && [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                  export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                  export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                fi
              '' + pkgs.lib.optionalString pkgs.stdenv.isLinux ''
                export CHROME_EXECUTABLE="${pkgs.chromium}/bin/chromium"
              '' + pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
                if [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
                  export CHROME_EXECUTABLE="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
                fi
              '';
            };
          }
        ))

        ];
    };
}
''';
