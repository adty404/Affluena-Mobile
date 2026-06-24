# Affluena Mobile

Flutter companion app for Affluena. This mobile app is focused on daily personal finance flows: dashboard summary, quick transaction entry, transactions, wallets, and profile/settings.

## Stack

- Flutter 3.44.2
- Dart 3.12.2
- Riverpod for state management
- Go Router for navigation
- Dio for API calls
- Flutter Secure Storage for auth token storage

## Design Direction

Affluena Mobile uses the locked direction **Editorial Light / Calm Consumer Finance**. The design source of truth is `DESIGN.md`.

## Setup

```bash
rtk fvm use 3.44.2
rtk fvm flutter pub get
rtk fvm flutter analyze
rtk fvm flutter test
```

To point the app at a custom API host:

```bash
rtk fvm flutter run --dart-define=AFFLUENA_API_BASE_URL=http://localhost:8080/api/v1
```

## VPS Debug Builds

Use these commands for internal VPS testing against the Affluena v1 API. These are debug builds only; they are not Play Store or TestFlight production-signed artifacts. The VPS URL is supplied only through `--dart-define`; keep `lib/core/config/app_config.dart` on its localhost default.

Android debug APK:

```bash
rtk fvm flutter build apk --debug --dart-define=AFFLUENA_API_BASE_URL=http://43.133.147.101/api/v1
```

Optional Android install after the APK build:

```bash
rtk adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

iOS simulator debug build:

```bash
rtk fvm flutter build ios --simulator --debug --dart-define=AFFLUENA_API_BASE_URL=http://43.133.147.101/api/v1
```

## Current Scope

This app includes:

- Android and iOS Flutter project wrappers
- App shell with bottom navigation (Home, Wallets, Add, Activity, More)
- Auth flows: login, register, forgot password, reset password
- Home dashboard screen
- Quick Entry screen and quick-entry templates
- Transactions screen and split bill
- Wallets screen with wallet detail and sharing
- Settings screen with security/device-lock and parity modules (budgets, categories/tags, debts, trackers, recurring, goals, insights, audit log)
- Shared UI primitives and theme tokens
- API client and secure token storage providers
