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

echo "Patching against API: $AFFLUENA_API_BASE_URL"
# `shorebird patch` uses --platforms (not a positional) and inherits the
# release's Flutter version automatically (no --flutter-version).
# --no-tree-shake-icons (proxied to flutter after `--`) must match the release
# build so the icon font asset is byte-identical — else the patch fails with an
# "asset changes" error. Shorebird args (and any "$@", e.g. --release-version)
# stay before the `--`.
shorebird patch \
  --platforms android \
  --dart-define=AFFLUENA_API_BASE_URL="$AFFLUENA_API_BASE_URL" \
  "$@" \
  -- \
  --no-tree-shake-icons
