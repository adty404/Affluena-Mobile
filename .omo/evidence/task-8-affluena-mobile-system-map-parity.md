# Task 8 — Mobile security device lock parity

## Scope

- Replaced the static "Biometric lock unavailable" row with a real device lock setting in Settings and Security Center.
- Added local preference persistence for the device lock flag.
- Added `local_auth` integration for iOS/Android device authentication.
- Added a root app-lock gate that blocks authenticated sessions when device lock is enabled until local device authentication succeeds.
- Added Android/iOS native configuration required by `local_auth`.

## Red/Green evidence

- RED: `flutter test test/features/settings/settings_screen_test.dart` failed because `Device lock` did not exist.
- RED: `flutter test test/features/auth/auth_routing_test.dart` failed because an enabled device lock did not gate the authenticated app.
- GREEN:
  - `flutter test test/features/settings/settings_screen_test.dart`
  - `flutter test test/features/auth/auth_routing_test.dart`

## Verification

- `flutter analyze`
- `flutter test test/features/auth/auth_routing_test.dart test/features/settings/settings_screen_test.dart test/features/settings/module_navigation_test.dart`
- `flutter test`
- `flutter build apk --debug --dart-define=AFFLUENA_API_BASE_URL=http://43.133.147.101/api/v1`

## Manual QA

- Ran the app on iPhone 17 simulator with VPS API: `http://43.133.147.101/api/v1`.
- Opened More → Settings and verified the Device lock row renders as a mobile switch row with readable status copy.
- Opened Security Center and verified the same Device lock row is present.
- Tapped Device lock and verified iOS native authentication prompt opens with Affluena-specific reason copy.
- Did not enter an iPhone passcode during QA; success path is covered by the fake `DeviceAuthService` widget test.

## Screenshots

- `.omo/evidence/task-8-device-lock-settings-ios.png`
- `.omo/evidence/task-8-device-lock-native-prompt-ios.png`
