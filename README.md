# nix

Reproducible Flutter builds via [Nix](https://nixos.org/) on macOS/iOS.

Nix pins system deps (ruby, cocoapods, cmake, etc.) so every developer gets
the same versions regardless of host macOS. Xcode still handles native
compilation -- Nix just provides the ancillary tooling.

## Setup

1. [Install Nix](https://nixos.org/download/) and enable flakes:
   ```
   # ~/.config/nix/nix.conf
   experimental-features = nix-command flakes
   ```

2. Install [Xcode](https://developer.apple.com/xcode/), then:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

3. Run:
   ```bash
   make setup    # pins flake + fetches Flutter SDK
   make shell    # enter dev shell
   flutter run -d macos
   ```

See the Makefile for all targets (`build-macos`, `shell-pinned`, etc.).

## Nix/Xcode compatibility

Nix's `mkShell` injects compiler wrappers and env vars that conflict with
Xcode. The `flake.nix` shellHook unsets these so Nix provides tools while
Xcode handles all C/C++/Swift compilation natively.

## Updating

- **Nix deps**: `make pin`
- **Flutter SDK**: edit `flutter_version.env`, then `make setup`
- **Dart deps**: `flutter pub upgrade`

## License

MIT -- see [LICENSE](LICENSE).
