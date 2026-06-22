# Task 7 Evidence - Audit Logs Mobile Flow

## Scope

- Replaced the static `/audit-logs` parity shell with a live mobile audit surface.
- Uses existing API contracts:
  - `GET /activities`
  - `GET /activities/:id`
  - `GET /system-logs`
  - `GET /system-logs/:id`
- Shows user activity and system request history as mobile cards.
- Adds activity/system tabs, summary metrics, loading, retryable error, empty states, and bottom-sheet detail views.
- Keeps potentially sensitive live detail evidence out of committed screenshots.

## RED

Command:

```bash
rtk flutter test test/features/insights/audit_log_screen_test.dart
```

Result: failed against the placeholder screen.

Observed failures:

- `1 activity` was not rendered.
- `Created transaction Lunch` was not rendered.
- `Audit logs unavailable` retry state was not rendered.

## GREEN

Command:

```bash
rtk flutter test test/features/insights/audit_log_screen_test.dart
```

Result: `+3: All tests passed!`.

Covered behavior:

- Activity and system log lists render from `InsightsRepository`.
- System tab renders endpoint, status, latency, and user agent.
- Activity detail opens via `getActivity`.
- System log detail opens via `getSystemLog`.
- Initial load failures show a retryable error state.

## Verification

Commands:

```bash
rtk dart format lib/features/insights/application/audit_log_controller.dart lib/features/insights/presentation/audit_log_screen.dart test/features/insights/audit_log_screen_test.dart
rtk flutter analyze
rtk flutter test test/features/insights
rtk flutter test test/features/settings/module_navigation_test.dart
rtk flutter test
rtk flutter build apk --debug --dart-define=AFFLUENA_API_BASE_URL=http://43.133.147.101/api/v1
```

Results:

- Format completed.
- Analyze passed: no issues found.
- Insights tests passed: 10 tests.
- Settings module navigation passed: 3 tests.
- Full Flutter suite passed: 120 tests.
- Debug APK built at `build/app/outputs/flutter-apk/app-debug.apk`.

## Manual QA

- Device: iPhone 17 simulator, iOS 26.5.
- App command: `rtk flutter run -d 20CF90DC-E403-4AB2-9BA2-83A207FB5640 --dart-define=AFFLUENA_API_BASE_URL=http://43.133.147.101/api/v1`.
- Login state: existing seed user session on VPS.
- Flow:
  - Opened More.
  - Scrolled to Insights with keyboard Page Down after pointer drag stopped advancing.
  - Opened Audit logs from Settings.
  - Verified live activity count and system request count from VPS.
  - Opened Activity detail sheet and verified entity type/id fields are shown.
  - Switched to System logs and verified live request cards show endpoint, status, latency, and user agent.
  - Opened System log detail sheet and verified client IP, request payload, response payload, and created date are available in a scrollable sheet.
  - Hot reloaded plural-label polish and verified `21 activities` / `20 system requests` render without overflow.

## Visual Evidence

- System logs screen: `.omo/evidence/task-7-audit-logs-system-ios.png`

## Runtime Hypotheses Checked

1. The audit screen could remain a static shell while route navigation still passes.
   - Confirmed by RED widget test before implementation.
   - Refuted after implementation by widget test and manual VPS run showing live activity/system request data.
2. Parallel loading of activity and system logs could leave an unhandled failed future.
   - Confirmed by an initial failing error-state test when both repository calls failed.
   - Fixed by awaiting both repository futures through one `Future.wait` and verified by retry-state test.
3. Detail sheets could overflow when system log payloads are long.
   - Confirmed by initial focused test rendering overflow in the detail sheet.
   - Fixed by wrapping detail content in `SingleChildScrollView` and verified by test + manual payload detail QA.

## Notes

- A Flutter tool crash occurred once when running multiple Flutter commands in parallel against native assets. The same insights test passed when rerun serially; final verification commands were run serially.
- No backend endpoint or mobile-only API contract was added.
- Review-work subagents were not spawned because the available `multi_agent_v1` tool policy allows spawning only when the user explicitly asks for delegation/subagents. The review-work fallback was inline goal/code/security/QA review using diff inspection, tests, build, and manual simulator QA.
