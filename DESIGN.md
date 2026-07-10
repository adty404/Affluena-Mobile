# Affluena Mobile Design System

> **📐 Visual source of truth:** pixel-level mockups of every screen live in
> [`design/affluena-design-guide.html`](design/affluena-design-guide.html) — one
> self-contained file (open it in any browser). This `DESIGN.md` is the *written*
> spec; the HTML is the *visual* reference. Keep the two in sync.
>
> **Build status:** the app now matches the guide — shipped: the monochrome
> **Tinta** palette (which replaced Sky & Denim; the guide's mockup colours
> predate it), dark mode, the icon-only floating pill nav, the bundled **Inter** type,
> the **6-section Beranda dashboard** (§1), the per-item **detail screens** (§8,
> opened from the dashboard cards), and the **quick-add "Catat cepat" sheet with
> a `PAKAI TEMPLATE` one-tap row** (§1).

## 1. Atmosphere & Identity

Affluena Mobile feels like a calm personal finance companion for daily use: light, tactile, trustworthy, and quick to operate. The visual language is **"Tinta"** — a monochrome ink interface: neutral off-white/near-black surfaces, an accent that *is* the ink (white in dark mode), and heavy "tegas" type. Colour is reserved for **meaning only**: income green, danger coral, amber warnings, and user-chosen content colours (e.g. wallet colours) — which makes the little colour there is highly scannable. (Both earlier directions — warm-paper "Editorial Light" and denim-blue "Sky & Denim" — are fully retired.)

### Information architecture

The authenticated shell (`RedesignShell`, route `/beranda`) is an **icon-only floating pill** bottom-nav with four tabs — **Beranda** · **Aktivitas** (cross-wallet feed) · **Kalender** (monthly money calendar: per-day masuk/keluar/selisih, swipe between months, tap any day for a sheet of its transactions — with a "Tambah" button that quick-adds on that date and tap-to-edit on each row) · **Wawasan** (insights) — plus a center quick-add **FAB** and a **"Lainnya"** item that opens **Pengaturan** (Settings), the hub for the remaining feature screens.

#### Beranda — sectioned dashboard

Beranda is a single scrollable dashboard. A `Total saldo` hero (with a month delta) sits on top, then a **Ringkasan** row — a savings-rate tile (monthly cashflow ÷ income, "—" when income is 0) beside a **"Tren kekayaan bersih"** sparkline (12 custom-painted points from `buildNetWorthSeries`: anchored at the current net worth, walking backward through each month's net cashflow) — and, only when dues exist, **"Jatuh tempo terdekat"** (the nearest 3 across cicilan/langganan/utang, each row tappable to its domain screen). Below those come the money-domain **sections** — each a titled header with a "Lihat semua" link over a **2-column card grid**; tapping a card opens that item's detail. The sections, in order:

1. **Dompet** — wallets (shared wallets show member avatars + a "Bersama" badge)
2. **Anggaran** — budgets (each card shows a spend-progress track)
3. **Tabungan** — savings goals
4. **Cicilan** — installments
5. **Langganan** — subscriptions
6. **Berulang** — recurring

Cicilan, Langganan, and Berulang stay **separate** — deliberately *not* merged into a single "Tagihan" section.

#### Quick-add — "Catat cepat"

Logging is a fast bottom-sheet: a **template row inside the sheet** (one-tap presets like *Kopi · Rp 25.000*), an expense/income segment, an `Rp` amount with a calculator keypad, and wallet + category pickers — the wallet is pre-set when the sheet is opened from a wallet context. Templates live **inside** the sheet, not as chips on top of Beranda.

> **Build note:** the 6-section dashboard is the **live** Beranda (the first nav tab, `BerandaDashboardView`). Tapping a card opens that item's detail screen (§8). The older wallet-**"rooms"** home (`RoomsHomeView`) remains only behind the `/rooms` deep-link route + the wallet detail. Aktivitas, Wawasan, Lainnya→Pengaturan, and the quick-add flow are unchanged in intent.

## 2. Color

The redesign surfaces read colours from **`SkyColors`** (`lib/app/theme/sky_palette.dart`) via the `context.sky` extension, which resolves **light and dark** by the active brightness. The themed feature screens use the `AffluenaColors` / `AffluenaSemanticColors` theme extension (`lib/app/theme/affluena_theme.dart`), kept aligned to the same Tinta values (its `forest` token now carries the ink accent). Class/token names keep their historical `Sky*` prefixes.

### Tinta palette (`SkyColors`)

| Role | Token | Light | Dark | Usage |
|------|-------|-------|------|-------|
| Ground | `ground` | `#F7F7F5` | `#0C0D0F` | App background |
| Surface | `surface` | `#FFFFFF` | `#17181B` | Cards, the floating nav pill |
| Sheet | `sheet` | `#F1F1EF` | `#1D1E22` | Bottom sheets, tinted tiles |
| Line | `line` | `#E5E5E3` | `#2A2B2F` | Borders, dividers |
| Ink | `ink` | `#17181A` | `#F2F2F1` | Headlines, body, money values |
| Muted | `muted` | `#6E7073` | `#9B9DA1` | Secondary text |
| Faint | `faint` | `#A4A5A8` | `#6E7074` | Tertiary text, inactive icons |
| Accent (ink) | `accent` | `#17181A` | `#F2F2F1` | Primary actions, active nav, FAB — same as `ink`, white in dark |
| On accent | `onAccent` | `#FFFFFF` | `#0C0D0F` | Icon/label ON an accent fill (never hardcode white) |
| Accent soft | `accentSoft` | `#ECECEA` | `#232428` | Selected surfaces, active-nav circle |
| Accent soft border | `accentSoftBorder` | `#DCDCDA` | `#3A3B40` | Pill / badge borders |
| Accent ink | `accentInk` | `#17181A` | `#F2F2F1` | Text on accent-soft pills |
| Avatar primary / secondary | `avatarPrimary` / `avatarSecondary` | `#17181A` / `#77797D` | `#4A4C51` / `#33353A` | Member avatars (white initials in both modes) |
| Income / success | `income` | `#2E8B57` | `#6BC089` | Positive cashflow |
| Danger | `danger` | `#C2553F` | `#E08070` | Destructive actions, errors |

### Rules

- The app is **dark-mode aware** (follows the system / in-app theme controller); both palettes above ship. Dark mode is the *inverted* ink scheme — the accent flips to white.
- `accent` is reserved for primary actions, the active nav tab, and the quick-add FAB. Anything rendered **on** an accent fill must use `onAccent` (it flips to near-black in dark mode) — hardcoded `Colors.white` on accent is a dark-mode bug.
- Colour carries **meaning only**: `income`, `danger`, `AffluenaColors.amber` (warnings), user-chosen content colours (wallet colours), and the **section hues** (`lib/app/theme/section_palette.dart`) — one identity hue per Beranda money domain (Dompet denim · Dibagikan magenta · Anggaran amber · Tabungan green · Cicilan indigo · Langganan violet · Berulang teal), applied as soft card tints + saturated icons; text on tinted cards stays ink. Everything else is monochrome.
- No raw colors in redesign widgets — read from `context.sky`. For themed feature screens, extend `AffluenaColors`.

## 3. Typography

### Scale

| Level | Size | Weight | Line Height | Tracking | Usage |
|-------|------|--------|-------------|----------|-------|
| Display | 34 | 800 | 1.12 | -0.02em | Hero money values (`Total saldo`, detail balances) |
| H1 | 28 | 800 | 1.18 | -0.02em | Screen titles |
| H2 | 22 | 800 | 1.25 | -0.02em | Onboarding headline, large section headers |
| H3 | 18 | 700 | 1.30 | 0 | Card titles |
| Body/lg | 16 | 500 | 1.45 | 0 | Prominent row text |
| Body | 14 | 400 | 1.45 | 0 | Default mobile body |
| Body/sm | 13 | 400 | 1.40 | 0 | Secondary metadata |
| Caption | 12 | 600 | 1.35 | 0 | Labels, chips, nav text |

### Font Stack

- Primary: **Inter**, bundled as a font asset (`assets/fonts/`, weights
  400/500/600/700/800 — static instances of the Google Fonts Inter variable font,
  OFL) and set as the app `fontFamily`, so the type looks identical on every
  device. The system UI stack remains the implicit fallback.
- Display & title weights run **heavy (800)** with tight tracking so money reads
  bold and decisive — the guide's signature "tegas" look. Earlier builds felt
  *sepi / kurang tegas* with lighter system weights; the guide and the re-skin
  correct this.
- Numerals: tabular figures wherever money values appear.
- Mono: not used in the mobile UI baseline.

### Rules

- Body text must not drop below 12 and primary content should stay at 14 or above.
- Money values use **strong weight (800)**, clear contrast, and enough breathing room.
- Avoid uppercase microcopy except short labels in chips and section eyebrows.

## 4. Spacing & Layout

### Base Unit

All spacing derives from a base of 4.

| Token | Value | Usage |
|-------|-------|-------|
| `space1` | 4 | Tight icon/text gaps |
| `space2` | 8 | Compact row gaps |
| `space3` | 12 | Chips, small cards |
| `space4` | 16 | Default screen horizontal padding |
| `space5` | 20 | Comfortable card padding |
| `space6` | 24 | Major block gaps |
| `space8` | 32 | Screen section separation |

### Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radiusMd` | 14 | Selector row ink, compact icon marks |
| `radiusLg` | 16 | Status messages, compact grouped controls |
| `radiusControl` | 18 | Buttons, inputs, selected navigation pills |
| `radiusCard` | 20 | Cards and grouped list containers |
| `radiusSheet` | 24 | Modal bottom sheet top corners |

### Grid

- Primary layout: single-column mobile scroll with safe-area top and bottom.
- Screen padding: 20 horizontal for main content.
- Cards: 16 to 20 inner padding, 16 to 24 vertical gaps.
- Bottom navigation: a **floating pill** hovering over the content — 3 tabs (Beranda/Aktivitas/Wawasan) plus "Lainnya" and a center quick-add FAB.

### Rules

- No dense desktop tables on mobile. Lists become readable mobile rows/cards.
- Critical controls use touch-friendly height and clear labels.
- Major flows prioritize one primary action per screen.

## 5. Components

> **Navigation motion:** the app ships with **no page-route transitions** — every
> `GoRoute` uses `_noTransitionPage` (`lib/app/router.dart`, zero forward/reverse
> duration), so pushing/popping any screen is instant (per user preference). Do
> **not** reintroduce `_fadePage`/`_slidePage`-style animated pages. In-widget
> motion (button press, sheet slide-up, calendar month PageView) is unaffected.

### Affluena Card

- **Structure**: tonal surface container with rounded corners, optional border, and child content.
- **Variants**: hero, standard, tinted, warning.
- **Spacing**: `space4` or `space5` inner padding.
- **States**: resting, pressed, selected.
- **Accessibility**: contrast against `surfaceCanvas`, text labels over icon-only actions.
- **Motion**: subtle opacity/scale only when interaction is added.

### Money Metric

- **Structure**: label, value, optional helper/change text.
- **Variants**: hero balance, compact cashflow tile.
- **Spacing**: `space2` internal rhythm.
- **States**: neutral, positive, warning.
- **Accessibility**: value is text, never image-only.

### Transaction Row

- **Structure**: leading icon mark, title, metadata line, trailing amount and menu/action.
- **Variants**: income, expense, transfer, recurring.
- **Spacing**: `space3` inner gap, `space4` vertical padding.
- **States**: default, pressed, loading skeleton later.
- **Accessibility**: row title and amount must be readable without color alone.
- **Category icon + color (everywhere)**: the leading mark shows the
  transaction's category **chosen icon in its chosen color** on a soft tinted
  tile — the same treatment across **every** transaction-history surface, so a
  categorized transaction looks identical wherever it is listed. Transfers keep
  the swap glyph; income/expense with no category color fall back to the default
  theming. The canonical resolver is `categoryAppearanceFor(Category?, {type})`
  in `transactions/presentation/transaction_display.dart` (the ledger's
  `transactionIcon` / `transactionIconColor` delegate to it). Surfaces:
  - **Main ledger** (`transactions_screen.dart` via `TransactionTile`).
  - **Aktivitas feed** (`redesign/activity_feed_screen.dart`) — leading slot is
    the category tile; the "kamu" ownership signal lives in the meta line.
    `recentActivityProvider` **excludes rows from wallets shared TO me**
    (role `viewer`), mirroring the main ledger's `visibleTransactions` — the
    feed is *my* activity, not another person's. The feed fetches at most 100
    rows with no pagination, so when it comes back full the **oldest day-group
    (and header) is dropped** rather than shown as a complete day. The row is
    the shared public **`TransactionActivityRow`**
    (`transactions/presentation/transaction_activity_row.dart`), reused by the
    Wawasan per-category screen; its **title falls back to the category name**
    (then the type label) when the transaction has no note — a note-less
    expense reads "Makanan", not "Pengeluaran". The feed has a **search field**
    (`activity-search-field`, client-side case-insensitive `contains` over
    note / wallet / category — the same semantics as the ledger's
    `visibleTransactions`) and a **`Icons.tune` filter button**
    (`activity-filter-button`) that reuses the ledger's
    `showTransactionFilterSheet(initialFilters:, includeTag: false)` for
    **date / kategori / dompet** (no Tag) applied **server-side** through
    `recentActivityProvider`, now an **`autoDispose.family` keyed on
    `ActivityQuery`** (`{walletId, categoryId, from, to}`); active filters show
    as an `AffluenaChipBar` with an "Atur ulang" chip
    (`activity-clear-filters`), and a filter/search that matches nothing shows a
    distinct "Tidak ada transaksi yang cocok" empty state (separate from the
    unfiltered "Belum ada transaksi").
  - **Wawasan per-category transactions** (`redesign/sky_category_transactions_screen.dart`)
    — the list opened by tapping a Wawasan breakdown category row, rendered with
    the same `TransactionActivityRow` day-grouped over the full period range.
  - **Calendar day sheet** (`calendar/calendar_screen.dart`) — `TransactionTile`
    fed the category icon+color. Tapping any day opens this sheet. Header layout:
    a drag handle, the day title on its own line, a tidy **3-column
    masuk/keluar/selisih** summary (the same `_SummaryColumn`/`_SummaryDivider`
    the month header uses, so the amounts never collide), then a **full-width
    "Tambah transaksi"** button that opens quick-add pre-set to that date; each
    row is **tappable to edit** (opens the transaction detail sheet). The sheet
    watches `calendarMonthProvider`, and `invalidateBalances()` invalidates that
    provider, so add/edit/delete refresh the day + grid live. Locked by
    `test/goldens/calendar_day_sheet_golden_test.dart`.
  - **Room (wallet) detail** (`redesign/room_detail_screen.dart`).
  - **Budget detail transaction list** (`budgets/budget_detail_screen.dart`) —
    every row is the budget's category, so it renders that category's icon+color
    (falling back to the budget's own color when the category has none).
  - **Transaction detail sheet** (`transactions/transaction_detail_sheet.dart`) —
    header shows the category icon+color beside the title. Edit/delete are shown
    only when the viewer is the creator **and** the wallet is writable
    (`showTransactionDetail(..., canWrite:)`, default `true`); on a read-only
    (shared-to-me) wallet the sheet shows an info banner instead. Room detail
    threads `detail.wallet.canWrite`; the global-ledger/Aktivitas/calendar/
    budget-detail callers list only writable wallets so they keep the default.
  Surfaces without a `TransactionsState` in scope watch
  `categoryTagManagementControllerProvider` for the category catalog (overridable
  in hermetic tests).

### Avatar

- **Structure**: circular photo or initial letter. `SkyAvatar` (members,
  authorship) takes an optional `imageUrl`; the Pengaturan profile card and the
  Akun sheet preview use `CircleAvatar` with `foregroundImage`.
- **Source resolution**: always through `avatarImageProvider(url)`
  (`shared/presentation/widgets/avatar_image.dart`) — an uploaded avatar is a
  **base64 `data:image/...` URL** stored in the existing `avatar_url` field
  (→ memoized `MemoryImage`), legacy absolute http(s) URLs still resolve
  (→ `NetworkImage`), anything else falls back to the initial letter.
- **Upload flow**: Pengaturan → Akun → "Pilih foto" opens the system photo
  picker (`image_picker` behind `imagePickerProvider`, no storage permission),
  downscales to ≤256px (JPEG q80 platform-side, Dart re-downscale fallback via
  `encodeAvatarDataUrl`, ≤~120KB) and stores the data URL; "Hapus foto" clears
  it. There is no hand-typed URL field anymore.
- **Accessibility**: the photo is decorative — the surrounding row carries the
  name/email text.

### Selector Row

- **Structure**: label, selected value, trailing chevron.
- **Variants**: wallet, category, tags, date, date & time, note.
- **Spacing**: `space4` vertical padding.
- **States**: default, focused, error.
- **Accessibility**: selected values must be names, never raw IDs.

### Settings Row

- **Structure**: leading icon mark, title, short status/value, optional trailing chevron.
- **Variants**: route-backed action, disabled unavailable item.
- **Spacing**: minimum 64 height with `space2` vertical padding and `space3` icon/text gap.
- **States**: enabled rows use forest soft icon treatment; disabled rows use muted text and no chevron.
- **Accessibility**: disabled unsupported features remain readable but cannot mutate preferences.

### Settings Switch Row

- **Structure**: leading icon mark, title, status/value, trailing adaptive switch or busy indicator.
- **Variants**: device lock, future route-backed local toggles.
- **Spacing**: same rhythm as Settings Row for grouped-list consistency.
- **States**: off, on, disabled unsupported, saving.
- **Accessibility**: use switch rows only for behavior backed by an API route or safe local-device capability.

### Skeleton

- **Structure**: tonal shimmer block sized to the content it stands in for; compose several to mirror the loaded layout.
- **Variants**: block (`AffluenaSkeleton`), line (`.line`), circle (`.circle`).
- **Usage**: the standard loading state across every screen — never a centered spinner or "Loading…" text.
- **States**: animating (shimmer) and static (when reduced-motion is on).
- **Accessibility**: honors the platform reduce-motion setting (static tonal fill, no animation).
- **Motion**: a single calm left-to-right shimmer sweep; opacity/gradient only.

### Money Input

- **Structure**: text field with an `Rp` prefix that groups thousands (`Rp 1.234.567`) as the user types.
- **Usage**: every money amount field. Stores and reports an integer in minor units; users never read or type a bare unformatted integer. For balance adjustments an Increase/Decrease control supplies the sign.
- **Hints**: pass `hint:` as **bare id_ID-grouped digits** (`'50.000'`, `'10.000.000'`) — the widget hardcodes the `Rp ` prefix, so a `cth:` prefix would render "Rp cth: 50.000". A descriptive sentence hint (e.g. `'Saldo dompet saat ini'`) is allowed where a numeric example adds nothing.
- **States**: default, focused, disabled, error (validator).
- **Accessibility**: numeric keyboard; the grouped value is plain text.

### Form Field Hints

- **Rule**: every form text field carries an Indonesian `hintText` placeholder so an empty form teaches its own format. No bare labels without a hint.
- **Copy conventions**: free-text fields use a `cth:`-prefixed example (`'cth: Makan siang'`, `'cth: Bayar kos'`); name-like/category fields use a bare example (`'Makanan'`, `'Budi Santoso'`); emails use `'nama@email.com'` / `'email@contoh.com'`; numeric non-money fields show the expected shape (`'cth: 12'`, `'1-31'`); **MoneyInput hints are bare grouped digits** (see Money Input). Passwords describe the requirement (`'Minimal 8 karakter'`); persistent guidance stays in `helperText` — the hint disappears on typing.
- **Search fields** use `hintText` (never `labelText`) so they read as search boxes (`'Cari kategori'`).
- **Implementation**: plain-string hints keep `const InputDecoration`s const; drop `const` only when the hint is computed (e.g. tab-dependent examples).

### Date Picker Field

- **Structure**: a Selector Row-styled field (label, formatted value, chevron) that opens the native date picker on tap.
- **Usage**: date-only fields where time-of-day is irrelevant — debt/installment due dates, goal target dates, tracker dates, recurring schedules, and the transaction filter range. Replaces hand-typed `YYYY-MM-DD` / RFC3339 entry; machine date formats are never shown to the user.
- **States**: empty (placeholder), selected, disabled.
- **Accessibility**: exposes label + selected value via `Semantics`; the displayed date uses the `id_ID` locale.

### Date & Time Picker Field

- **Structure**: a Selector Row-styled field (label, formatted value, chevron) that opens the native date picker followed by the native time picker on tap.
- **Usage**: every transaction input — transaction create/edit, quick entry (manual save and template execute), split bill, and the wallet balance-adjustment (penyesuaian) sheet. Captures a full date **and** time-of-day; values may be backdated or future-dated. The picked local datetime is normalized to UTC and sent as a full RFC3339 timestamp (`transaction_at`); machine date formats are never shown to the user.
- **States**: empty (placeholder), selected, disabled.
- **Accessibility**: exposes label + selected value via `Semantics`; the displayed date and time use the `id_ID` locale.

### Status Banner

- **Structure**: rounded inline container with a leading status icon, message, and optional retry/dismiss action.
- **Variants**: error (coral), success (success), warning (amber), info (forest).
- **Usage**: action and load errors and confirmations. Errors read as errors — never a neutral `surfaceTintSoft` tint. Bottom sheets stay open on failure and surface the banner inline.
- **States**: static, with-retry, with-dismiss.
- **Accessibility**: message is body text at full ink contrast; the accent color is supportive, not the only signal.

### Status Badge

- **Structure**: compact pill colored by semantic meaning, not by the brand accent.
- **Variants**: success, warning, danger, neutral (plus a `forStatus()` mapper for backend status strings).
- **Usage**: lifecycle/status pills (active, paused, partial, paid_off, cancelled, joined, rejected, …). Active and Cancelled must look different.
- **Accessibility**: status is carried by the label text, not color alone.

### Confirmation Sheet (`skyConfirm`)

- **Structure**: the app-wide confirmation surface — a modal bottom sheet (rounded `radiusSheet` top + drag handle from the sheet theme) with a soft-tinted 48px leading icon tile, a w700 title, a muted 1.4-line-height message, then a **full-width `FilledButton` confirm** (key `sky-confirm-accept`) stacked over a **full-width `TextButton` cancel** (key `sky-confirm-cancel`). `useSafeArea`, content scrolls on short viewports.
- **Variants**: default (accent tile, question glyph, themed confirm button) and **danger** (`danger: true` — coral tile with a warning glyph and a coral confirm fill) for destructive actions: delete, cancel-a-record, revoke, sign-out. An optional `icon:` overrides the glyph (e.g. `delete_outline`).
- **Usage**: `skyConfirm(context, title:, message:, confirmLabel:, cancelLabel:, danger:, icon:)` → `Future<bool>`; dismissing the sheet counts as cancel. **Every two-action confirmation routes through it** — payments/runs (non-danger), deletes and cancels (danger). Never hand-roll an `AlertDialog` confirm; single-OK info dialogs and rich summary sheets (e.g. the split-bill recap) are not confirmations.
- **States**: default, danger.
- **Tokens**: colours via `context.sky.*` (the danger fill keeps the theme's foreground — never hardcoded white), spacing/radii via `AffluenaSpacing`/`AffluenaRadii`.
- **Accessibility**: the action semantics live in the button labels, not colour alone; the message is body text at muted contrast with the title carrying the question.

### Category Tree Picker

- **Structure**: bottom sheet with a header (title + a **search icon** that toggles a `Cari kategori` field + "Kelola kategori" gear), an optional "no category" row, and the 3-level category tree (parents with indented, collapsible children). Search is hidden behind the icon (not an always-on field) so it never crowds the list. The picker is **selection-only**: it neither reorders nor creates in place.
- **Appearance**: each category renders its user-chosen icon (semantic id → catalog in `item_appearance.dart`) inside a soft tinted chip of its chosen color; categories without an appearance keep the minimal row so lists stay calm. The same icon+color follows the category onto transaction tiles, budget rows, and the master Kategori screen.
- **Order**: rows follow the user's arranged order (API `position`). Reordering happens only on the master Kategori screen, where each row has a visible `Icons.drag_indicator` handle **on the left** (immediate drag) that rearranges a category among its siblings and persists the flattened id list (optimistic, reverted with a snackbar on failure).
- **Manage (CRUD)**: the header gear (`category-picker-manage-button`) pushes `CategoryTagManagementScreen` for all create/edit/delete + reorder; `onMutated:` refreshes the caller on return. The master screen's add affordance is a plain **`Icons.add`** button. Its create/edit form shows the expense/income toggle **only on create** — a category's type is fixed once it exists (edit changes name, icon, color, parent only), and the name field has no prefix icon.
- **States**: searching (flat pruned results).
- **Accessibility**: selection is marked with a check icon and `Semantics(selected:)`, never color alone.

### Item Appearance (icon & color)

- **Palette**: the shared **24-swatch** `kItemColorPalette` (`#RRGGBB`, stored as-is on the API) with a leading "no color" option; used by wallets, budgets, goals, trackers, recurring rules, and categories via `ItemColorPickerRow` (keys `<entity>-color-<hex>`, horizontally scrollable). The first 10 swatches are the original set (never reordered/removed so existing data maps); new swatches are only appended and every swatch stays dark enough for white text/icons on a solid card. Keep identical to the web catalog.
- **Solid colored cards**: an item with a valid chosen color renders its card **solid** in that color — on Beranda's dashboard grid *and* on the domain list screens (Dompet, Anggaran, Tabungan, Cicilan/Langganan, Berulang). Treatment: bg + border = the color; white title/value; white70 secondary text; white icon on a white-20% tile (`ItemOnColorIconTile`); white progress fill on a white-25% track; status pills switch to the `StatusBadge(onColor: true)` white-on-white-20% variant. Semantic danger still wins: an over-budget progress fill stays coral. The income-green recurring amount yields to white. Items without a color (or with an unparseable legacy value) keep their default theming, the color only accenting the icon tile.
- **Category icons**: `kCategoryIconCatalog` maps ~40 semantic ids (food, transport, home, health, salary, travel, savings, coffee, fuel, bills, beauty, tools, bonus, …) to Material glyphs; `CategoryIconPickerGrid` renders the picker as a wrapping grid (keys `category-icon-<id>`, selected cell fills with the chosen accent). Unknown/empty ids fall back to the income/expense trend glyph via `resolveCategoryIcon`. Ids are append-only — never rename or drop one (they persist server-side).
- **Entity icons**: `entityIconFor(id)` resolves any entity's stored icon id against the **union** of `kCategoryIconCatalog` + `kWalletIconCatalog` (both live in `item_appearance.dart`; the category catalog wins on an id clash, e.g. `investment`); `resolveEntityIcon(id, fallback)` keeps each surface's default glyph when the id is unset/unknown. Budgets prefer `budget.icon` → the category's icon → the pie glyph; wallets keep `resolveWalletIcon` (id → per-type default).
- **Rules**: never rename a catalog id and never persist `IconData` (semantic ids persist server-side); the icon catalogs and palette are client-owned and must stay in sync with the web app.

## 6. Motion & Interaction

### Timing

| Type | Duration | Easing | Usage |
|------|----------|--------|-------|
| Micro | 100-150ms | easeOut | Button press, toggle |
| Standard | 200-260ms | easeInOut | Tab switch, sheet open |
| Emphasis | 320-420ms | easeOutCubic | First-load card reveal |

### Rules

- Animate opacity and transform only.
- Navigation should feel calm and predictable.
- Reduced-motion mode should keep all flows usable without decorative animation.

## 7. Depth & Surface

### Strategy

Affluena uses mixed tonal shift and subtle borders. Shadows are minimal and reserved for bottom sheets/dialogs.

| Level | Value | Usage |
|-------|-------|-------|
| Resting | tonal shift + subtle border | Cards and list groups |
| Raised | soft shadow + elevated surface | Bottom sheets and dialogs |
| Selected | accent soft fill | Active chips, selected nav |

The UI should feel tactile, not glossy. Avoid glassmorphism, neon effects, and heavy shadows.

## 8. Screen guide (visual reference)

The full set of mockups lives in
[`design/affluena-design-guide.html`](design/affluena-design-guide.html) — 21
screens across 7 flows. Open it in any browser; it is self-contained, no build
step. **Colour caveat:** the mockups still render in the retired Sky & Denim
(denim-blue) colours — for layout, spacing, type, and flows they remain the
source of truth, but for colour the Tinta table in §2 wins.

1. **Onboarding & Auth** — onboarding (shared-wallet hero), Masuk (login), Daftar (register).
2. **Beranda** — the 6-section dashboard (Dompet → Anggaran → Tabungan → Cicilan → Langganan → Berulang).
3. **Detail — Dompet · Anggaran · Tabungan** — wallet detail (members + access), budget detail (progress + transactions), savings-goal detail ("Liburan Bali": progress + the **"Riwayat setoran"** deposit history — the backing goal wallet's transactions, rows = `TransactionActivityRow`, hidden when no wallet carries the goal's id). The **Dompet list hero** is a calm `Total saldo` over one row of compact soft-tinted stat chips (Dompet / Bersama / Pribadi — Bersama hidden at 0). List cards on the Anggaran/Tabungan/Cicilan & Langganan screens are **whole-card tappable** (InkWell ripple) into these details, same as Beranda's grid cards.
4. **Detail — Cicilan · Langganan · Berulang** — installment detail (schedule + **"Riwayat pembayaran"**), subscription detail (upcoming bills + **"Riwayat pembayaran"**, pause/pay), recurring detail ("Transfer ke Tabungan"). The payment-history rows come from `GET /…/:id/payments` (newest first): amount + date (+ note), each tapping through to the backing transaction's detail sheet; empty state "Belum ada pembayaran."
5. **Quick-add · Aktivitas · Wawasan** — the "Catat cepat" sheet (templates + keypad), the activity feed, the insights/charts screen. The Wawasan screen (`SkyInsightsView`) leads with a **"Ke mana perginya uangmu?"** category-breakdown card scoped by a **period selector** — chips for **Hari / Minggu / Bulan / Kuartal / Tahun / Semua** plus **Atur** (custom `showDateRangePicker` range) — with a prev/next pager (disabled from paging into the future; "Semua"/"Atur" don't page). Under it: a `SkySegmentedToggle` (**Pengeluaran** / **Pemasukan**) over a **ranked horizontal-bar list** — each row is the category's chosen icon (in its colour on a soft tile) + name + amount + a colour-proportion bar + %, with the selected type's total shown above. Both breakdowns are computed **client-side** from the range's transactions (the API has no income-distribution endpoint) via `categoryBreakdownProvider(DateRange)`, joined to the category catalog for icon/colour; uncategorized money falls into a neutral "Tanpa kategori" bucket. The client pages up to **5.000 transactions**; a range larger than that sets `CategoryBreakdown.truncated`, and the card shows a small amber notice ("Menampilkan 5.000 transaksi terbaru — total mungkin tidak lengkap") so the total isn't silently under-reported. **Each real category row is tappable** (a subtle ripple) → `SkyCategoryTransactionsScreen`, a `DrillInScaffold` list of that one category's transactions **scoped to the same period** (`categoryTransactionsInRangeProvider((categoryId, DateRange))` — the same widened-window / 5.000-cap fetch as the breakdown, but `categoryId`-filtered server-side and returned raw newest-first): header = the category name + the period label subtitle, body = the full range day-grouped into `TransactionActivityRow`s, each tapping through to the shared detail sheet. The "Tanpa kategori" bucket (no id) stays non-tappable. Below it sit the cashflow-trend and forecast cards (the old standalone "Ke mana uang pergi" expense-distribution card was removed as a duplicate of the breakdown).
6. **Pengaturan** — Lainnya (settings hub), Keamanan (password, device lock, active sessions), Kategori (category hierarchy). The **Laporan & Notifikasi** section opens REAL separate screens — `LaporanScreen` (reports, keeps its own report-kind chips), `EksporScreen` (CSV exports), `AuditLogScreen`, `PeringatanAktivitasScreen` (alerts + audit-trail activity stacked on one scroll), `AturanNotifikasiScreen` (rules + `DeviceNotificationsCard`) — the old single chip-tabbed InsightsScreen is retired (chips may only switch sub-views *within* one screen, never act as a cross-section router). The "Alat harian" card has no "Transaksi" row (the ledger is the Aktivitas tab).
7. **State & aksi** — empty, loading (skeleton), error, the confirmation sheet (`skyConfirm`, see §5 — the mockup still shows the retired centered modal), and a dark-mode sample.

When a screen's visual changes, update **both** the HTML guide and the relevant
spec section above so the two never drift.
