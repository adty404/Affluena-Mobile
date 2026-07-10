#!/usr/bin/env bash
# Build the Google Play App Bundle (AAB) with the API base URL baked in.
#
# ⚠️ PRE-REQUISITES (see docs/PLAYSTORE.md — "Keystore & signing"):
#   1. A RELEASE keystore at android/keystore/affluena-release.jks and its
#      credentials in android/key.properties (NEVER commit either — both are
#      gitignored). Play rejects debug-signed bundles, and today
#      android/app/build.gradle.kts still falls back to the debug signingConfig
#      — the 1.5.0 release PR flips it to the release keystore when
#      key.properties exists.
#   2. The API MUST be HTTPS by then (Play Data-Safety: encryption in transit).
#      Override the default below via AFFLUENA_API_BASE_URL.
#
# Version: Play requires a strictly increasing versionCode — bump pubspec.yaml
# `version:` (e.g. 1.5.0+8) before building, which also means a Shorebird
# RELEASE (not an OTA patch) — see SHOREBIRD.md.
set -euo pipefail

API_BASE_URL="${AFFLUENA_API_BASE_URL:-http://43.133.147.101/api/v1}"

if [[ "$API_BASE_URL" == http://* ]]; then
  echo "⚠️  WARNING: building a Play bundle against a plain-HTTP API URL."
  echo "   Play's Data Safety form requires encryption in transit for a"
  echo "   finance app — switch to https:// before actually submitting."
fi

echo "Building release AAB against API: $API_BASE_URL"
fvm flutter build appbundle --release \
  --dart-define=AFFLUENA_API_BASE_URL="$API_BASE_URL"

echo "Built: build/app/outputs/bundle/release/app-release.aab"
echo "Upload this file in Play Console → Testing → Closed testing (first run)"
