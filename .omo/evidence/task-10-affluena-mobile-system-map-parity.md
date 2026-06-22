# Task 10 Evidence: Mobile System Map Parity Hardening

## Scope

- Cross-feature mobile UX/state sweep for the parity surfaces from `system_map.md`.
- Added a route sweep regression guard so parity screens do not expose raw wallet/category/tag/resource IDs when display names exist.
- No production behavior change was required for this pass.

## Automated Guard Added

- `test/features/settings/module_navigation_test.dart`
  - Added `parity surfaces never render raw resource ids`.
  - Routes through Dashboard, Wallets, Wallet detail/sharing, Quick Entry, Templates, Transactions, Split Bill, Settings, Security, Budget, Debt, Tracker, Recurring, Goals, Category & Tags, Insights reports/exports/alerts/rules, and Audit Logs.
  - Fails if raw tokens such as `wallet-main`, `category-food`, `22222222-2222`, or `44444444-4444` appear in rendered UI.

## Verification

- `dart format test/features/settings/module_navigation_test.dart`
  - Passed.
- `flutter test test/features/settings/module_navigation_test.dart`
  - Passed: 4 tests, including the new parity raw-ID route sweep.
- `flutter analyze`
  - Passed: no issues found.
- `flutter test`
  - Passed: all tests passed.
- `flutter build apk --debug --dart-define=AFFLUENA_API_BASE_URL=http://43.133.147.101/api/v1`
  - Passed, produced `build/app/outputs/flutter-apk/app-debug.apk`.
- LSP diagnostics
  - Attempted for the touched test file, but the LSP transport was closed. `flutter analyze` was used as the static verification gate.

## Error-State Coverage Audit

Existing tests cover retry/error behavior across the relevant top-level surfaces:

- Dashboard: `test/features/dashboard/dashboard_screen_test.dart`
- Wallets/detail/mutations: `test/features/wallets/*`
- Quick Entry/templates/write flows: `test/features/quick_entry/*`
- Transactions/edit/split bill: `test/features/transactions/*`
- Settings/security/session/password: `test/features/settings/*`
- Insights/audit logs: `test/features/insights/*`
- API network and session failure mapping: `test/core/api/api_client_test.dart`

## Manual Simulator Smoke

Device: iPhone 17 simulator, iOS 26.5.

Successful VPS run:

- API base: `http://43.133.147.101/api/v1`
- Dashboard rendered balances and recent transactions with display names.
- Wallets rendered named wallet cards.
- Quick Entry rendered wallet/category/tag labels as `GoPay`, `Food & Dining`, and `#MonthlyBill`.
- Transactions rendered mobile list rows with category and wallet names.
- Settings/Profile rendered mobile settings list.
- Security center rendered account/session/device-lock controls.
- Insights list and Reports & Exports rendered mobile-native metric cards, tab chips, and export action.

Representative failure run:

- API base: `http://127.0.0.1:1/api/v1`
- Auth bootstrap showed a friendly restore-session failure message instead of a blank/crashed state.

## Screenshots

- `.omo/evidence/task-10-dashboard-ios.png`
- `.omo/evidence/task-10-wallets-ios.png`
- `.omo/evidence/task-10-quick-entry-ios.png`
- `.omo/evidence/task-10-transactions-ios.png`
- `.omo/evidence/task-10-settings-ios.png`
- `.omo/evidence/task-10-security-ios.png`
- `.omo/evidence/task-10-settings-insights-list-ios.png`
- `.omo/evidence/task-10-insights-ios.png`
- `.omo/evidence/task-10-error-state-ios.png`
