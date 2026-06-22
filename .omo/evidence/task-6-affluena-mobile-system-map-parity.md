# Task 6 Evidence - Split Bill Mobile Flow

## Scope
- Implemented the mobile Split Bill flow from Transactions.
- Uses the existing API contract `POST /transactions/split`.
- Keeps wallet/category/tag selections as display names.
- Supports participant rows through a bottom sheet.
- Validates participant total before submit.
- Shows final allocation before create: total bill, participant share, user share, participant count.
- Shows transaction/debt result summary after create.

## TDD / Regression
- RED: `rtk flutter test test/features/transactions/split_bill_screen_test.dart`
  - Failed against the placeholder screen because the split-bill form and submit flow were missing.
- RED after real-device QA found a layout bug:
  - Updating the widget test to use `AffluenaTheme.light/dark` reproduced `BoxConstraints(w=Infinity)` on `split-add-participant-button`.
- GREEN:
  - Replaced the participant add action with compact `IconButton.filledTonal`.
  - `rtk flutter test test/features/transactions/split_bill_screen_test.dart` passed: `+3: All tests passed!`.

## Verification Commands
- `rtk dart format lib/features/transactions/application/split_bill_controller.dart lib/features/transactions/presentation/split_bill_screen.dart lib/features/transactions/presentation/split_bill_screen_form_widgets.dart lib/features/transactions/presentation/split_bill_screen_info_widgets.dart lib/features/transactions/presentation/split_bill_screen_result_widgets.dart lib/features/transactions/presentation/split_bill_participant_sheet.dart lib/features/transactions/presentation/transactions_screen.dart test/features/transactions/split_bill_screen_test.dart`
  - Result: formatted, exit 0.
- `rtk flutter analyze`
  - Result: `No issues found!`.
- `rtk flutter test test/features/transactions`
  - Result: `+12: All tests passed!`.
- `rtk flutter test test/features/settings/module_navigation_test.dart`
  - Result: `+3: All tests passed!`.
- `rtk flutter test`
  - Result: `+117: All tests passed!`.
- `rtk flutter build apk --debug --dart-define=AFFLUENA_API_BASE_URL=http://43.133.147.101/api/v1`
  - Result: built `build/app/outputs/flutter-apk/app-debug.apk`.

## Manual QA
- Device: iPhone 17 simulator, iOS 26.5.
- App command: `rtk flutter run -d 20CF90DC-E403-4AB2-9BA2-83A207FB5640 --dart-define=AFFLUENA_API_BASE_URL=http://43.133.147.101/api/v1`.
- Login: seed user `demo@affluena.com`.
- Flow:
  - Opened Dashboard.
  - Opened Activity / Transactions.
  - Tapped `Split bill`.
  - Verified wallet/category/tag display names render as names, not UUIDs.
  - Entered total `300000`.
  - Added participant `Rani` with share `120000`.
  - Verified summary changed to total `Rp 300.000`, participant share `Rp 120.000`, user share `Rp 180.000`.
  - Submitted and verified confirmation sheet shows explicit final allocation.
  - Confirmed split against VPS API and observed result summary: `Split bill created`, `Expense transaction recorded`, `1 debt record created`.
- Runtime log after hot restart and final submit: no new Flutter render exceptions.

## Visual Evidence
- Confirmation sheet: `.omo/evidence/task-6-split-bill-confirm-ios.png`
- Result summary: `.omo/evidence/task-6-split-bill-result-ios.png`

## Notes
- The backend supports partial split; mobile preserves that behavior by allowing participant totals below the total bill and showing the user's remaining share.
- The app does not silently auto-balance participant shares.
