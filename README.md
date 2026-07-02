# Affluena Mobile

Flutter app for **Affluena**, a personal-finance app for Indonesian couples. The
UI is **fully Bahasa Indonesia**. It is a client of the Affluena API (the API is
the source of truth); money is handled as **integer minor units** (IDR).

## Stack

- Flutter 3.44.2 / Dart 3.12.2 (pinned via `.fvmrc`; use `fvm`)
- Riverpod (state) · go_router (navigation) · Dio (HTTP) · flutter_secure_storage (tokens)
- **Shorebird** code-push for over-the-air updates (see [`SHOREBIRD.md`](SHOREBIRD.md))

## Design — "Tinta"

The app uses the **Tinta** visual language: a monochrome ink UI (neutral
greys, near-black accent that flips to white in dark mode) where colour is
reserved for meaning — income green, danger coral, amber warnings, and
user-chosen wallet colours. The earlier warm-paper "Editorial Light" and
denim-blue "Sky & Denim" directions are **fully retired** (class/token names
keep their `Sky*` prefixes).

- Palette tokens: `lib/app/theme/sky_palette.dart` — `SkyColors` resolves
  **light + dark** by brightness; read via `context.sky` (e.g. `context.sky.accent`).
  Content ON an accent fill must use `context.sky.onAccent`, never `Colors.white`.
  The legacy theme + spacing/radii/typography tokens live in `lib/app/theme/affluena_theme.dart`.
- **Dark mode aware** (follows the system / the in-app theme controller).
- **Visual guide:** [`design/affluena-design-guide.html`](design/affluena-design-guide.html)
  — pixel-level mockups of all 21 screens (open in a browser; self-contained).
  [`DESIGN.md`](DESIGN.md) is the written spec (palette, IA, components). Keep both in sync.

## Information architecture — "Spaces / rooms"

The authenticated home is **`RedesignShell`** (route `/beranda`,
`lib/features/redesign/presentation/redesign_shell.dart`) — an **icon-only
floating pill** bottom-nav with three tabs plus a center quick-add FAB:

- **Beranda** — wallets as "rooms" (`RoomsHomeView`); tap a room → room detail; long-press → quick-add.
- **Aktivitas** — cross-wallet merged transaction feed (`ActivityFeedView`).
- **Wawasan** — insights: cashflow trend, expense distribution, forecast (`SkyInsightsView`).
- **Lainnya** (+ FAB) — "Lainnya" pushes **Pengaturan** (Settings), the hub for the
  remaining feature screens; the center FAB opens the quick-add capture sheet.

The old 5-tab bottom-nav shell (Home/Wallets/Add/Activity/More) was **deleted**
in the redesign; feature screens are now reached from the rooms home and from
Pengaturan, and remain plain top-level routes in `lib/app/router.dart`.

> **Design target:** the guide
> ([`design/affluena-design-guide.html`](design/affluena-design-guide.html))
> redesigns Beranda from wallet "rooms" into a **6-section dashboard** — Dompet ·
> Anggaran · Tabungan · Cicilan · Langganan · Berulang (2-column cards → detail).
> The rooms home above is the **current build**; the re-skin to the dashboard is
> in progress. See [`DESIGN.md` §1](DESIGN.md).

## Setup

```bash
fvm use 3.44.2
fvm flutter pub get
fvm flutter analyze
fvm flutter test            # widget + golden tests
```

Run against a custom API host (the API base URL is compile-time, default
`http://localhost:8080/api/v1`):

```bash
fvm flutter run --dart-define=AFFLUENA_API_BASE_URL=http://localhost:8080/api/v1
```

## Builds & releases

The **API base URL is a compile-time constant** (`AFFLUENA_API_BASE_URL` in
`lib/core/config/app_config.dart`). It MUST be baked in at build time or the app
falls back to `localhost` and shows *"Tidak bisa terhubung ke Affluena."*

| Goal | How |
|---|---|
| Plain release APK (sideload) | `scripts/build_apk.sh` (bakes the VPS URL via `--dart-define`) |
| **OTA patch** (Dart/UI change — no reinstall) | `scripts/shorebird_patch.sh` |
| New Shorebird release (version bump / native change) | `scripts/shorebird_release.sh` → install the produced APK once |

> Shorebird builds an Android App Bundle, whose post-build step needs
> `JAVA_HOME` (Android Studio's JBR) **and** Android `build-tools;35.0.0`
> installed, else the build fails with *"failed to strip debug symbols"*. The
> scripts set this up; details in [`SHOREBIRD.md`](SHOREBIRD.md). Plain
> `flutter build apk` is unaffected.

The built APK is distributed by dropping `Affluena.apk` at the repo root + an
iCloud folder. Install the **Shorebird-built** APK so it can receive OTA patches.

## Features

Reached from the rooms home and from **Lainnya → Pengaturan**:

- **Auth** — login, register, forgot/reset password, change password (revokes
  other sessions, persists the refreshed token pair), device lock (biometric).
- **Wallets & sharing** — share a wallet as **member** (read+write) or
  **viewer** (read-only). Viewer wallets are excluded from every "record into
  wallet" picker and their write actions are hidden.
- **Transactions** — create/edit with a date+time picker (local time normalized
  to UTC RFC3339 `transaction_at`; supports back/future-dating), split bill
  (deep-link reachable).
- **Quick entry** + templates (tree-aware 3-level category picker), **budgets**,
  **goals**, **debts**, **recurring**, **trackers** (installments/subscriptions),
  **categories** (3-level), **insights/reports**, **audit log**, **notifications/rules**.
- **Settings** — account, password, sessions, device lock, appearance/theme.

## Layout

```
lib/
  app/            router.dart, theme/ (sky_palette.dart, affluena_theme.dart)
  core/           config (app_config.dart), api client, formatters
  features/
    redesign/     RedesignShell + rooms/activity/insights/room-detail/quick-add (the live UI)
    <feature>/    data / application (Riverpod) / presentation per feature
scripts/          build_apk.sh, shorebird_release.sh, shorebird_patch.sh, shorebird_env.sh
test/             widget tests + goldens (test/goldens/)
```

## Conventions

- State: Riverpod (`NotifierProvider`, `FutureProvider.family`). Navigation: go_router.
- Imports are sorted (`directives_ordering` lint is on).
- Verify before committing: `fvm flutter analyze` + `fvm flutter test` + `fvm dart format`.
- Money: integer minor units; format with `MoneyFormatter.idr`. Dates: `id_ID` locale.
