# Fallback for non-flake Nix users.
# Enter with: nix-shell nix/shell.nix
with import <nixpkgs> {};

mkShell {
  buildInputs = [
    ruby
    cocoapods
    git
    curl
    unzip
    cmake
    ninja
    pkg-config
  ];

  shellHook = ''
    # Unset Nix compiler/linker env so Xcode builds work.
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

    if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
      export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    fi

    echo "Nix dev shell (unpinned -- use 'nix develop ./nix' for pinned builds)"
    if [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
      export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
      export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
      echo "Flutter SDK: $FLUTTER_ROOT"
    fi
  '';
}
