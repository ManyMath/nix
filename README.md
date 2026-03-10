# nix

Reproducible Flutter builds on macOS, iOS, Android, Linux, and Web using
[Nix](https://nixos.org/).

Nix pins system dependencies (ruby, cocoapods, cmake, gtk3, etc.) so every
developer gets identical versions. Xcode and the Android NDK handle
native compilation on their respective platforms; Nix supplies the surrounding
tooling and the full desktop toolkit on Linux.

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

3. **Android on macOS** requires JDK 17+. Install
   [Android Studio](https://developer.android.com/studio) or point
   `JAVA_HOME` at any compatible JDK.
   **Android on Linux** requires no extra prerequisites: Nix provides JDK 17
   via the `android` devShell.

4. **Linux** requires no extra prerequisites: Nix provides the entire
   toolchain including the GTK3 development headers Flutter needs.

## Quick start

```bash
# macOS/iOS
make setup            # pin flake + fetch Flutter SDK
make shell            # enter dev shell
flutter run -d macos

# Android (macOS)
make setup-android    # fetch Flutter (macOS) + Android SDK
make shell-android
flutter run -d emulator-5554

# Android (Linux)
make setup-android-linux   # fetch Flutter (Linux) + Android SDK via Nix
make shell-android-pinned  # Nix provides JDK 17
flutter run -d emulator-5554

# Linux desktop
make setup-linux      # pin flake + fetch Flutter SDK
make shell-linux      # enter dev shell (Nix provides GTK3, clang, cmake, …)
flutter run -d linux

# Web
make setup-web        # pin flake + fetch Flutter SDK (auto-detects OS)
make shell-web        # enter dev shell
flutter run -d chrome
```

| Platform        | Setup                      | Dev shell                  | CI build             |
|-----------------|----------------------------|----------------------------|----------------------|
| macOS/iOS       | `make setup`               | `make shell`               | `make build-macos`   |
| Android (macOS) | `make setup-android`       | `make shell-android`       | `make build-android` |
| Android (Linux) | `make setup-android-linux` | `make shell-android-pinned`| `make build-android` |
| Linux desktop   | `make setup-linux`         | `make shell-linux`         | `make build-linux`   |
| Web             | `make setup-web`           | `make shell-web`           | `make build-web`     |

See the Makefile for all targets (`shell-pinned`, `build-web-fast`, etc.).

## Nix and Xcode compatibility

Nix's `mkShell` injects compiler wrappers and environment variables
that conflict with Xcode. The shellHook in `flake.nix` unsets these
so that Nix provides tools while Xcode owns all C/C++/Swift compilation.

On Linux there is no such conflict — Nix provides the full toolchain
(clang, cmake, ninja, pkg-config) and the GTK3 libraries that Flutter's
Linux embedder requires.

## Android on Linux

Flutter Android builds work on Linux with no additional system prerequisites
beyond Nix. The `android` devShell in `nix/flake.nix` provides **JDK 17**
(Eclipse Temurin) for Gradle and `sdkmanager`.

### First run on a new Linux machine

```bash
make setup-android-linux         # fetch Flutter (Linux) + Android SDK via Nix android shell
make shell-android-pinned        # enter Nix android shell (JDK 17 + Flutter on PATH)
flutter config --enable-android
flutter doctor                   # verify setup; ignore Xcode/iOS warnings
flutter build apk --release      # or: make build-android
```

### CI build

```bash
make build-android    # auto-detects Linux, uses Nix android shell for Java
```

Outputs to `build/app/outputs/flutter-apk/app-release.apk`.

### Reproducibility

APK file contents are byte-identical across clean rebuilds from the same
pinned configuration (same `flake.lock`, `flutter_version.env`,
`android_sdk_version.env`, and `pubspec.lock`). The APK Signature v2 block
changes between builds because cryptographic signing is inherently
non-deterministic; the compiled Dart code and resources are stable.

Verify:
```bash
make build-android
cp build/app/outputs/flutter-apk/app-release.apk /tmp/first.apk
rm -rf build/app
make build-android
# Compare entries (excluding the signature block):
unzip -p /tmp/first.apk classes.dex | sha256sum
unzip -p build/app/outputs/flutter-apk/app-release.apk classes.dex | sha256sum
```

### What Nix provides

The `android` devShell (`nix/flake.nix`) supplies:

- **JDK 17** (`jdk17` / Eclipse Temurin) — required by Gradle and `sdkmanager`
- `git`, `curl`, `unzip` — for `fetch-android-sdk.sh`

The Android SDK itself (platforms, build-tools, NDK) is downloaded by
`scripts/fetch-android-sdk.sh` into `.android-sdk/` (git-ignored), with
component versions pinned in `android_sdk_version.env`. The Flutter SDK is
downloaded by `scripts/fetch-flutter-linux.sh` into `.flutter-sdk/`, with
the version and SHA-256 hash pinned in `flutter_version.env`.

### Pinning the cmdline-tools checksum

`fetch-android-sdk.sh` prints the SHA-256 of the downloaded archive on the
first run if `ANDROID_CMDLINE_TOOLS_SHA256_LINUX` is not set. Record it:

```bash
# In android_sdk_version.env:
ANDROID_CMDLINE_TOOLS_SHA256_LINUX="<hash printed by fetch-android-sdk.sh>"
```

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

## Web platform notes

- Builds on both macOS and Linux hosts with no platform-specific tooling needed.
- `dart2js` (bundled in the Flutter SDK) handles Dart→JS compilation; no separate download required.
- On Linux, Nix provides Chromium automatically; on macOS, set `CHROME_EXECUTABLE` or install Google Chrome.
- Full determinism: no code signing, no native linking. `build/web/main.dart.js` is byte-identical across clean rebuilds.
- Verify reproducibility:
  ```bash
  make build-web && sha256sum build/web/main.dart.js > first.sha256
  rm -rf build/web
  make build-web && sha256sum build/web/main.dart.js > second.sha256
  diff first.sha256 second.sha256   # no output = reproducible
  ```
- Serve locally: `python3 -m http.server 8080 -d build/web`

## Updating

| What              | How                                                         |
|-------------------|-------------------------------------------------------------|
| Nix packages      | `make pin`                                                  |
| Flutter SDK (all) | edit `flutter_version.env`, then re-run the relevant setup  |
| Android SDK       | edit `android_sdk_version.env`, then `make setup-android` (macOS) or `make setup-android-linux` (Linux) |
| Dart packages     | `flutter pub upgrade`                                       |

## License

MIT. See [LICENSE](LICENSE).
