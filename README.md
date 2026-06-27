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
- Auth flows: login, register, forgot password, reset password, change password (revokes other sessions; persists the refreshed token pair to secure storage)
- Home dashboard with interactive sections: a balance card, budget summary, tappable Upcoming rows, and tappable recent transactions (the dashboard has been trimmed of the heavier analytics — forecast, the cashflow-trend chart, and the "Where money went" expense distribution are no longer rendered on Home; their providers/endpoints remain in the codebase)
- Quick Entry + templates with a tree-aware category picker and templates scoped to the active expense/income/transfer tab (the inline tag picker is retained in code but stays empty/disabled now that tags are de-emphasized in the UI)
- A reusable date + time picker on every transaction input (transaction create, quick entry manual save and template execute, split bill, and the wallet adjust-balance/penyesuaian sheet): the picked local datetime is normalized to UTC and sent as a full RFC3339 `transaction_at` timestamp, so entries capture the exact time of day and can be backdated or future-dated rather than defaulting to "now"
- Activity tab with a Transactions/Activity segmented view (the Activity feed surfaces transaction-related actions: split bill, debt/installment/subscription payments)
- Split bill screens (list-first: ongoing splits, who owes you, detail, add a new split) are still built and routable, but their entry points are currently hidden from the UI nav; settled splits still surface as events in the Activity feed
- Wallets shown as a two-per-row grid; wallet detail and sharing. Shared-wallet invites pick a role — "Boleh lihat" (viewer, read-only) or "Boleh catat" (member, read + write). Viewer wallets are filtered out of every record-into-wallet picker (transaction create, quick entry, split bill, recurring), and write actions (adjust balance, edit, invite) are hidden on a viewer's wallet detail
- Settings ("More") with inline security (account, password, sessions, device lock with auto-prompt biometric), appearance (theme, app tour), and route-backed modules: quick-entry templates, Categories (a 3-level hierarchy — the screen was previously "Categories & Tags"; tag management is no longer surfaced in the menu), budgets, installments & subscriptions, recurring, goals, reports/insights, audit logs, alerts & activity, and notification rules
- Shared UI primitives, a reusable tree category picker, and theme tokens
- API client and secure token storage providers

A recent UI de-clutter hides a set of secondary features from the navigation and menus while keeping their routes, screens, and API code intact (nothing was deleted): split bill, tags, debt/loan, and CSV export. They remain reachable in the codebase and continue to be exercised by the backend and QA suites; they are simply no longer surfaced in the mobile UI.
