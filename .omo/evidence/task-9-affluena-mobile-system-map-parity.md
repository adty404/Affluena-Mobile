# Task 9 Evidence - Security/Profile/Session Parity

## Scope

- Kept route-backed profile/account/password/session/device-lock controls reachable from Settings and Security Center.
- Added an Advanced protection group in Security Center.
- Routed Security alerts to the existing Notification rules surface.
- Marked unsupported 2FA, push notifications, and dedicated login email alerts as disabled informational rows.
- Removed the unused settings `NotificationRule` widget that rendered an always-on switch pattern.
- Documented Settings Row and Settings Switch Row rules in `DESIGN.md`.

## RED

Command:

```bash
rtk omo sparkshell flutter test test/features/settings/settings_screen_test.dart
```

Result: failed as expected before implementation:

- `security-two-factor-row` was missing from Security Center.

## GREEN

Command:

```bash
rtk omo sparkshell flutter test test/features/settings/settings_screen_test.dart
```

Result: 7 settings tests passed.

Covered behavior:

- Account update refreshes profile copy.
- Password validation and API error copy remain visible.
- Session revoke requires confirmation and removed revoked sessions from the list.
- Device lock remains the only switch-style control in Security Center.
- 2FA, push notifications, and login email alerts render as disabled rows and do not mutate security preferences.

## Verification

Commands:

```bash
rtk omo sparkshell dart format lib/features/settings/presentation/security_screen.dart lib/features/settings/presentation/settings_screen_widgets.dart test/features/settings/settings_screen_test.dart
rtk omo sparkshell flutter analyze
rtk omo sparkshell flutter test test/features/auth test/features/settings
rtk omo sparkshell flutter test
rtk omo sparkshell flutter build apk --debug --dart-define=AFFLUENA_API_BASE_URL=http://43.133.147.101/api/v1
```

Results:

- Format completed with no changes needed on the final run.
- Analyze passed: no issues found.
- Auth/settings tests passed: 17 tests.
- Full Flutter suite passed: 83 tests.
- Debug APK built at `build/app/outputs/flutter-apk/app-debug.apk`.

LSP note:

- The LSP MCP diagnostics transport was closed in this session. `flutter analyze` was used as the diagnostics gate and passed with no issues.

## Manual QA

- Device: iPhone 17 simulator, iOS 26.5.
- App command:

```bash
rtk flutter run -d 20CF90DC-E403-4AB2-9BA2-83A207FB5640 --dart-define=AFFLUENA_API_BASE_URL=http://43.133.147.101/api/v1
```

Observed:

- More tab shows Security Center, Account, Password, Sessions, and Device lock.
- Security Center shows Account, Password, Sessions, Device lock, and Advanced protection.
- Advanced protection shows Security alerts as enabled/route-backed.
- Advanced protection exposes 2FA, push notifications, and login email alerts as disabled accessibility elements with explicit unavailable copy.
- Tapping Security alerts opens Insights on the Rules tab backed by VPS notification rules.
- Tapping disabled 2FA does not navigate and does not toggle device lock or mutate security preferences; the mutation guard is covered by widget test.

## Screenshots

- `.omo/evidence/task-9-security-center-ios.png`
- `.omo/evidence/task-9-security-alerts-rules-ios.png`

## Notes

- No mobile-specific API route was added.
- No fake 2FA, push, or dedicated login email alert support was claimed.
