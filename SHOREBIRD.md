# Shorebird — over-the-air updates for Affluena

Affluena uses [Shorebird](https://shorebird.dev) (code push for Flutter) so most
updates reach installed apps **automatically, without reinstalling the APK**.
`auto_update` is on (see `shorebird.yaml`), so the app downloads new patches in
the background and applies them on the next launch.

App: **Affluena** · `app_id: 1405299c-086b-4398-9361-064b147f99d8`

## The two operations

| | When | How | User reinstalls? |
|---|---|---|---|
| **Patch** (OTA) | Dart / UI / logic changes — the vast majority | `scripts/shorebird_patch.sh` | ❌ No — app self-updates on next open |
| **Release** | App-version bump, or **native** changes (new plugin, Android/Gradle config, Flutter version bump) | `scripts/shorebird_release.sh` → install the produced APK once | ✅ Yes, once |

So the normal loop is: make Dart changes → `scripts/shorebird_patch.sh` → done.
You only cut a new release + reinstall when something native changes.

> **Assets & patches:** OTA patches are Dart-code-only and can't carry **asset**
> changes. The builds pass `--no-tree-shake-icons` (scripts + `shorebird.yml`) so
> the full Material Icons font is always bundled — that way adding/removing icons
> no longer changes an asset and stays patchable. Other asset changes (new
> bundled fonts/images, `pubspec.yaml` asset list edits) still require a release.

## First-time / per-machine prerequisites

1. Shorebird CLI installed (`~/.shorebird`) and logged in (`shorebird login`).
2. **Android SDK `build-tools;35.0.0` installed** — required, the newer 36/37
   alone break the release build's `apkanalyzer` step:
   ```sh
   sdkmanager --install "build-tools;35.0.0"
   ```
3. A real JDK — the scripts default `JAVA_HOME` to Android Studio's bundled JBR.

These are handled/documented in `scripts/shorebird_env.sh`. Without them, the
release build fails with *"failed to strip debug symbols from native libraries"*
(see [flutter/flutter#186810](https://github.com/flutter/flutter/issues/186810)).

The **API base URL is compile-time** (`AFFLUENA_API_BASE_URL`, default localhost).
Both `shorebird_release.sh` and `shorebird_patch.sh` bake the VPS URL via
`--dart-define` (from `shorebird_env.sh`). If it's ever missed, the app shows
*"Tidak bisa terhubung ke Affluena"* because it falls back to localhost. Override
by exporting `AFFLUENA_API_BASE_URL` before running a script.

## Releasing

```sh
scripts/shorebird_release.sh
```
Produces `build/app/outputs/flutter-apk/app-release.apk` (a Shorebird-enabled
APK). Distribute/install **that** APK — a plain `flutter build apk` cannot
receive patches. Keep the dropped `Affluena.apk` in sync with this.

## Patching (the common case)

```sh
scripts/shorebird_patch.sh            # patch the latest release
```
Make sure the patch is built with the **same Flutter version** as its release
(pinned to `3.44.2` in `scripts/shorebird_env.sh`).

## GitHub Actions (CI)

Two workflows in `.github/workflows/`:

- **`ci.yml`** (Mobile CI) — on every PR and push to `master`: `dart format`
  check, `flutter analyze`, and `flutter test`. Golden tests are tagged `golden`
  (see `dart_test.yaml`) and excluded in CI because their baselines are
  macOS-specific; run them locally with plain `flutter test`.
- **`shorebird.yml`** (Mobile Shorebird):
  - **Auto OTA patch** on every push to `master` touching app code (`lib/**`,
    `pubspec.yaml`, `assets/**`, `shorebird.yaml`) → `shorebird patch
    --release-version=latest`. Installed apps self-update on next launch.
  - **Manual release**: Actions → *Mobile Shorebird* → *Run workflow* → choose
    `release` (for a version bump / native change). Produces an installable APK
    as a build artifact.

### One-time setup
1. **`SHOREBIRD_TOKEN`** repo secret (required): Shorebird Console →
   **Account → API Keys** → *Create API Key* (scope *Release & Patch only*), then
   repo **Settings → Secrets and variables → Actions → New repository secret**.
2. **`AFFLUENA_API_BASE_URL`** repo variable (optional): defaults to the VPS URL
   if unset; baked into every CI build via `--dart-define`.

A native change pushed to `master` makes the auto-patch fail (patches can't carry
native diffs) — that is the signal to run the manual `release` instead.

## Notes

- Free tier = 5,000 patch installs/month (1 device applying 1 patch = 1 install);
  far more than enough for this app.
- `shorebird.yaml` is safe to commit (the `app_id` is not a secret).
