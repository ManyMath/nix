# nix

Reproducible Flutter builds on macOS, iOS, and Android using
[Nix](https://nixos.org/).

Nix pins system dependencies (ruby, cocoapods, cmake, etc.) so every
developer gets identical versions. Xcode and the Android NDK handle
native compilation; Nix supplies the surrounding tooling.

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
```

See the Makefile for all targets (`build-macos`, `build-android`,
`shell-pinned`, etc.).

## Nix and Xcode compatibility

Nix's `mkShell` injects compiler wrappers and environment variables
that conflict with Xcode. The shellHook in `flake.nix` unsets these
so that Nix provides tools while Xcode owns all C/C++/Swift compilation.

## Updating

| What              | How                                                  |
|-------------------|------------------------------------------------------|
| Nix packages      | `make pin`                                           |
| Flutter SDK       | edit `flutter_version.env`, then `make setup`        |
| Android SDK       | edit `android_sdk_version.env`, then `make setup-android` |
| Dart packages     | `flutter pub upgrade`                                |

## License

MIT. See [LICENSE](LICENSE).
