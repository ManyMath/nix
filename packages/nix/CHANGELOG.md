# Changelog

## 0.0.1

- Initial release of the `nix_dart` CLI package.
- `init` bootstraps `nix.yaml` and a starter `flake.nix`, or imports an
  existing vendored toolkit with `--from-existing`.
- `setup` fetches the Flutter SDK and bridges to vendored Android setup scripts
  when they exist.
- `shell`, `build`, and `pin` wrap the configured Nix flake directly.
- `sync` writes the `.env` files used by the repo-shipped shell scripts.
- `doctor` and `eject` validate the config, lockfile, and embedded toolkit
  layout.
