# Example app workflow

This is the smallest complete example in the repo.

It is a plain Flutter app with pinned Nix files and a checked-in web artifact
hash, so you can build it and see what a known-good result looks like.

## Build It Here

Run these commands from this directory:

```bash
make setup-web
make build-web
./tool/hash_web_release.sh --check
```

Expected web artifact hash:

```text
62297b9be2ade42aa8c3f0416a5e8453c85c9b718a086f346f65238e7074ef38
```

That value is stored in `expected-hashes/web-main.dart.js.sha256`.
It only applies to this app and the pinned toolchain in this directory.

If you prefer `make`, the same flow is wrapped in `make verify-web` after a
build, or `make verify-example-web` to build and verify in one step.

## Other Ways To Use The Repo

### Run it from this checkout

This is the path shown above. It is the quickest way to prove the repo is in a
known-good state before you adapt it to your own app.

```bash
make setup-web
make build-web
./tool/hash_web_release.sh --check
```

### Copy the wrappers into an existing Flutter project

Copy these files and directories into the root of your project:

- `Makefile`
- `nix/`
- `scripts/`
- `tool/hash_web_release.sh`
- `expected-hashes/web-main.dart.js.sha256`
- `flutter_version.env`
- `android_sdk_version.env`

Then:

- commit your app's `pubspec.lock` so Dart dependencies are pinned alongside the Nix and Flutter inputs,
- keep the project-root layout expected by the scripts, or adjust the wrappers if your layout differs,
- run the setup and build target for the platform you care about, and
- replace `expected-hashes/web-main.dart.js.sha256` with a hash from your own app after your first known-good build.

Once you change the app code, do not expect it to match the reference hash
shown above.

### Add the repo as a git subtree

If you want a tracked copy of this repo inside a larger codebase, add it as a
subtree and run its commands from the subtree root:

```bash
git subtree add --prefix third_party/nix-flutter REPO_URL main --squash
cd third_party/nix-flutter
make setup-web
make build-web
./tool/hash_web_release.sh --check
```

That keeps the example app and its pinned toolchain together under one
directory. It does not automatically retarget the scripts to a sibling Flutter
app elsewhere in your monorepo. If you want the wrappers to drive your existing
app at the repo root, use the copy-in approach instead.

### Fork the repo and replace the app

If you are starting from this example, fork the repo and keep the example
intact until `make verify-example-web` passes. After that, replace:

- `lib/`
- assets and branding
- Android/iOS/macOS bundle identifiers and app names

When you intentionally change the app, the checked-in example hash will stop
matching. That is expected. Rebuild, compute the new artifact hash, and update
`expected-hashes/web-main.dart.js.sha256` to establish your new baseline.
