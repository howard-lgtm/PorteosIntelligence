# Porteos Intelligence — Figma Import Package

Design tokens and component specs for the UI look-and-feel overhaul.

## Figma file

**[Porteos Intelligence — UI Redesign](https://www.figma.com/design/7XdLK0I2aWj7KVkvhnJEyE/Porteos-Intelligence---UI-Redesign?node-id=4-7&t=0lfVUZC5FjHwcEHI-1)** — live design file (file ID `7XdLK0I2aWj7KVkvhnJEyE`).

**Phase 0 status:** Cursor deliverables complete (July 2026). See `PHASE-0-FIGMA-CHECKLIST.md` for your Figma steps.

## Cursor execution (start here)

**`porteos.figma-execution-plan.json`** — phased tasks + acceptance criteria.

```
@Design-system/Figma/porteos.figma-execution-plan.json Execute Phase 1
```

## Phase 0 — Your Figma steps

1. Read **`PHASE-0-FIGMA-CHECKLIST.md`**
2. Import **`porteos.tokens.json`** (v2.06 reconciled) via Tokens Studio
3. Create 7 pages + cover frame using **`phase-0-cover-spec.md`**

## Files

| File | Purpose |
|------|---------|
| **`porteos.figma-execution-plan.json`** | Cursor execution plan |
| **`porteos.tokens.json`** | **V2.06 reconciled** — Tokens Studio import |
| **`porteos.tokens.w3c.json`** | W3C format alternative |
| **`porteos.components.json`** | Component anatomy |
| **`porteos.screens.json`** | Screen inventory (27 frames) |
| **`phase-0-cover-spec.md`** | Cover page content for Figma page 00 |
| **`PHASE-0-FIGMA-CHECKLIST.md`** | Phase 0 acceptance checklist |
| `DESIGN.md` | Stitch design system reference |
| `porteos_v2.06_color_spec.md` | V2.06 color architecture |

## Quick Start (Tokens Studio)

1. Install [Tokens Studio for Figma](https://tokens.studio/)
2. **Plugins → Tokens Studio → Import** → `porteos.tokens.json`
3. Apply theme: **Porteos Dark**
4. **Sync styles**

## Canonical colors (V2.06 — post Phase 0)

| Token | Hex |
|-------|-----|
| canvasBase | `#0A0A0A` |
| surfacePanel | `#111111` |
| surfaceElevated | `#1A1A1A` |
| dividerStructural | `#333333` |
| statusGo | `#27C93F` |
| statusWarn | `#FFBD2E` |
| statusCritical | `#FF5F56` |

Legacy v1.0.4 colors (`#0F1115`, etc.) are in `porteos/legacy` token set — **disabled** in theme.

## Resolved decisions (defaults)

| Decision | Choice |
|----------|--------|
| RE accent | Rust `#C25E30` |
| Aesthetic | Hybrid (terminal data + institutional chrome) |
| Buttons | CLI `[ ACTION ]` |
| CLI headers | Keep |
| Density | Dense (28px rows) |
| Nav / Inspector | 260px / 280px |

## Figma page structure

```
00 — Cover & Tokens
01 — Components
02 — Shell & Navigation
03 — Dashboards
04 — Inspector & Overlays
05 — Sheets & Modals
06 — Admin & Extension
```

## Fonts

- **JetBrains Mono** (400, 500, 700) — required
- **Inter** — optional (AI prose only)

## Redesign order

Real Estate dashboard first (stress test) → then other profiles. See `porteos.screens.json`.
