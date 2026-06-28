#!/usr/bin/env bash
# Build the internal/distribution release APK with the API base URL baked in.
#
# The API URL is a compile-time value (lib/core/config/app_config.dart reads
# AFFLUENA_API_BASE_URL via String.fromEnvironment). A plain `flutter build apk`
# would fall back to the localhost default and fail to reach the VPS, so ALWAYS
# build through this script (or pass the same --dart-define yourself).
#
# Override the URL by exporting AFFLUENA_API_BASE_URL before running.
set -euo pipefail

API_BASE_URL="${AFFLUENA_API_BASE_URL:-http://43.133.147.101/api/v1}"

echo "Building release APK against API: $API_BASE_URL"
fvm flutter build apk --release \
  --dart-define=AFFLUENA_API_BASE_URL="$API_BASE_URL"

echo "Built: build/app/outputs/flutter-apk/app-release.apk"
