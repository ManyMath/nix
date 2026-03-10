# nix

Reproducible Flutter builds on macOS, iOS, Android, and Linux using
[Nix](https://nixos.org/).

Nix pins system dependencies (ruby, cocoapods, cmake, gtk3, etc.) so every
developer gets identical versions. Xcode and the Android NDK handle
native compilation on their respective platforms; Nix supplies the surrounding
tooling and — on Linux — the full desktop toolkit.

## Reproducibility

Builds from the same pinned configuration are deterministic on a given
machine. macOS `.app` bundles are byte-identical across clean rebuilds.
Android APK file contents are also byte-identical; the only variance is
the APK Signature v2 block, which changes because cryptographic signing
is inherently non-deterministic.

Pinning happens at three layers:

- **Nix packages** are locked in `nix/flake.lock`.
- **Flutter SDK** version is set in `flutter_version.env`.
- **Android SDK** component versions are set in `android_sdk_version.env`.
- **Dart packages** are locked in `pubspec.lock`.

## Setup

1. [Install Nix](https://nixos.org/download/) with flakes enabled:
   ```
   # ~/.config/nix/nix.conf
   experimental-features = nix-command flakes
   ```

2. **macOS/iOS** requires [Xcode](https://developer.apple.com/xcode/):
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

3. **Android** requires JDK 17+. Install
   [Android Studio](https://developer.android.com/studio) or point
   `JAVA_HOME` at any compatible JDK.

4. **Linux** requires no extra prerequisites — Nix provides the entire
   toolchain including the GTK3 development headers Flutter needs.

## Quick start

```bash
# macOS/iOS
make setup            # pin flake + fetch Flutter SDK
make shell            # enter dev shell
flutter run -d macos

# Android
make setup-android    # fetch Flutter + Android SDK
make shell-android
flutter run -d emulator-5554

# Linux desktop
make setup-linux      # pin flake + fetch Flutter SDK
make shell-linux      # enter dev shell (Nix provides GTK3, clang, cmake, …)
flutter run -d linux
```

See the Makefile for all targets (`build-macos`, `build-android`,
`build-linux`, `shell-pinned`, etc.).

## Nix and Xcode compatibility

Nix's `mkShell` injects compiler wrappers and environment variables
that conflict with Xcode. The shellHook in `flake.nix` unsets these
so that Nix provides tools while Xcode owns all C/C++/Swift compilation.

On Linux there is no such conflict — Nix provides the full toolchain
(clang, cmake, ninja, pkg-config) and the GTK3 libraries that Flutter's
Linux embedder requires.

## Linux platform notes

The `linux` devShell in `nix/flake.nix` uses `nixos-24.11` and includes:

- **Build toolchain**: `clang`, `cmake`, `ninja`, `pkg-config`
- **GTK3 stack**: `gtk3`, `glib`, `pcre2`
- **System libs**: `libblkid`, `libuuid`, `liblzma`
- **X11/OpenGL**: `libX11`, `libXcursor`, `libXrandr`, `mesa`, `libGL`

The Flutter Linux SDK archive is downloaded by
`scripts/fetch-flutter-linux.sh` and verified with a SHA-256 hash stored
in `flutter_version.env` (`FLUTTER_SHA256_LINUX_X64` /
`FLUTTER_SHA256_LINUX_ARM64`).

### First run on a new machine

```bash
make setup-linux                 # downloads Flutter, pins flake
make shell-linux                 # enters Nix shell
flutter config --enable-linux-desktop
flutter doctor                   # verify setup
flutter run -d linux             # run the example app
```

### CI build

```bash
make build-linux                 # fully pinned, outputs to build/linux/
```

## Updating

| What              | How                                                         |
|-------------------|-------------------------------------------------------------|
| Nix packages      | `make pin`                                                  |
| Flutter SDK (all) | edit `flutter_version.env`, then re-run the relevant setup  |
| Android SDK       | edit `android_sdk_version.env`, then `make setup-android`   |
| Dart packages     | `flutter pub upgrade`                                       |

## License

MIT. See [LICENSE](LICENSE).
