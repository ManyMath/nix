# nix

Reproducible Flutter builds on macOS, iOS, Android, Linux, and Web with [Nix](https://nixos.org/).

This is a [melos](https://melos.invertase.dev/) monorepo containing:

| Path | Description |
|------|-------------|
| `packages/nix` | Dart CLI package exposing the `nix_dart` executable |
| `apps/example` | Reference Flutter app demonstrating the toolkit |

## Quick Start

```bash
dart pub global activate melos
melos bootstrap
```

## Reference App

The example app in `apps/example/` is the smallest working example. It wraps
the same `Makefile.inc` that subtree users include in their host app.

```bash
cd apps/example
make setup-web
make build-web
make verify-web
```

The repo also includes a checked-in `nix.yaml`, so the example app works
through `nix_dart` as well:

```bash
dart run packages/nix/bin/nix_dart.dart doctor
```

## Dart CLI

The publishable package lives in `packages/nix` and exposes `nix_dart`.

```bash
dart pub global activate nix

# In a Flutter project:
nix_dart init linux android web
nix_dart setup
nix_dart shell linux
nix_dart build web
nix_dart pin
```

`nix_dart init --from-existing` is the migration path for projects that
already have `flutter_version.env`, `android_sdk_version.env`, or a vendored
copy of this repo. After editing `nix.yaml`, run `nix_dart sync` to refresh
the `.env` files that the shell scripts consume.

If you want to start CLI-first and later hand a self-contained toolkit to CI or
to another repo, `nix_dart eject` materializes `bootstrap.sh`,
`Makefile.inc`, `nix/`, `scripts/`, and the `.env` files into the output
directory:

```bash
nix_dart eject --output-dir tooling/nix
bash tooling/nix/bootstrap.sh
```

Package-specific docs live in `packages/nix/README.md`.

## Embedded Toolkit

### Subtree + CLI

For new projects, prefer `nix_dart init` (see Dart CLI above) or
`nix_dart eject` (see Standalone Script Toolkit below). The subtree approach
is still supported for projects that want a vendored copy of the example
toolkit checked into their repo.

```bash
git subtree add --prefix=nix \
  --squash https://github.com/ManyMath/nix.git main
bash nix/apps/example/bootstrap.sh

dart pub global activate nix
nix_dart init --from-existing
```

The host project's `Makefile` should point `NIX_FLUTTER_DIR` at the subtree's
example toolkit:

```make
NIX_FLUTTER_DIR ?= nix/apps/example
include $(NIX_FLUTTER_DIR)/Makefile.inc
```

`Makefile.inc` auto-delegates to `nix_dart` only when both `nix_dart` and
`nix.yaml` are present in the host project. Until then it falls back to the
vendored shell scripts.

### Subtree Only

If you do not want a Dart CLI dependency in the host project, include
`Makefile.inc` and use the vendored scripts directly through `make`.

```make
NIX_FLUTTER_DIR ?= nix/apps/example
include $(NIX_FLUTTER_DIR)/Makefile.inc
```

Then run:

```bash
make nix-bootstrap
make nix-setup-linux
make nix-shell-linux
make nix-build-linux
```

### Standalone Script Toolkit

`nix_dart eject` is the bridge between the CLI workflow and the vendored
script workflow. It produces the same files that a subtree checkout would
contain, but without requiring git subtree history in the host project.

```bash
nix_dart init web
nix_dart setup web
nix_dart eject --output-dir .

./scripts/fetch-flutter-web.sh
PROJECT_ROOT="$PWD" ./scripts/build-web.sh
```

## Reproducibility Inputs

Pinning happens at four layers:

- `nix/flake.lock` for Nix system dependencies.
- `flutter_version.env` for the Flutter SDK version and archive checksums.
- `android_sdk_version.env` for Android cmdline-tools, build-tools, and NDK.
- `pubspec.lock` for Dart/Flutter packages.

`make pin` or `nix_dart pin` advances the checked-in `flake.lock`.

## Setup Notes

1. Install Nix with flakes enabled:
   ```text
   experimental-features = nix-command flakes
   ```
2. macOS and iOS builds still require Xcode.
3. Android on macOS needs a JDK on `PATH` or Android Studio installed.
4. Android on Linux uses the Nix `android` dev shell to provide JDK 17.
5. Linux desktop builds rely on the `linux` dev shell in `nix/flake.nix` for
   GTK, clang, cmake, ninja, and related libraries.

## Updating

- Nix packages: `make pin` or `nix_dart pin`
- Flutter SDK: edit `flutter_version.env` or `nix.yaml`, then re-run setup
- Android SDK versions: edit `android_sdk_version.env` or `nix.yaml`, then re-run setup
- Dart packages: `flutter pub upgrade` or `dart pub upgrade`

## License

MIT. See `LICENSE`.
