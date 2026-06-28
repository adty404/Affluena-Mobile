#!/usr/bin/env bash
# Create a new Shorebird RELEASE (a fresh installable APK that supports OTA
# patches). Run this only when you bump the app version or change native code
# (new plugin, Flutter/Gradle/Android config). For Dart/UI-only changes, use
# scripts/shorebird_patch.sh instead — no reinstall needed.
#
# Output APK: build/app/outputs/flutter-apk/app-release.apk
# Install that APK once on the device; future patches update it over the air.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/shorebird_env.sh

echo "Releasing against API: $AFFLUENA_API_BASE_URL"
# --no-tree-shake-icons bundles the FULL Material Icons font so later adding or
# removing icons never changes the asset — keeping Dart/UI changes patchable
# over the air (icon-driven asset changes otherwise force a new release).
shorebird release android \
  --artifact apk \
  --flutter-version "$SHOREBIRD_FLUTTER_VERSION" \
  --dart-define=AFFLUENA_API_BASE_URL="$AFFLUENA_API_BASE_URL" \
  --no-tree-shake-icons \
  "$@"
