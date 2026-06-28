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

## Notes

- Free tier = 5,000 patch installs/month (1 device applying 1 patch = 1 install);
  far more than enough for this app.
- `shorebird.yaml` is safe to commit (the `app_id` is not a secret).
