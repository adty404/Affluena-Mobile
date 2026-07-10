# Affluena-MOBILE — orientation for a fresh session

Personal-finance **Flutter app** (Riverpod + Dio + go_router), pinned to **Flutter 3.44.2** via
`fvm` (`.fvmrc`), Dart `^3.12.2`. Talks to the Affluena-API backend.

Depth lives in **`DESIGN.md`** (design system), **`SHOREBIRD.md`** (release/OTA), `README.md`, and
the pixel-level **`design/affluena-design-guide.html`** (open in a browser — visual source of truth).
**`docs/PLAYSTORE.md`** is the single master checklist for the Google Play submission prep
(status per item, keystore/AAB guide, the 1.5.0 release package, listing + Data Safety drafts) —
update it in the same PR whenever any of its items changes.

## ⚠️ Read before you change anything (prod danger)

- **Merging to `master` auto-ships an OTA patch to every installed app.** `.github/workflows/shorebird.yml`
  runs on push to `master` touching `lib/**`, `assets/**`, `pubspec.yaml`, `pubspec.lock`, or
  `shorebird.yaml`, and **auto-publishes a Shorebird patch** that installed apps download on next
  launch (`auto_update` is on). A merged Dart change = a production OTA. Confirm before merging.
- **Patch vs Release** (`SHOREBIRD.md`): Dart/UI/logic changes ship as an **OTA patch**
  (`scripts/shorebird_patch.sh`, no reinstall). **Native** changes (new plugin, Android/Gradle,
  Flutter bump) or a version bump need a **release** (`scripts/shorebird_release.sh` → reinstall the
  APK once) — they are NOT patchable. Builds pass `--no-tree-shake-icons` so the full Material Icons
  font is always bundled (adding/removing icons stays OTA-patchable); other asset changes need a release.
  The push-triggered patch job **fails fast if `pubspec.yaml`'s `version:` changed** (a bump means you
  needed a *release*; the auto-patch targets the previous release) — so bump the version only when
  you intend to run the release workflow manually.

## Run / test / build (Flutter SDK is NOT pre-installed in a cloud sandbox — install fvm + 3.44.2 first)

```bash
fvm install 3.44.2 && fvm flutter pub get      # one-time setup
fvm flutter analyze                             # lint/type gate (CI runs this)
fvm dart format lib test                        # CI also gates on formatting (--set-exit-if-changed) — run before pushing
fvm flutter test --exclude-tags golden          # unit/widget tests (CI runs this)
fvm flutter test                                # includes goldens — macOS only, must use fvm's 3.44.2
bash scripts/build_apk.sh                        # sideload APK (bakes the API URL via --dart-define)
```

- **API base URL is a compile-time constant**: `AppConfig.apiBaseUrl` =
  `String.fromEnvironment('AFFLUENA_API_BASE_URL', default 'http://localhost:8080/api/v1')`
  (`lib/core/config/app_config.dart`). Cannot change at runtime — pass
  `--dart-define=AFFLUENA_API_BASE_URL=…` at build/run, or the app falls back to localhost and shows
  *"Tidak bisa terhubung ke Affluena."*
- **Goldens are macOS-only** and rendered with a placeholder font (drift detector, not a pixel
  match). Regenerate with `fvm flutter test --update-goldens`.

## Architecture

- `lib/main.dart` → `lib/app/affluena_app.dart` (MaterialApp.router) → `lib/app/router.dart` (go_router).
- `lib/core/` → `api` (Dio client + interceptors, single-flight refresh), `config`, `formatters`
  (`MoneyFormatter`, `AffluenaDateFormatter`), `storage` (secure token store), `calc`.
- `lib/features/<x>/` → one folder per feature, each layered:
  - `data/` → models + a `Repository` (a `Provider` over `dioProvider`)
  - `application/` → a `NotifierProvider`/`AsyncNotifier` controller (auto-loads via `Future.microtask(load)`, `_mutate` helper). Their `copyWith` methods distinguish "omitted" from "set to null" using the **shared `kUnchanged` sentinel** from `core/state/copy_with_sentinel.dart` — don't redeclare a per-file `_unchanged`.
  - `presentation/` → screens/widgets
  Features: auth, wallets, transactions, budgets, categories, tags, goals, debts, trackers,
  recurring, quick_entry, dashboard, insights, settings, onboarding, **partner** (the "Berbagi
  Dompet" sharing feature), **redesign** (the Beranda dashboard + bottom-nav shell), shared.

## Design system — "Tinta" monochrome (see DESIGN.md + design/affluena-design-guide.html)

- The palette is **monochrome ink**: accent = ink (near-black, flips to WHITE in dark mode);
  colour only for meaning (income green, danger coral, amber warning, user wallet colours).
  Anything rendered ON an accent fill must use `context.sky.onAccent` — hardcoding
  `Colors.white` there is a dark-mode bug. (The design-guide HTML mockups still show the
  retired denim-blue colours; §2 of DESIGN.md is the colour source of truth.)
- **Two token accessors, same theme** (`lib/app/theme/`): the older `context.affluenaColors.*`
  (forest/ink/inkMuted/coral/…) used by list/form screens, and the newer `context.sky.*`
  (accent/ink/muted/surface/line/…) used by detail screens. Both are real; match the surrounding file.
- Spacing/radii via `AffluenaSpacing`, `AffluenaRadii`, `AffluenaInsets` (never magic numbers).
- **Reuse the shared widgets** in `lib/features/shared/presentation/widgets/` — `DrillInScaffold`
  (back chrome), `AffluenaCard`, `SectionHeader`, `MetricTile`, `StatusBadge`, `AffluenaBanner`,
  `sky_detail.dart` (`SkyDetailHero/Card/Row/StatusPill/Placeholder` + `skyConfirm`),
  `SkyProgressBar`, `SkySegmentedToggle`. **Chip rows use `AffluenaChipBar` (single-line, scrollable)
  wrapping `AffluenaChoiceChip`** — never a ragged `Wrap` of Material `ChoiceChip`s.
- **`skyConfirm` is THE app-wide confirmation surface** — a Tinta modal bottom sheet (soft-tinted
  icon tile, w700 title, muted message, full-width confirm over cancel; keys `sky-confirm-accept` /
  `sky-confirm-cancel`). Pass `danger: true` for destructive confirms (delete / cancel / revoke /
  sign-out — coral tile + coral confirm button) and optionally `icon:` to override the glyph. Never
  hand-roll an `AlertDialog` confirmation; info-only dialogs (single OK) are out of scope.

## Conventions & gotchas

- **Money = integer minor units**; format with `MoneyFormatter` (Rp grouping). Locale is `id_ID`
  (initialized in `main`); date widgets use `AffluenaDateFormatter`.
- **API dates are full RFC3339 timestamps even for `DATE` columns** — a budget's `month` arrives as
  `"2026-06-01T00:00:00Z"`, not `"2026-06"`. Parse defensively (take the `YYYY-MM` prefix); assuming a
  short date throws and blanks the screen.
- **Never re-send a stored RFC3339 value into a date-only API field.** The write side of the rule
  above: fields like a subscription's `next_due_date`, an installment's `start_date`, and a debt's
  `due_date` expect `YYYY-MM-DD`, and the tracker endpoints **400** on a full timestamp (this made
  "Jeda langganan" silently do nothing). Any request builder that round-trips a stored date must
  normalize it through `AffluenaDateFormatter.apiDate` (prefix-based — no timezone conversion, so
  the calendar day never shifts). Timestamp fields (`transaction_at`, `paid_at`, `next_run_at`,
  `opened_at`, goal `deadline`) stay full RFC3339.
- **Tests are hermetic**: full-app tests use `authTestApp`/`pumpAuthTestApp` (overrides every repo
  with fakes). `redesign_shell_test` uses its own `ProviderScope` and stubs controllers directly.
- **Item appearance (color/icon)**: wallets, budgets, goals, installments, subscriptions, and
  recurring rules carry optional `color` (`#RRGGBB`) + `icon` (semantic id — never persist
  `IconData`). A valid color renders the item's card **solid** (bg+border = color, white text,
  white icon on a white-20% tile, white progress on white-25% track, `StatusBadge(onColor: true)`
  pills; over-budget danger fill still wins) on Beranda AND every domain list screen. Icons resolve
  via `resolveEntityIcon`/`entityIconFor` in `item_appearance.dart` — the union of the category +
  wallet catalogs, category winning on an id clash; budgets prefer budget.icon → category icon →
  pie glyph, wallets keep `resolveWalletIcon`. See DESIGN.md "Item Appearance".
- **Category appearance & ordering**: categories carry client-owned `icon` (semantic id → catalog in
  `lib/features/shared/presentation/appearance/item_appearance.dart`, `resolveCategoryIcon`) and
  `color` (`#RRGGBB` from the shared **24-swatch** `kItemColorPalette` — first 10 are the original
  set, never reordered; new swatches only appended so stored picks stay valid), plus a server-side
  `position` (the user's arranged order). **Don't pass `sort` when listing categories** — the API
  default is position ASC and every list/picker must respect it. **Reorder lives only on the master
  Kategori screen** (`CategoryTagManagementScreen`): each row has a visible `Icons.drag_indicator`
  handle **on the left** (`ReorderableDragStartListener`, immediate drag) that rearranges within a
  sibling group and persists the full flattened id list via `PUT /categories/reorder` (optimistic +
  revert on failure). The master screen's add button is a plain **`Icons.add`** (no tree glyph); its
  create/edit form shows the expense/income toggle **only on create** — a category's type is fixed
  once it exists (editing changes name/icon/color/parent only). The shared `showCategoryTreePicker`
  is **selection-only** — no in-place reorder and no inline create; its header has a search icon
  (`category-picker-search-button`, toggles the `Cari kategori` field — the field is hidden until
  tapped, not always-on) and a "Kelola kategori" gear (`category-picker-manage-button`) that pushes
  the master screen for all CRUD + reorder, and `onMutated:` refreshes the caller after returning.
- **Transaction-history rows show the category's icon+color everywhere**: every surface that lists
  transactions renders the transaction's category chosen icon in its chosen color on a soft tinted
  leading tile — the main ledger, the **Aktivitas** feed, the **Kalender** day sheet, **room/wallet
  detail**, the **budget detail** transaction list, and the **transaction detail sheet**. The shared
  resolver is `categoryAppearanceFor(Category?, {type})` in
  `transactions/presentation/transaction_display.dart` (the ledger's `transactionIcon` /
  `transactionIconColor` delegate to it); transfers keep the swap glyph, uncolored income/expense
  fall back to default theming. Surfaces without a `TransactionsState` watch
  `categoryTagManagementControllerProvider` for the category catalog. See DESIGN.md "Transaction Row".
  The **Aktivitas feed** and the **Wawasan per-category** screen share the public
  `TransactionActivityRow` (`transactions/presentation/transaction_activity_row.dart`); its row
  **title falls back to the category name** (then the type label) when a transaction has no note — so
  a note-less expense reads "Makanan", not "Pengeluaran".
- **The Aktivitas feed has search + date/kategori/dompet filters — ALL server-side**: search
  lives **behind a header icon** (`activity-search-button`, beside the filter button on the
  "Aktivitas" title row — mirroring the category picker): tapping toggles the field
  (`activity-search-field`, autofocus), collapsing clears the query instantly. The field
  debounces ~350ms into the API's `search=` param
  (full-history, matches note + category name + wallet name server-side — no more 100-row
  client-side ceiling). Two client-side guards on top: the query is **capped at 100 characters**
  (the API 400s past 100 runes; field `maxLength` + a rune clamp on the debounced value, no counter
  UI), and when the query could name a transaction-type label ("Transfer", "Pemasukan",
  "Pengeluaran", "Penyesuaian") the provider ALSO fetches the same window unsearched and unions in
  note-less uncategorized rows whose **rendered type-label title** matches — server search can't
  see those synthesized titles, and the ledger tab's client search still matches them. An emptied
  search field applies instantly (no debounce) and the empty-state disambiguation reads the
  **debounced** query (the one that produced the shown data), never the live field text. The
  `Icons.tune` **filter button** (`activity-filter-button`) reuses
  the ledger's `showTransactionFilterSheet` with `initialFilters:` (seed from the feed's own
  filters, decoupled from the ledger state) + `includeTag: false` (Aktivitas filters by
  date/category/wallet only). `recentActivityProvider` is a
  **`FutureProvider.autoDispose.family`** keyed on `ActivityQuery`
  (`{walletId, categoryId, from, to, search}` — a record, so the key is value-stable); the all-null
  query is the default unfiltered feed. Active filters show as an `AffluenaChipBar` with an
  "Atur ulang" chip (`activity-clear-filters`); a search/filter that matches nothing shows a
  distinct "Tidak ada transaksi yang cocok" empty state, separate from "Belum ada transaksi".
- **Device notifications are LOCAL and rules-gated (no FCM/Firebase)** —
  `lib/features/notifications/`: `due_reminder_planner.dart` (pure: dues + rules + now →
  `PlannedReminder` list — H-3 & H-1 at 09:00 local for upcoming installments/subscriptions/debts,
  deterministic ids, past instants skipped, cap 50), `notification_scheduler.dart` (debounced ~3s
  `requestResync(summary)`: fetch `notification_rules` → disabled/missing `due-reminder` rule ⇒
  cancel-all & arm nothing; rules-fetch failure ⇒ abort quietly WITHOUT cancelling what's armed;
  runs are **serialized + generation-guarded** so overlapping resyncs can't interleave, and a
  non-empty plan is swapped **arm-first then prune** — deterministic ids overwrite in place, then
  stale ids are cancelled via `listPendingIds()`/`cancelIds()`, so a crash mid-resync leaves the
  old set or a superset armed, never nothing), `local_device_notifications.dart`
  (flutter_local_notifications adapter — Android only, inexact `zonedSchedule`, channel
  "Pengingat jatuh tempo", every call fail-quiet). Resync hooks: the Beranda summary load
  (`dashboard_home_controller.dart` — covers app start AND every financial mutation, since
  `dashboardSummaryProvider` is in `_balanceProviders`) plus a **due-reminder rule toggle**
  (`InsightsController.updateRule` calls `scheduler.resyncLatest()`, falling back to invalidating
  `dashboardSummaryProvider` when no summary was seen yet) — so turning the rule off cancels armed
  reminders immediately, no money mutation needed. **Logout and a discarded restored session call
  `scheduler.clear()`** (fire-and-forget: cancels the pending debounce + every armed notification)
  so the old account's reminders can't keep firing. Pengaturan → Aturan notifikasi hosts
  `DeviceNotificationsCard` ("Aktifkan notifikasi perangkat", requests Android 13+
  POST_NOTIFICATIONS once). **This plugin is a NATIVE change: it shipped as the 1.4.0+7 Shorebird
  RELEASE** — future Dart edits are patchable again, but touching the plugin set/Android config
  needs another release.
- **Beranda gained three data sections**: "Jatuh tempo terdekat" (nearest 3 dues merged across
  upcoming subscriptions/installments/debts, tappable to their domain screens, hidden when empty),
  a savings-rate tile (monthly cashflow ÷ income, "—" when income is 0), and the "Tren kekayaan
  bersih" sparkline (custom-painted, 12 points from `buildNetWorthSeries` in
  `dashboard/application/net_worth_series.dart` — anchors current `net_worth_minor` and walks
  backward subtracting each month's net cashflow; the series is **clamped to start at the earliest
  own-wallet `createdAt` month** because wallet initial balances and adjustment transactions are
  invisible to the cashflow trend and would otherwise back-propagate into older points).
- **Every transaction row is tappable → the detail sheet**: tapping a transaction anywhere it's
  listed opens `showTransactionDetail(context, ref, txState, tx)` (view / edit / delete) — the ledger,
  Aktivitas, the Kalender day sheet, **room/wallet detail**, the **budget detail** list, and the
  **Wawasan per-category transactions** screen. Surfaces
  outside the global ledger (room detail, budget detail, calendar) pass
  `ref.read(transactionsControllerProvider)` as `txState` (it powers name resolution + edit/delete)
  even though their rows come from a feature-local provider. The detail sheet is a polished hero
  (category icon + type pill + big signed amount) over a details card; **editing a transaction can
  change its date & time** (the edit form has a `Tanggal & waktu` selector wiring `showDatePicker` +
  `showTimePicker` into `transactionAt`).
- **`invalidateBalances()` also refreshes the standalone transaction-list surfaces** the main ledger
  controller doesn't own — the cross-wallet **Aktivitas** feed (`recentActivityProvider`, an
  `autoDispose.family` over `ActivityQuery` — listed bare so every alive keyed instance refreshes),
  each **room/wallet detail** list (`walletTransactionsProvider`), the **budget-detail "Transaksi"** list
  (`categoryTransactionsProvider`, a `(categoryId, monthIso)` family), the **Wawasan breakdown**
  (`categoryBreakdownProvider`), the **Wawasan per-category transactions** list
  (`categoryTransactionsInRangeProvider`, a `(categoryId, DateRange)` family — the screen a tapped
  breakdown row opens), and the legacy **Laporan** controller (`insightsControllerProvider`)
  are all in the shared `_balanceProviders` set (`shared/application/financial_refresh.dart`).
  Without this a quick-add (or any non-ledger mutation) moved balances but left those surfaces stale.
  (The quick-entry screen now calls `invalidateFinancialData()` for the same reason.)
- **Calendar day sheet is add/edit-capable + day-steppable**: tapping any day in the Kalender grid
  opens a sheet with a **"Tambah"** button (`showSkyQuickAddSheet(context, date: day)` — quick-add
  gained a `date` param that stamps the transaction on that day, keeping the wall-clock time) and
  **tap-to-edit** rows (`showTransactionDetail`). The title is flanked by **‹ ›** steppers
  (`calendar-day-prev` / `calendar-day-next`) that move to the adjacent day without closing the
  sheet — the sheet is a `ConsumerStatefulWidget` holding the shown `_day`, and `_stepDay` uses
  `DateTime(y, m, d ± 1)` so it crosses month/year boundaries (the month-keyed
  `calendarMonthProvider` watch re-points to the new month). "Tambah" always targets the shown day. It watches `calendarMonthProvider`, and `invalidateBalances()` now also
  invalidates that provider, so any money mutation (from anywhere) refreshes the calendar grid + open
  day sheet live.
- **Sharing feature naming**: UI "Berbagi Dompet"; people you invite are "Pemantau" (max 5, one-way,
  read-only); the wallets others share to you show under Beranda's "Dibagikan untukku" section /
  `SharedWithMeScreen` (rendered as full cards mirroring Beranda's, **no "LIHAT" badge**). Endpoints
  are `/api/v1/partners` (historical) — see the API repo's contract.
- **Only the invitee can answer a wallet invitation**: the API rejects a respond on someone else's
  membership, so `WalletMembersSection` renders Terima/Tolak **only on the signed-in user's own
  pending row** (`member.userId == authControllerProvider.user?.id`); anyone else's pending row
  shows the neutral "Undangan untuk <email> menunggu jawaban mereka." line instead — never render
  buttons the API will always reject.
- **Account deletion is self-service** (Google Play requirement): Pengaturan → "Hapus akun"
  (`settings-delete-account-row`) opens `delete_account_sheet.dart` — password re-entry →
  `AuthController.deleteAccount` (`DELETE /auth/account`); on success it clears tokens + armed
  reminders and lands on login; on failure the user STAYS signed in and the sheet shows the API
  error. Public web counterparts: `/privacy` + `/hapus-akun` (Affluena-WEB).
- **Every form text field carries an Indonesian `hintText`** (see DESIGN.md "Form Field Hints"):
  `cth:`-prefixed examples for free-text, bare examples for name-like fields, and **bare id_ID-
  grouped digits for `MoneyInput` hints** (the widget hardcodes the `Rp ` prefix — `cth:` inside it
  would render "Rp cth: 50.000"). Plain-string hints keep `const InputDecoration`s const.
- **`WalletsScreen` = your own spending wallets only**: it excludes goal-backing wallets (`isGoal` —
  they live under Tabungan) and wallets shared TO you (`isViewer` — they live under "Dibagikan
  untukku"), mirroring Beranda's Dompet section. Because sharing is one-way read-only, "Bersama" in
  the summary means *your* wallets you've shared to a Pemantau (`members.isNotEmpty`); "Pribadi" means
  not shared. The card subtitle is terse (`type · Bersama|Pribadi`) so it never truncates in the
  2-column grid; the full description shows on the wallet detail screen.
