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

Beranda is a single scrollable dashboard. A `Total saldo` hero (with a month delta) sits on top, followed by money-domain **sections** — each a titled header with a "Lihat semua" link over a **2-column card grid**; tapping a card opens that item's detail. The sections, in order:

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
    header shows the category icon+color beside the title.
  Surfaces without a `TransactionsState` in scope watch
  `categoryTagManagementControllerProvider` for the category catalog (overridable
  in hermetic tests).

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

### Parity Surface

- **Structure**: screen title, compact contextual summary card, and a grouped list of route-backed modules.
- **Variants**: wallet detail, sharing, category/tag, quick-entry templates, split bill, audit logs.
- **Spacing**: `space5` screen padding, `space6` major section breaks, `space3` row gaps.
- **States**: static route shell, later replaced by module-specific loading/empty/error states.
- **Accessibility**: rows use visible text labels and Material icons; parameter IDs are not shown as user-facing copy.

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
- **States**: default, focused, disabled, error (validator).
- **Accessibility**: numeric keyboard; the grouped value is plain text.

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

### Category Tree Picker

- **Structure**: bottom sheet with search field, optional "no category" row, the 3-level category tree (parents with indented, collapsible children), and a pinned "Tambah kategori" action.
- **Appearance**: each category renders its user-chosen icon (semantic id → catalog in `item_appearance.dart`) inside a soft tinted chip of its chosen color; categories without an appearance keep the minimal row so lists stay calm. The same icon+color follows the category onto transaction tiles, budget rows, and the master Kategori screen.
- **Order**: rows follow the user's arranged order (API `position`); long-press drag rearranges a category among its siblings and persists immediately (optimistic, reverted with a snackbar on failure). The master screen offers the same drag on the full hierarchy.
- **Inline add**: the pinned action opens a compact create form (name, type — preset from the calling context when unambiguous, icon, color); on success the new category is selected immediately.
- **States**: searching (flat pruned results, drag disabled), reordering, inline create (saving, inline error).
- **Accessibility**: selection is marked with a check icon and `Semantics(selected:)`, never color alone.

### Item Appearance (icon & color)

- **Palette**: the shared 10-swatch `kItemColorPalette` (`#RRGGBB`, stored as-is on the API) with a leading "no color" option; used by wallets, budgets, goals, trackers, recurring rules, and categories via `ItemColorPickerRow` (keys `<entity>-color-<hex>`).
- **Solid colored cards**: an item with a valid chosen color renders its card **solid** in that color — on Beranda's dashboard grid *and* on the domain list screens (Dompet, Anggaran, Tabungan, Cicilan/Langganan, Berulang). Treatment: bg + border = the color; white title/value; white70 secondary text; white icon on a white-20% tile (`ItemOnColorIconTile`); white progress fill on a white-25% track; status pills switch to the `StatusBadge(onColor: true)` white-on-white-20% variant. Semantic danger still wins: an over-budget progress fill stays coral. The income-green recurring amount yields to white. Items without a color (or with an unparseable legacy value) keep their default theming, the color only accenting the icon tile.
- **Category icons**: `kCategoryIconCatalog` maps ~20 semantic ids (food, transport, home, health, salary, travel, savings, …) to Material glyphs; `CategoryIconPickerGrid` renders the picker (keys `category-icon-<id>`, selected cell fills with the chosen accent). Unknown/empty ids fall back to the income/expense trend glyph via `resolveCategoryIcon`.
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
3. **Detail — Dompet · Anggaran · Tabungan** — wallet detail (members + access), budget detail (progress + transactions), savings-goal detail ("Liburan Bali": progress + deposits).
4. **Detail — Cicilan · Langganan · Berulang** — installment detail (schedule), subscription detail (history, pause/pay), recurring detail ("Transfer ke Tabungan").
5. **Quick-add · Aktivitas · Wawasan** — the "Catat cepat" sheet (templates + keypad), the activity feed, the insights/charts screen. The Wawasan screen (`SkyInsightsView`) leads with a **"Ke mana uang bulan ini?"** category-breakdown card — a `SkySegmentedToggle` (**Pengeluaran** / **Pemasukan**) over a **ranked horizontal-bar list**: each row is the category's chosen icon (in its colour on a soft tile) + name + amount + a colour-proportion bar + %, with the selected type's total shown above. Both breakdowns are computed **client-side** from the current month's transactions (the API has no income-distribution endpoint), joined to the category catalog for icon/colour; uncategorized money falls into a neutral "Tanpa kategori" bucket. Below it sit the existing cashflow-trend, expense-distribution, and forecast cards.
6. **Pengaturan** — Lainnya (settings hub), Keamanan (password, device lock, active sessions), Kategori (category hierarchy).
7. **State & aksi** — empty, loading (skeleton), error, a confirmation modal, and a dark-mode sample.

When a screen's visual changes, update **both** the HTML guide and the relevant
spec section above so the two never drift.
