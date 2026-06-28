#!/bin/bash
# Affluena-Mobile SessionStart hook.
# Installs the pinned Flutter SDK and project packages so `flutter analyze`
# and `flutter test` work in Claude Code on the web.
#
# Scope: this enables static analysis + unit/widget tests. It does NOT install
# the Android SDK (APK builds) or provide an iOS toolchain (macOS-only).
set -euo pipefail

# Only run in the remote (Claude Code on the web) environment.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# Read the pinned Flutter version from .fvmrc (falls back to 3.44.2).
FLUTTER_VERSION="3.44.2"
if [ -f .fvmrc ]; then
  parsed="$(grep -oE '"flutter"[[:space:]]*:[[:space:]]*"[^"]+"' .fvmrc | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
  if [ -n "$parsed" ]; then
    FLUTTER_VERSION="$parsed"
  fi
fi

FLUTTER_DIR="$HOME/flutter"

# Install Flutter once; the extracted SDK persists in the cached container
# state. We download the official release archive over HTTPS rather than
# `git clone`, because the sandbox git proxy only allows the Affluena repos.
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "[session-start] Affluena-Mobile: installing Flutter $FLUTTER_VERSION..."
  archive_url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  tmp_archive="$(mktemp --suffix=.tar.xz)"
  curl -fSL --retry 3 --retry-delay 2 -o "$tmp_archive" "$archive_url"
  # Extract to $HOME; the archive unpacks into a top-level `flutter/` dir.
  rm -rf "$FLUTTER_DIR"
  tar -xJf "$tmp_archive" -C "$HOME"
  rm -f "$tmp_archive"
else
  echo "[session-start] Affluena-Mobile: reusing cached Flutter at $FLUTTER_DIR."
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# Flutter shells out to git against its own checkout; allow it when the SDK
# directory ownership looks "dubious" to git (common when run as root).
git config --global --add safe.directory "$FLUTTER_DIR" >/dev/null 2>&1 || true

# Persist Flutter on PATH for the rest of the session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$FLUTTER_DIR/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

# Avoid noisy/at-exit analytics prompts in a non-interactive shell.
flutter --disable-analytics >/dev/null 2>&1 || true

echo "[session-start] Affluena-Mobile: flutter pub get..."
flutter pub get

echo "[session-start] Affluena-Mobile: Flutter $FLUTTER_VERSION ready."
echo "[session-start] Note: 'flutter analyze' and 'flutter test --exclude-tags golden' work here; APK builds need the Android SDK and iOS builds need macOS."
