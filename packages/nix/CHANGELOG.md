# Changelog

## 0.0.1

- Initial release of the `nix_dart` CLI package.
- `init` bootstraps `nix.yaml` and a starter `flake.nix`, or imports an
  existing vendored toolkit with `--from-existing`.
- `setup` fetches the Flutter SDK and bridges to vendored Android setup scripts
  when they exist.
- `shell`, `build`, and `pin` wrap the configured Nix flake directly.
- `sync` writes the `.env` files used by the repo-shipped shell scripts.
- `doctor` validates config and lockfile health
- `eject` now materializes a standalone toolkit, with bundled-asset fallback
  layout.
- `bootstrap.sh` now discovers the nearest host `pubspec.yaml`, so nested
  vendored toolkits and standalone roots bootstrap correctly.
- `init --from-existing` now scans deep enough to detect vendored flakes inside
  nested subtree layouts such as `vendor/tools/nix/nix`.
