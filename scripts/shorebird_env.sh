#!/usr/bin/env bash
# Shared environment for Shorebird release/patch builds.
#
# Shorebird always builds an Android App Bundle as the release base. Flutter's
# post-build step then runs `apkanalyzer` to verify native debug symbols were
# stripped — and apkanalyzer needs:
#   1. JAVA_HOME pointing at a real JDK (Android Studio's bundled JBR), otherwise
#      it hits the macOS Java stub and the build aborts with
#      "failed to strip debug symbols from native libraries"
#      (flutter/flutter#186810).
#   2. An Android SDK build-tools version its (older) sdklib can parse. The very
#      new build-tools 36/37 are rejected with "Cannot locate latest build
#      tools", so build-tools;35.0.0 MUST be installed:
#         sdkmanager --install "build-tools;35.0.0"
#
# Plain `flutter build apk` does NOT need this (it skips the appbundle strip
# check) — only Shorebird release/patch (which build an AAB) do.
export JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$HOME/.shorebird/bin:$JAVA_HOME/bin:/opt/homebrew/bin:$PATH"

# The Flutter version Shorebird builds with. Keep this identical for the release
# and every patch — a patch must match its release's Flutter version.
export SHOREBIRD_FLUTTER_VERSION="3.44.2"
