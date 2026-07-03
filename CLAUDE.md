# Affluena-MOBILE — orientation for a fresh session

Personal-finance **Flutter app** (Riverpod + Dio + go_router), pinned to **Flutter 3.44.2** via
`fvm` (`.fvmrc`), Dart `^3.12.2`. Talks to the Affluena-API backend.

Depth lives in **`DESIGN.md`** (design system), **`SHOREBIRD.md`** (release/OTA), `README.md`, and
the pixel-level **`design/affluena-design-guide.html`** (open in a browser — visual source of truth).

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

## Run / test / build (Flutter SDK is NOT pre-installed in a cloud sandbox — install fvm + 3.44.2 first)

```bash
fvm install 3.44.2 && fvm flutter pub get      # one-time setup
fvm flutter analyze                             # lint/type gate (CI runs this)
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
  - `application/` → a `NotifierProvider`/`AsyncNotifier` controller (auto-loads via `Future.microtask(load)`, `_mutate` helper)
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

## Conventions & gotchas

- **Money = integer minor units**; format with `MoneyFormatter` (Rp grouping). Locale is `id_ID`
  (initialized in `main`); date widgets use `AffluenaDateFormatter`.
- **API dates are full RFC3339 timestamps even for `DATE` columns** — a budget's `month` arrives as
  `"2026-06-01T00:00:00Z"`, not `"2026-06"`. Parse defensively (take the `YYYY-MM` prefix); assuming a
  short date throws and blanks the screen.
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
  is **selection-only** — no in-place reorder and no inline create; its header has a "Kelola kategori"
  gear (`category-picker-manage-button`) that pushes the master screen for all CRUD + reorder, and
  `onMutated:` refreshes the caller after returning.
- **Transaction-history rows show the category's icon+color everywhere**: every surface that lists
  transactions renders the transaction's category chosen icon in its chosen color on a soft tinted
  leading tile — the main ledger, the **Aktivitas** feed, the **Kalender** day sheet, **room/wallet
  detail**, the **budget detail** transaction list, and the **transaction detail sheet**. The shared
  resolver is `categoryAppearanceFor(Category?, {type})` in
  `transactions/presentation/transaction_display.dart` (the ledger's `transactionIcon` /
  `transactionIconColor` delegate to it); transfers keep the swap glyph, uncolored income/expense
  fall back to default theming. Surfaces without a `TransactionsState` watch
  `categoryTagManagementControllerProvider` for the category catalog. See DESIGN.md "Transaction Row".
- **Calendar day sheet is add/edit-capable**: tapping any day in the Kalender grid opens a sheet with
  a **"Tambah"** button (`showSkyQuickAddSheet(context, date: day)` — quick-add gained a `date` param
  that stamps the transaction on that day, keeping the wall-clock time) and **tap-to-edit** rows
  (`showTransactionDetail`). It watches `calendarMonthProvider`, and `invalidateBalances()` now also
  invalidates that provider, so any money mutation (from anywhere) refreshes the calendar grid + open
  day sheet live.
- **Sharing feature naming**: UI "Berbagi Dompet"; people you invite are "Pemantau" (max 5, one-way,
  read-only); the wallets others share to you show under Beranda's "Dibagikan untukku" section /
  `SharedWithMeScreen`. Endpoints are `/api/v1/partners` (historical) — see the API repo's contract.
