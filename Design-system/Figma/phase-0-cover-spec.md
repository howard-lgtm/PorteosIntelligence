# Porteos Intelligence — Cover Page Spec
## Page: `00 — Cover & Tokens` · Frame: `Cover — Porteos Intelligence v2.06` · 1200 × 2400

Build this frame in Figma using imported token variables. Background: `canvasBase` (#0A0A0A).

---

## 1. Project brief

**Product:** Porteos Intelligence  
**Version:** PORTEOS_TERMINAL_v2.06 (redesign)  
**Platform:** macOS · SwiftUI + SwiftData  
**Scope:** Look-and-feel overhaul only — preserve all features and information architecture.

**North star:** Institutional terminal (iTerm2-class) with inset metric cells, CLI module headers, bracket actions, zero internal corner radius.

**Default frame:** 1200 × 800 px  
**Grid base:** 8 px  
**Font:** JetBrains Mono (400, 500, 700) — required

---

## 2. Resolved design decisions

*Defaults applied — change on cover if you decide otherwise before Phase 2.*

| ID | Decision | Chosen | Value |
|----|----------|--------|-------|
| re-accent | Real Estate profile accent | **Rust (live app)** | `#C25E30` |
| aesthetic-direction | Overall aesthetic | **Hybrid** | Terminal data + cleaner institutional chrome |
| button-format | Button copy | **CLI** | `[ ACTION ]` and `./script` |
| cli-headers | Module headers | **Keep** | `porteos@system ~ %` on every block |
| density | Information density | **Dense** | 28px data rows |
| nav-width | Navigation pane | **260px** | Live code |
| inspector-width | Inspector pane | **280px** | Live code |

**Note:** Gold `#D4AF37` retained as `profile.realEstateSpec` for optional use — not primary.

---

## 3. Color swatch grid

Lay out as labeled rectangles (80×48 each) + hex label below in `textDim` 10px.

### Shell (V2.06 canonical)

| Swatch label | Hex | Token |
|--------------|-----|-------|
| CANVAS_BASE | `#0A0A0A` | shell.canvasBase |
| SURFACE_PANEL | `#111111` | shell.surfacePanel |
| SURFACE_ELEVATED | `#1A1A1A` | shell.surfaceElevated |
| DIVIDER_STRUCTURAL | `#333333` | shell.dividerStructural |

### Text

| Swatch label | Hex | Token |
|--------------|-----|-------|
| TEXT_PRIMARY | `#F8F9FA` | text.primary |
| TEXT_SECONDARY | `#94A3B8` | text.secondary |
| TEXT_DIM | `#666666` | text.dim |

### Semantic (threshold only)

| Swatch label | Hex | Token |
|--------------|-----|-------|
| STATUS_GO | `#27C93F` | semantic.statusGo |
| STATUS_WARN | `#FFBD2E` | semantic.statusWarn |
| STATUS_CRITICAL | `#FF5F56` | semantic.statusCritical |

### Profile identity

| Swatch label | Hex | Token |
|--------------|-----|-------|
| CMD_CENTER | `#94A3B8` | profile.cmdCenter |
| REAL_ESTATE | `#C25E30` | profile.realEstate |
| REAL_ESTATE_SPEC | `#D4AF37` | profile.realEstateSpec |
| HOSPITALITY | `#14B8A6` | profile.hospitality |
| DESIGN | `#A855F7` | profile.design |
| CIRCULAR | `#3B82F6` | profile.circular |
| PIPELINE | `#F59E0B` | profile.pipeline |

### Deal status (5)

| Swatch label | Hex |
|--------------|-----|
| PIPELINE | `#64748B` |
| REVIEW | `#F59E0B` |
| VIABLE | `#27C93F` |
| REJECTED | `#FF5F56` |
| ACQUIRED | `#3B82F6` |

### Legacy (deprecated — do not use in new frames)

| Swatch label | Hex | Note |
|--------------|-----|------|
| LEGACY_BG | `#0F1115` | v1.0.4 export |
| LEGACY_SURFACE | `#1A1D24` | v1.0.4 export |
| LEGACY_BORDER | `#2E333F` | v1.0.4 export |

---

## 4. Type scale specimen

Font: JetBrains Mono. Show each on its own row with label left, sample right.

| Style token | Size | Weight | Sample text |
|-------------|------|--------|-------------|
| score-hero | 36px | Bold 700 | `87` |
| score-grade | 20px | Bold 700 | `A` |
| metric-value | 16px | Semibold 600 | `€125,000` |
| metric-label | 11px | Medium 500 | `NET OPERATING INCOME` |
| row-value | 12px | Medium 500 | `6.20%` |
| row-label | 11px | Regular 400 | `CAP RATE` |
| cli-prompt | 11px | Regular 400 | `porteos@system ~ %` |
| module-cmd | 11px | Medium 500 | `01 // CORE_FINANCIALS` |
| button-primary | 11px | Bold 700 | `[ EDIT DEAL DATA ]` |
| meta | 10px | Regular 400 | `LAST TOUCH · 2D AGO` |

**Rule:** All numbers use tabular lining figures.

---

## 5. Spacing scale

Show horizontal bars scaled to width:

| Token | px | Usage |
|-------|-----|-------|
| xs | 4 | Micro gaps |
| sm | 8 | Cell padding, tight gaps |
| md | 12 | Block gutter, module padding |
| lg | 16 | Section gaps |
| xl | 24 | Sheet padding |
| 2xl | 32 | Hero padding |

**Layout constants:**

| Element | Size |
|---------|------|
| Window (design frame) | 1200 × 800 |
| Nav pane | 260 |
| Inspector pane | 280 |
| Header bar | 40 |
| Command bar | 32 |
| Data row | 28 |
| Metric cell min height | 52 |
| Hero cell min height | 88 |
| Corner radius (internal) | 0 |

---

## 6. Constraints (do not violate in redesign)

**Must preserve:** 3-pane layout · 5 profiles · Porteos Score A–F · 5 deal statuses · all dashboard modules · Inspector WEIGHTS + AI VIBE · 12 sheet flows · compare · triage · filters · command palette

**Must not break:** State vs identity color rule · zero internal corner radius · JetBrains Mono on numbers · import-first nav hierarchy

**Color rule:** Green/amber/red **only** on threshold breach — never on normal metrics by profile.

---

## 7. Redesign order

1. Phase 1 — Component library (`01 — Components`)
2. Phase 2 — Shell (`02 — Shell & Navigation`)
3. Phase 3 — **Real Estate dashboard first** (stress test), then other profiles
4. Phases 4–6 — Inspector, sheets, admin

---

*Generated by Phase 0 execution · Design-system/Figma · July 2026*
