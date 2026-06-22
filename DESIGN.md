# Affluena Mobile Design System

## 1. Atmosphere & Identity

Affluena Mobile feels like a calm personal finance companion for daily use: light, tactile, trustworthy, and quick to operate. The signature is editorial calm with practical finance clarity: warm paper-like surfaces, clear money hierarchy, muted forest accents, and touch-friendly rows that make recording small daily transactions feel low-friction.

## 2. Color

### Palette

| Role | Token | Light | Dark | Usage |
|------|-------|-------|------|-------|
| Surface/primary | `surfaceCanvas` | `#F7F2EA` | `#151411` | Main app background |
| Surface/secondary | `surfaceSoft` | `#FFFDF8` | `#211F1A` | Cards, sheets, panels |
| Surface/elevated | `surfaceElevated` | `#FFFFFF` | `#2A261F` | Raised controls and dialogs |
| Surface/tint | `surfaceTintSoft` | `#ECE4D8` | `#342F26` | Subtle grouped sections |
| Text/primary | `ink` | `#171714` | `#F8F3EA` | Headlines, body, money values |
| Text/secondary | `inkMuted` | `#6E665B` | `#BFB6AA` | Captions, hints, metadata |
| Border/subtle | `borderSubtle` | `#E5DCCC` | `#3B352C` | Dividers and card outlines |
| Accent/primary | `forest` | `#315C46` | `#7EB694` | Primary actions, selected tabs |
| Accent/soft | `forestSoft` | `#DCEADF` | `#20382D` | Selected surfaces and chips |
| Status/warning | `amber` | `#B4772E` | `#E0A552` | Budget warnings and due reminders |
| Status/error | `coral` | `#B55342` | `#F09483` | Destructive actions and errors |
| Status/success | `success` | `#49764F` | `#88C28F` | Positive cashflow and completed states |

### Rules

- The UI uses warm light surfaces by default; dark mode is supported structurally but not the initial brand default.
- Forest is reserved for primary actions, selected navigation, and meaningful positive emphasis.
- Amber and coral are status colors only. They are never decorative.
- No raw colors in widgets. Extend `AffluenaColors` first when a semantic color is needed.

## 3. Typography

### Scale

| Level | Size | Weight | Line Height | Tracking | Usage |
|-------|------|--------|-------------|----------|-------|
| Display | 34 | 700 | 1.12 | 0 | Hero money values |
| H1 | 28 | 700 | 1.18 | 0 | Screen titles |
| H2 | 22 | 700 | 1.25 | 0 | Section headers |
| H3 | 18 | 700 | 1.30 | 0 | Card titles |
| Body/lg | 16 | 500 | 1.45 | 0 | Prominent row text |
| Body | 14 | 400 | 1.45 | 0 | Default mobile body |
| Body/sm | 13 | 400 | 1.40 | 0 | Secondary metadata |
| Caption | 12 | 600 | 1.35 | 0 | Labels, chips, nav text |

### Font Stack

- Primary: system UI stack via Flutter platform defaults.
- Numerals: tabular figures where money values appear.
- Mono: not used in the mobile UI baseline.

### Rules

- Body text must not drop below 12 and primary content should stay at 14 or above.
- Money values use strong weight, clear contrast, and enough breathing room.
- Avoid uppercase microcopy except short labels in chips.

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
- Bottom navigation: persistent, four destinations plus central add action.

### Rules

- No dense desktop tables on mobile. Lists become readable mobile rows/cards.
- Critical controls use touch-friendly height and clear labels.
- Major flows prioritize one primary action per screen.

## 5. Components

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

### Selector Row

- **Structure**: label, selected value, trailing chevron.
- **Variants**: wallet, category, tags, date, note.
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
