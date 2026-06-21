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
fvm use 3.44.2
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```

To point the app at a custom API host:

```bash
fvm flutter run --dart-define=AFFLUENA_API_BASE_URL=http://localhost:8080/api/v1
```

## Current Scope

This scaffold includes:

- Android and iOS Flutter project wrappers
- App shell with bottom navigation
- Home dashboard screen
- Quick Entry screen
- Transactions screen
- Wallets screen
- Profile/settings screen
- Shared UI primitives and theme tokens
- API client and secure token storage providers
