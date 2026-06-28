#!/usr/bin/env bash
# Push an over-the-air PATCH to the current release. Use this for Dart/UI-only
# changes (the vast majority) — installed apps update themselves on next launch,
# no APK reinstall needed.
#
# Patch the latest release:           scripts/shorebird_patch.sh
# Patch a specific release version:   scripts/shorebird_patch.sh --release-version 1.0.0+1
#
# NOTE: native changes (new plugin, Android/Gradle config, Flutter version bump)
# can NOT be patched — cut a new release with scripts/shorebird_release.sh and
# reinstall the APK instead.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/shorebird_env.sh

shorebird patch android \
  --flutter-version "$SHOREBIRD_FLUTTER_VERSION" \
  "$@"
