# Porteos Intelligence — Design Execution Plan V2.06

**Design Lead:** Cursor Agent (Design Systems)  
**Authority:** This plan + `01_TERMINAL_DESIGN_SYSTEM.md` + `DesignTokens.swift`  
**Date:** July 1, 2026  
**Status:** APPROVED FOR EXECUTION  
**Certainty:** Implementation-ready — no aesthetic ambiguity remains.

---

## 1. Design Lead Position

Porteos Intelligence is a **native macOS institutional terminal**, not a web dashboard, not a crypto fintech clone, and not generic AI UI.

**What we are building:**
- Hermetic: one continuous data plate, zero visual leakage between regions
- Technical: JetBrains Mono, tabular numbers, bracket actions, numbered modules
- Balanced: fixed grids, aligned value columns, reserved sparkline slots
- Native: SwiftUI views styled as terminal — no NSTextView, no card shadows, no pills

**What we reject:**
- Rounded cards, glass blur, gradient heroes, sans-serif body text
- Adaptive metric grids that reflow into ragged column counts
- Semantic color on every metric (State vs Identity rule)
- Duplicate hex literals in view files (single token source)

**Current diagnosis:** Shell chrome is ~40% migrated. Workspace, sheets, and 22 components still use legacy V3.0 hex. This causes the “disproportionate mess” — not wrong product logic, wrong **layout contract**.

---

## 2. Non-Negotiable Layout Contract

Every screen must obey this geometry:

```
┌──────────────────────────────────────────────────────────────┐
│ TopHeaderBar (40pt) — wordmark + [ PROFILE // MODULE ]       │
├──────────┬───────────────────────────────────────┬─────────┤
│ Nav      │ Center workspace                      │ Inspector│
│ 260pt    │ Hero (48pt score)                     │ 280pt    │
│          │ CLI breadcrumb (36pt)                 │          │
│          │ TerminalBlock modules (16pt gutter)   │ tabs     │
│          │ 4-column metric grid (28pt cells)     │          │
├──────────┴───────────────────────────────────────┴─────────┤
│ GlobalCommandBar (32pt) — prompt + cursor + monitors         │
└──────────────────────────────────────────────────────────────┘
```

### Metric cell anatomy (all profiles)

```
┌─────────────────────────┐
│ LABEL (10pt dim, 2 lines max)
│ VALUE (14pt medium, tnum)
│ [sparkline slot 24pt]     ← always reserved
└─────────────────────────┘
Height: 56pt fixed (28×2 rhythm)
```

### Key-value row anatomy (sheets, PDF, inspector)

```
LABEL (40% width, dim)     VALUE (60%, right-aligned, primary)
Height: 28pt
```

---

## 3. Color Authority (Final)

| Role | Token | Hex | Usage |
|------|-------|-----|-------|
| Canvas | `canvasBase` | `#0A0A0A` | Window, center bg |
| Panel | `surfacePanel` | `#111111` | Nav, inspector, blocks |
| Elevated | `surfaceElevated` | `#1A1A1A` | Active nav row, sheets |
| Divider | `dividerStructural` | `#333333` | All 1px lines |
| Primary text | `textPrimary` | `#F8F9FA` | Values, headers |
| Secondary | `textSecondary` | `#94A3B8` | Standard copy |
| Dim | `textDim` | `#666666` | Labels, paths, prompts |
| Go | `statusGo` | `#27C93F` | Threshold pass, positive delta |
| Warn | `statusWarn` | `#FFBD2E` | Threshold caution |
| Critical | `statusCritical` | `#FF5F56` | Threshold fail |
| Nav chrome | `accentRust` | `#A34121` | Nav selection, system logo |

**Profile identity (from `ProfileType.accentColor` only):**
- Real Estate `#C25E30`, Hospitality `#14B8A6`, Design `#A855F7`, Circular `#3B82F6`, CmdCenter `#94A3B8`

**Deprecated — remove all references:**
- `#0F1115`, `#1A1D24`, `#23262E`, `#2E333F`, `#10B981`, `#F59E0B`, `#EF4444`, `#D4AF37`, `#64748B` as label dim

---

## 4. Per-Profile Dashboard Anatomy

### Command Center (`CmdCenterView`)
| Zone | Content |
|------|---------|
| Hero | Portfolio total + deal count (list rows, not grid) |
| 01 | Portfolio summary |
| 02 | Profile health bars |
| 03 | Profile distribution |
| 04 | Recent activity |
| 05 | System status (server, email) |
| Grid | List rows @ 28pt — no adaptive grid |

### Real Estate (`RealEstateDashboardView`)
| Zone | Content |
|------|---------|
| Hero | PorteosScoreBlock (above scroll, in AppShell) |
| CLI | `profile --real-estate --asset="…"` |
| 01 | Revenue (4-col grid) |
| 02 | OpEx audit |
| 03 | Profitability |
| 04 | Leverage (ASCII gauges on LTV, DSCR) |
| 05 | Returns |
| + | SensitivityAnalysisBlock, MarketTrendModule |

### Hospitality (`HospitalityDashboardView`)
| 01 | Operational stats (ADR, Occ, RevPAR, TRevPAR + sparklines) |
| 02 | Profitability matrix |
| 03 | Distribution log |
| + | HospitalitySensitivityBlock, MarketTrendModule |

### Design (`DesignDashboardView`)
| 01 | Space efficiency |
| 02 | Wellness |
| 03 | Biophilic |
| 04 | Adaptability |
| + | DesignSensitivityBlock, MarketTrendModule |

### Circular Economy (`CircularEconomyDashboardView`)
| 01 | Material flow |
| 02 | Carbon lifecycle |
| 03 | Resource efficiency |
| + | CircularSensitivityBlock, MarketTrendModule |

**All deal dashboards:** `LazyVGrid` with **4 fixed columns** (not adaptive 140–220).

---

## 5. Surface Inventory (Complete)

### Shell
| Surface | File | Migration |
|---------|------|-----------|
| App shell | `AppShell.swift` | ✅ Tokens |
| Navigation | `NavigationPane.swift` | ✅ Partial |
| Inspector | `InspectorPane.swift` | ✅ Partial |
| Detached panes | `DetachedPaneViews.swift` | ❌ Legacy hex |
| Top header | `TopHeaderBar.swift` | ✅ |
| Command bar | `GlobalCommandBar.swift` | ✅ |

### Overlays & popups
| Surface | File |
|---------|------|
| Command palette | `CommandPalette.swift` |
| Ingestion toast | `IngestionToast.swift` |
| Advanced filter | `AdvancedFilterPanel.swift` |
| Batch triage | `BatchTriageView.swift` |
| Comparison | `ComparisonView.swift` |

### Sheets (12)
TemplatePicker, Import, BulkExport, FullDealEdit, QuickAdd, QuickAddDeal, EmailSetup, ServerConfig, Settings, PDFReport, BatchTriage — **all need token + key-value row pass**

### Inspector tabs
| Tab | Component |
|-----|-----------|
| WEIGHTS | Sliders, Founder Lens, Tag Repository |
| AI VIBE | `AIVibePanel` — rule signals + LLM narrative |

### Machines / services UI
| Panel | File |
|-------|------|
| Deal ingestion server | `DealIngestionServerPanel`, `ServerConfigSheet` |
| Email ingestion | `EmailIngestionPanel`, `EmailSetupSheet` |
| PDF generator | `PDFReportSheet` |
| Scenario manager | `ScenarioManagerBlock` |

---

## 6. Component Registry (Canonical)

| Component | Purpose | Standard |
|-----------|---------|----------|
| `DesignTokens` | Colors, layout, fonts | Code authority |
| `TerminalMetricGrid` | 4-col fixed grid | ✅ |
| `TerminalMetricCell` | Unified grid cell | ✅ |
| `TerminalMetricRow` | List rows @ 28pt | ✅ |
| `TerminalKeyValueRow` | Sheet label/value | ✅ |
| `TerminalBlock` | Numbered module shell | ✅ accentColor wired |
| `PorteosScoreBlock` | Hero score | ✅ DesignTokens |
| `TerminalButtonStyle` | Bracket buttons | ✅ |
| `TerminalAsciiGauge` | Threshold bars | ✅ |
| `TerminalSparkline` | Time series | ✅ + delta color |
| `TerminalTagChip` | Border-only tags | ✅ |
| `AIVibePanel` | Vibe check | Token migration |
| Sensitivity blocks (×4) | Simulation tables | Consolidate base |

**Delete or integrate:** `ModuleHeader`, `CircularScoreRing` (preview-only dead code)

---

## 7. Execution Phases (Linear, Safe)

Each phase: build → visual check → commit. No calculator or model changes.

### Phase 0 — Documentation sync ✅
- This file + updated `01_TERMINAL_DESIGN_SYSTEM.md`
- Sync `.cursor/rules/project-rules.mdc`
- Deprecate duplicate in-app design doc

### Phase 1 — Layout primitives ✅
- `TerminalMetricGrid` + `TerminalMetricCell`
- `TerminalKeyValueRow`
- Extend `DesignTokens.Layout` (gridColumns4, cellHeight, blockPadding)

### Phase 2 — Hero + score alignment ✅
- `PorteosScoreBlock`: DesignTokens, semantic grade colors
- Wire `TerminalBlock.accentColor` → header command text (profile identity)

### Phase 3 — Reference dashboard (Hospitality) ✅
- Replace adaptive grid with `TerminalMetricGrid`
- Token sweep on `HospitalityDashboardView`
- `MetricGridCell` delegates to `TerminalMetricCell` for other dashboards

### Phase A — Type scale ✅
- `DesignTokens.TypeScale` locked: metric 11/16, hero 36/20, row 11/12, meta 10
- Shell gutter 12pt; grid gap 6pt; wide threshold 900pt

### Phase B — Padded metric cells ✅
- `TerminalMetricCell` v2: `surfaceElevated` + 1px border + 8pt padding @ 52pt min
- Label top / value+sparkline bottom; 2px left accent on warn/danger (no fill)
- All dashboards using `TerminalMetricGrid` inherit automatically

### Phase 6 — Sheets + modals (in progress)
- Shared: `TerminalSheetShell`, `TerminalSheetFooter`, `TerminalCategoryTabBar`, `TerminalSensitivityStyles`
- Migrated: ImportDealSheet, TemplatePickerSheet, BulkExportSheet, ServerConfigSheet, BatchTriageView
- Pending: FullDealEdit, EmailSetup, PDFReport, Settings, QuickAdd sheets

### Phase 8 — Sensitivity blocks ✅
- All 4 profile sensitivity blocks migrated to DesignTokens + TerminalSensitivityStyles

### Phase 7 — Detached + tearaway
- `DetachedPaneViews` token sweep
- Remove nested ScrollView duplication

### Phase 8 — Token extermination
- Grep `#0F1115|#1A1D24|#2E333F|#10B981` → zero in Views/
- Consolidate sensitivity blocks (~1600 lines → ~400 shared base)

### Phase 9 — QA matrix
- All 5 profiles × no-deal / with-deal / comparison
- All 12 sheets open/close
- Tearaway × 3 panes
- PDF export B&W + color semantic map update

---

## 8. Success Criteria (100.1%)

| Test | Pass condition |
|------|----------------|
| Visual seam | No color step between shell and center pane |
| Grid | 4 equal columns at all window widths ≥ 900px |
| Row rhythm | Data rows 28pt ± 0 across nav, metrics, tables |
| Hero | Score block left edge aligns with TerminalBlock below |
| Typography | Zero Inter, zero SF Pro in UI code |
| Color | Zero inline legacy hex in Views/ |
| Hermetic | No gap between nav/center/inspector except 1px divider |
| Native | macOS menus, sheets, keyboard shortcuts unchanged |
| Build | Zero compile errors every phase |

---

## 9. Wordmark Decision (Locked)

| Location | Text |
|----------|------|
| TopHeaderBar | `INSTITUTIONAL_V2.06_STABLE` (rust) |
| NavigationPane header | Same |
| Center workspace header | `[ PROFILE // MODULE ]` in profile accent |
| Footer | `porteos@system ~ %` + blinking cursor |

---

*End of execution plan. All agents and contributors must read this before UI work.*
