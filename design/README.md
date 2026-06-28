# Affluena Mobile — Design Guide

[`affluena-design-guide.html`](affluena-design-guide.html) is the **canonical
visual reference** for the Affluena Mobile UI: pixel-level mockups of every
screen in the **"Sky & Denim"** language, light mode plus a dark sample.

## View it

Open the file in any browser — it is **fully self-contained** (all CSS inlined,
no fonts/CDN/build step):

```bash
open design/affluena-design-guide.html        # macOS
```

## What it covers

21 screens across 7 flows:

| # | Flow | Screens |
|---|------|---------|
| 1 | Onboarding & Auth | Onboarding · Masuk (login) · Daftar (register) |
| 2 | Beranda | 6-section dashboard (Dompet → Anggaran → Tabungan → Cicilan → Langganan → Berulang) |
| 3 | Detail — Dompet · Anggaran · Tabungan | Wallet detail (members + access) · Budget detail (progress) · Savings-goal detail |
| 4 | Detail — Cicilan · Langganan · Berulang | Installment detail (schedule) · Subscription detail (history) · Recurring detail |
| 5 | Quick-add · Aktivitas · Wawasan | "Catat cepat" sheet (templates + keypad) · Activity feed · Insights |
| 6 | Pengaturan | Lainnya (settings hub) · Keamanan (password, lock, sessions) · Kategori (hierarchy) |
| 7 | State & aksi | Empty · Loading (skeleton) · Error · Confirmation modal · Dark-mode sample |

## How this relates to the rest

- **This HTML is the visual source of truth.** [`../DESIGN.md`](../DESIGN.md) is
  the *written* spec (palette tokens, IA, component rules). When a screen's look
  changes, update **both**.
- The palette is implemented in
  [`../lib/app/theme/sky_palette.dart`](../lib/app/theme/sky_palette.dart)
  (`SkyColors`, light + dark via `context.sky`).

## Build status

The guide is the **target** design. The live app already ships the Sky & Denim
palette, dark mode, and the icon-only floating pill nav. The main in-flight change is
**Beranda**, which the guide redesigns from wallet **"rooms"** into the
**6-section dashboard** above; the per-screen re-skin to fully match the guide is
in progress.
