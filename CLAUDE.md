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

- **Text scaling is clamped at 1.1×** at the app root (`AffluenaApp`'s
  `MaterialApp.router` `builder:` wraps a `MediaQuery` with
  `textScaler.clamp(maxScaleFactor: 1.1)`, no minimum) — the standard
  finance-app behaviour so huge system fonts can't break money layouts. Never
  bypass it per-widget. Locked by `test/app/text_scale_clamp_test.dart`.
- **"Tinta Compact" density (2026-07)** — the agreed compaction: hero money
  24/w700 (was 28–30/w800), secondary big numbers 18–19 (was 20–22), screen
  h1s + the `DrillInScaffold`/AppBar title 18 (was 21–22), Beranda section
  titles 15.5, content-card padding 12 (was 14), card/row radius 14 (was the
  literal 16 — sheets/pills untouched), leading icon tiles 30×30 w/ 16px glyph
  (was 34×34/18), between-section gap `space5` (was `space6`), list-row
  vertical padding 9 (was 11). Meta text never below 10.5; tappable rows never
  below a 48px touch target; money keeps tabular figures. Match these numbers
  on new surfaces — see DESIGN.md §3/§4.
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
- **Saldo masking**: the Beranda hero's eye toggle
  (`beranda-amount-visibility-toggle`) flips the global, persisted
  `amountVisibilityProvider` (`shared/application/amount_visibility.dart`,
  key `affluena.amounts_visible`, default visible). Masked surfaces render
  `MoneyFormatter.maskedIdr(minor, visible:)` → the fixed `Rp ••••••`.
  Scope = balances/summaries only (Beranda hero + Ringkasan rupiah labels +
  all section-card amounts + dues, WalletsScreen hero/cards, room + wallet
  detail balances, SharedWithMe cards, goal detail saved/target); the
  **working ledger — transaction rows, detail sheets, Wawasan breakdown —
  always shows real amounts**. See DESIGN.md "Saldo masking".
- **Quick amount chips**: money-entry forms where a fresh amount is typed show
  the shared `QuickAmountChips` (`10rb · 50rb · 100rb · 500rb · 1jt`, keys
  `amount-chip-<minor>`); tapping SETS (replaces) the amount + a selection
  haptic. `MoneyInput(showQuickAmounts: true)` on the transaction create/edit
  forms; the quick-add sheet wires it to `MoneyCalculator.setAmountMinor`.
  Don't add chips to odd fields (adjustment "saldo baru", starting balances).
- **Haptics** (`lib/core/haptics.dart`): `hapticSuccess()` on the SUCCESS path
  of money mutations (tx create/edit/delete, quick-add save, template run,
  installment/subscription/debt payment, goal contribution — lives in the
  controllers) and `hapticTap()` on the `skyConfirm` accept + quick-amount
  chips. Never vibrate on errors. Platform-channel no-op in tests.
- **Beranda "Diperbarui HH.mm" stamp**: the hero sub-line appends the time the
  dashboard summary last ARRIVED — `dashboardRefreshedAtProvider`
  (non-autoDispose, null = hidden) is marked only in
  `dashboardSummaryProvider`'s real fetch path, timed by the overridable
  `clockProvider` (`core/clock.dart`). Tests that stub the summary provider
  never show the stamp; `authTestApp` pins the clock to 14:32 so full-app
  tests/goldens are deterministic. Format via
  `AffluenaDateFormatter.clockTime` (id-ID `HH.mm`).
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
  so the old account's reminders can't keep firing. Pengaturan → Aturan notifikasi
  (`AturanNotifikasiScreen`) hosts `DeviceNotificationsCard` ("Aktifkan notifikasi perangkat",
  requests Android 13+ POST_NOTIFICATIONS once). **This plugin is a NATIVE change: it shipped as
  the 1.4.0+7 Shorebird RELEASE**; **1.5.0+8 is another RELEASE** (image_picker added for the
  avatar upload, local_auth/USE_BIOMETRIC/NSFaceIDUsageDescription removed) — future Dart edits
  are patchable again, but touching the plugin set/Android config needs another release.
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
  `showTimePicker` into `transactionAt`). For a **transfer with an admin fee** the details card adds
  a **"Biaya admin"** row (formatted Rp); it's hidden for non-transfers and zero-fee transfers.
- **Transfer admin fee (`fee_minor`)**: transfers carry an optional admin fee — `TransactionRequest`
  and `Transaction` both hold `feeMinor` (minor units, default 0). Semantics: the **source wallet is
  charged `amount + fee`**, the destination receives `amount`, so the fee is a net-worth reduction.
  `TransactionRequest.toJson` emits `fee_minor` **only for a transfer AND only when > 0** (never on
  expense/income/adjustment); `Transaction.fromJson` reads it via `ApiJson.optionalInt` (absent → 0,
  since older rows / list responses may omit it). Both the **full form** (`transaction_create_screen.dart`,
  key `transaction-create-fee-field`) and the **quick-add sheet** (key `quick-add-fee-field`) show an
  optional **"Biaya admin (opsional)"** `MoneyInput` below "Ke dompet" when the type is transfer, reset
  when switching away from transfer. The **edit sheet** (`transaction-edit-fee-field`) seeds from the
  stored `feeMinor` and always sends it back on a transfer update — an edit that never touches the
  field preserves the fee (an absent `fee_minor` would zero it server-side); clearing the field to
  0 removes the fee (omitted-on-zero, which the API update reads as 0).
- **Quick-add now has a Transfer segment + an "Opsi lengkap" escape hatch** (`sky_quick_add_sheet.dart`):
  the "Catat cepat" segmented control gained a third **Transfer** option. Selecting Transfer hides the
  category picker and shows **"Dari dompet"** (`_walletId`) + **"Ke dompet"** (`_toWalletId`) selectors —
  both filtered through `Wallet.canRecordTo` (writable + non-goal) with the destination excluding the
  source (distinct + amount>0 gate the submit) — plus the optional admin-fee field; the request is built
  with no `categoryId`. A subtle **"Opsi lengkap"** text button (key `quick-add-full-form-link`) under the
  keypad closes the sheet and `context.push(TransactionCreateScreen.path)` to reach the full form
  (date/time, notes, tags, adjustment). The sheet's content above the keypad now scrolls (keypad + link
  stay pinned) so the extra transfer fields never overflow the fast-path sheet.
- **`invalidateBalances()` also refreshes the standalone transaction-list surfaces** the main ledger
  controller doesn't own — the cross-wallet **Aktivitas** feed (`recentActivityProvider`, an
  `autoDispose.family` over `ActivityQuery` — listed bare so every alive keyed instance refreshes),
  each **room/wallet detail** list (`walletTransactionsProvider`), the **budget-detail "Transaksi"** list
  (`categoryTransactionsProvider`, a `(categoryId, monthIso)` family), the **Wawasan breakdown**
  (`categoryBreakdownProvider`), the **Wawasan per-category transactions** list
  (`categoryTransactionsInRangeProvider`, a `(categoryId, DateRange)` family — the screen a tapped
  breakdown row opens), the **"Riwayat pembayaran"** lists on the installment/subscription detail
  screens (`installmentPaymentsProvider` / `subscriptionPaymentsProvider`, `autoDispose.family`
  over the item id — listed bare so paying refreshes the open history in place), and the legacy
  **Laporan** controller (`insightsControllerProvider`)
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
- **Avatars are uploaded photos stored as base64 data URLs** — Pengaturan → Akun replaces the old
  "URL avatar" text field with "Pilih foto"/"Hapus foto": the pick goes through
  `imagePickerProvider` (a Riverpod-wrapped `image_picker`, overridable in tests; the system photo
  picker needs **no storage permission**), is downscaled to ≤256px / JPEG q80 platform-side and
  guarded by the pure `encodeAvatarDataUrl` helper (`settings/application/avatar_picker.dart` —
  re-downscales in Dart via `ImageDescriptor.instantiateCodec` when the pick is still too big,
  hard cap ~120KB), then saved into the EXISTING `avatar_url` field as
  `data:image/...;base64,...` (unbounded text column — no server change, no file storage).
  **Render avatars only through `avatarImageProvider(url)`**
  (`shared/presentation/widgets/avatar_image.dart`): data URL → memoized `MemoryImage`, legacy
  http(s) → `NetworkImage`, anything else → null (fall back to the initial letter). Used by the
  Pengaturan profile card and `SkyAvatar` (via its optional `imageUrl`).
- **Laporan & Notifikasi are real separate screens** — the old chip-tabbed `InsightsScreen`
  (`/insights?tab=…`, one surface for reports/exports/alerts/activity/rules) was retired because
  three Pengaturan rows landed on the same screen differing only by selected chip. Each section is
  its own routed screen now: `LaporanScreen` (`/laporan`, keeps the report-kind chips — those are
  its own sub-views), `EksporScreen` (`/ekspor`), `PeringatanAktivitasScreen`
  (`/peringatan-aktivitas`, alerts + the audit-trail activity feed stacked on one scroll — they
  shared one Pengaturan entry), and `AturanNotifikasiScreen` (`/aturan-notifikasi`, incl.
  `DeviceNotificationsCard`). All of them keep reading the shared `insightsControllerProvider`
  (whose `InsightTab`/`selectedTab` were deleted); shared pieces live in
  `insights/presentation/insight_shared_widgets.dart`. **Legacy `/insights` deep links redirect**
  (route-level redirect in router.dart) so nothing 404s. Pengaturan also gained an "Ekspor CSV"
  row and dropped the redundant "Transaksi" row (the ledger is the Aktivitas bottom-nav tab).
- **List cards drill into their detail screens**: budget cards (Anggaran), installment +
  subscription cards (Cicilan & Langganan), and goal cards (Target tabungan) are whole-card
  tappable (InkWell ripple) → the same detail screens Beranda's dashboard cards open; edit/delete/
  pay stay on their own buttons/menus. The tracker details show a **"Riwayat pembayaran"** section
  (`GET /installments/:id/payments` / `GET /subscriptions/:id/payments` → `{ "payments": [...] }`
  paid_at DESC; rows tap → fetch the `transaction_id` → `showTransactionDetail`), and the goal
  detail shows **"Riwayat setoran"** — the transactions of the wallet whose `goalId` matches
  (goals are funded via their backing goal wallet; section hidden when no wallet matches).
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
  not shared. The header hero is a calm `Total saldo` over one row of compact soft-tinted stat
  chips (Dompet / Bersama / Pribadi) — no explainer paragraphs, and the **Bersama chip is hidden
  while the count is 0** so an all-private list shows no "Bersama 0" noise (golden:
  `wallets_header`). The card subtitle is terse (`type · Bersama|Pribadi`) so it never truncates
  in the 2-column grid; the full description shows on the wallet detail screen.
