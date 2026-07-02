# Porteos Intelligence — Figma Import Package

Design tokens and component specs extracted from the live app (`PORTEOS_TERMINAL_v1.0.4`).

## Cursor execution (start here)

**`porteos.figma-execution-plan.json`** — single file for Cursor to read and execute the full Figma redesign. It includes phased tasks, acceptance criteria, design decisions, constraints, and references to all other files in this folder.

```
@design-system/figma/porteos.figma-execution-plan.json Execute Phase 0
```

## Files

| File | Purpose |
|------|---------|
| **`porteos.figma-execution-plan.json`** | **Cursor execution plan — phased tasks + acceptance criteria** |
| `porteos.tokens.json` | Colors, typography, spacing, layout — import via **Tokens Studio** |
| `porteos.components.json` | Component anatomy, variants, dimensions — reference while building |
| `porteos.screens.json` | Screen inventory, Figma page structure, redesign phases |
| `porteos.tokens.w3c.json` | W3C Design Tokens format — alternative import path |

## Quick Start (Tokens Studio — recommended)

1. Install [Tokens Studio for Figma](https://tokens.studio/) plugin
2. In Figma: **Plugins → Tokens Studio → Import**
3. Select `porteos.tokens.json`
4. Apply theme: **Porteos Dark**
5. **Sync styles** → creates Color + Typography variables in Figma

## Alternative: Figma Variables (manual)

If not using Tokens Studio, create variable collections from `porteos/global`:

**Collection: Porteos / Color**
- shell/bg `#0F1115`, shell/surface `#1A1D24`, shell/elevated `#23262E`, shell/border `#2E333F`
- text/primary `#F8F9FA`, text/secondary `#94A3B8`, text/tertiary `#64748B`
- semantic/success `#10B981`, semantic/warning `#F59E0B`, semantic/danger `#EF4444`, semantic/info `#3B82F6`

**Collection: Porteos / Profile**
- realEstate `#C25E30`, hospitality `#14B8A6`, design `#A855F7`, circular `#3B82F6`

## Fonts

Install before designing:
- **JetBrains Mono** (Regular 400, Medium 500, Bold 700) — [jetbrains.com/mono](https://www.jetbrains.com/mono/)
- **Inter** (optional — spec only, rarely used in current UI)

## Figma File Structure

Create pages as defined in `porteos.screens.json → figmaPageStructure`:

```
00 — Cover & Tokens     ← swatches, type scale, spacing grid
01 — Components       ← build library from porteos.components.json
02 — Shell & Navigation
03 — Dashboards       ← start with Real Estate (stress test)
04 — Inspector & Overlays
05 — Sheets & Modals
06 — Admin & Extension
```

## Key Dimensions (live code)

| Element | Size |
|---------|------|
| Window (design frame) | 1200 × 800 |
| Nav pane | 260px |
| Inspector pane | 280px |
| Header bar | 40px |
| Command bar | 32px |
| Row / input / primary button | 28px |
| Corner radius | 0 everywhere |

## Design Decisions Flagged

These differ between design doc v3.0 and live code — pick one direction in Figma:

| Token | Design doc | Live code |
|-------|-----------|-----------|
| RE accent | Gold `#D4AF37` | Rust `#C25E30` |
| Nav width | 220px | 260px |
| Inspector width | 320px | 280px |

Both RE accent values are in the token file under `profile.accent`.

## Redesign Order

See `porteos.screens.json → redesignPhases`. Build Real Estate dashboard first — it has the most modules and metric states.
