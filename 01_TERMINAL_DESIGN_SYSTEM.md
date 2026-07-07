# Porteos Intelligence — Terminal Design System V2.06_STABLE

**Purpose:** Absolute source of truth for UI, layout, typography, and components.  
**Code authority:** `PorteosIntelligence/Utilities/DesignTokens.swift`  
**Execution plan:** `DESIGN_EXECUTION_PLAN.md` (phased rollout)  
**Platform:** macOS 14.0+ · SwiftUI  
**Last updated:** July 1, 2026

---

## 0. Design Philosophy — Institutional Terminal

Native macOS app styled as a high-end terminal emulator (iTerm2-class) with standard SwiftUI interaction models.

| Law | Rule |
|-----|------|
| Structural honesty | Zero-margin data plate; panels separated only by 1px dividers |
| Geometry | `cornerRadius: 0` everywhere |
| Typography | JetBrains Mono 100%; `.monospacedDigit()` on all numbers |
| Interaction | Bracket triggers `[ ACTION ]`; no pill buttons, no shadows |
| Density | 28pt data rows; maximum aligned information per square inch |
| Native | SwiftUI `VStack`/`HStack`/`Grid` — not NSTextView, not web cards |

### 0.1 State vs Identity (Critical)

1. **State semantics** — Green/Amber/Red ONLY on threshold breach or delta direction  
2. **Typographic hierarchy** — Weight + brightness draw the eye; not rainbow metrics  
3. **Profile identity** — Rust/Teal/Purple/Blue ONLY on section headers, CLI paths, score hero, slider fills  
4. **Cell highlight** — 2px left border + 5% tint on warning/danger rows  

### 0.2 Hermetic Balance (Reference Quality Bar)

Balanced UI = **fixed grid + typographic hierarchy + restrained palette**.  
See crypto/fintech references for grid discipline only — not rounded cards or sans-serif.

---

## 1. Color System

**Use `DesignTokens` in code. Do not hardcode hex in views.**

### 1.1 Shell (V2.06)

| Token | Hex | Usage |
|-------|-----|-------|
| `canvasBase` | `#0A0A0A` | Window, center workspace background |
| `surfacePanel` | `#111111` | Nav, inspector, module interiors |
| `surfaceElevated` | `#1A1A1A` | Active nav row, sheet bodies |
| `dividerStructural` | `#333333` | All 1px dividers and borders |

Legacy aliases (`shellBg`, `shellSurface`, `shellBorder`) map to the above — **deprecated for new code**.

### 1.2 Text

| Token | Hex | Usage |
|-------|-----|-------|
| `textPrimary` | `#F8F9FA` | Values, active paths, headers |
| `textSecondary` | `#94A3B8` | Standard copy, secondary metrics |
| `textDim` | `#666666` | Labels, prompts, inactive commands |

### 1.3 Semantic (Terminal Palette)

| Token | Hex | Usage |
|-------|-----|-------|
| `statusGo` | `#27C93F` | Optimal threshold, positive delta, approvals |
| `statusWarn` | `#FFBD2E` | Caution threshold, watchlist |
| `statusCritical` | `#FF5F56` | Fail threshold, reject, high risk |

**Deprecated:** `#10B981`, `#F59E0B`, `#EF4444` — migrate to terminal semantics above.

### 1.4 Chrome vs Profile

| Token | Hex | Usage |
|-------|-----|-------|
| `accentRust` | `#A34121` | Nav 2px selection bar, system wordmark |

**Profile accents (`ProfileType.accentColor`):**

| Profile | Hex |
|---------|-----|
| Command Center | `#94A3B8` |
| Real Estate | `#C25E30` |
| Hospitality | `#14B8A6` |
| Design | `#A855F7` |
| Circular Economy | `#3B82F6` |
| Pipeline (badges) | `#F59E0B` |

---

## 2. Typography (Phase A — locked in `DesignTokens.TypeScale`)

| Tier | Size | Weight | Usage |
|------|------|--------|-------|
| Hero score | 36pt | Bold | Porteos score |
| Hero grade | 20pt | Bold | Score letter |
| Metric value | 16pt | Semibold | Grid cell values |
| Metric label | 11pt | Medium | Grid cell labels |
| Row value | 12pt | Medium | List/table values |
| Row label | 11pt | Regular | List/table labels |
| Module cmd | 11pt | Medium | `01 // MODULE` |
| Meta | 10pt | Regular | LN:120, timestamps only |

```swift
DesignTokens.metricValueFont()   // 16pt semibold + tnum
DesignTokens.metricLabelFont()   // 11pt medium
DesignTokens.rowValueFont()      // 12pt medium
DesignTokens.heroScoreFont()     // 36pt bold
```

**Rule:** No hardcoded font sizes in views.

---

## 3. Layout System

### 3.1 App Shell

| Region | Width | Background |
|--------|-------|------------|
| Navigation | 260pt fixed | `surfacePanel` |
| Center | Flexible | `canvasBase` |
| Inspector | 280pt fixed | `surfacePanel` |
| Dividers | 1px | `dividerStructural` |

### 3.2 Row Heights (Fixed)

| Token | pt | Usage |
|-------|-----|-------|
| `rowHeightData` | 28 | Metric rows, list rows, table rows |
| `rowHeightButton` | 32 | Bracket buttons, command bar |
| `rowHeightHeader` | 36 | CLI breadcrumb, inspector section headers |
| `rowHeightPaneBar` | 40 | TopHeaderBar |

### 3.3 Spacing

| Token | pt | Usage |
|-------|-----|-------|
| Block gutter | 12 | ScrollView padding, pane insets |
| Block spacing | 6 | Between TerminalBlocks |
| Grid gap | 6 | Between metric inset cells |
| Cell padding | 8 | Inside bordered metric cells |

### 3.4 Metric Grid

- **2 columns default**; **4 columns** when center pane ≥ 900pt
- **Inset cell:** `surfaceElevated` + 1px border, min 52pt
- **Never** use `GridItem(.adaptive(minimum:maximum:))`

### 3.5 Key-Value Rows (Sheets, PDF, Inspector)

- Label column: 40% width, left-aligned, dim  
- Value column: 60% width, right-aligned, primary  
- Row height: 28pt  

---

## 4. Component Specifications

### 4.1 TerminalBlock

```
porteos@system ~ % 01 // MODULE_NAME    ← accentColor on command segment
───────────────────────────────────────
[ 4-col grid or list content ]
```

- Header height: 28pt  
- Content padding: 12pt (0 for full-bleed lists)  
- Background: inherits parent surface  

### 4.2 TerminalMetricRow (Lists)

- Height: 28pt  
- Layout: `[2px border?] [label] [spacer] [value]`  
- Warning/danger: 2px left border + 5% background tint  

### 4.3 TerminalMetricCell (Grids) — Phase B

```
┌─────────────────────────┐  surfaceElevated + 1px border
│ LABEL (11pt)            │  8pt padding
│ €144          [sparkline]│  min 52pt; 2px left accent if warn/danger
└─────────────────────────┘
```

### 4.4 PorteosScoreBlock (Hero)

```
[ 36pt score ]                    [ PORTEOS SCORE / 20pt grade ]
```

- 12pt horizontal inset; background `surfacePanel`
- 1px border: `dividerStructural`  

### 4.5 Buttons

**Primary filled:** `TerminalButtonStyle(color: .rust|.green|…)`  
**Semantic ribbon:** `TerminalButtonStyle(semantic: .approve|.watchlist|.reject)`  
**Secondary:** bordered, no fill, profile or rust text  

Format: `[ ACTION_NAME ]` — JetBrains Mono 11pt bold  

### 4.6 TerminalAsciiGauge vs TerminalSparkline

| Type | Use |
|------|-----|
| ASCII `[████░░░░]` | Static thresholds: LTV, DSCR, occupancy |
| Sparkline | Time series; color from `TerminalSparkline.color(forDelta:)` |

### 4.7 Tags

`TerminalTagChip`: `[tag_name]` — border only, no fill, `dividerStructural` stroke  

### 4.8 AIVibePanel

- Idle → Running (`[ ANALYZING_RULES... ]` → `[ GENERATING_NARRATIVE... ]`) → Result  
- Grade badge 48pt centered  
- Signals: prefix `+` `~` `!` with semantic color  
- LLM offline: amber `~` banner  

### 4.9 GlobalCommandBar

```
porteos@system ~ % [input________________] █    MAN_PAGES  SYS_STAT  KERNEL_LOG  LN:120
```

---

## 5. Per-Profile Module Map

See `DESIGN_EXECUTION_PLAN.md` §4 for full module numbering.

Each deal profile dashboard structure:

1. CLI header (36pt, profile accent command)  
2. `SystemLogBlock` (validation)  
3. Numbered `TerminalBlock` modules with 4-col grid  
4. Profile sensitivity block  
5. `MarketTrendModule`  

Command Center uses list rows instead of grid — same tokens and row heights.

---

## 6. Surface Checklist

| Category | Files |
|----------|-------|
| Shell | `AppShell`, `NavigationPane`, `InspectorPane`, `DetachedPaneViews` |
| Headers | `TopHeaderBar`, `GlobalCommandBar` |
| Dashboards | 5 profiles + `ComparisonView` |
| Components | 33 in `Views/Components/` |
| Sheets | 12 in `Views/Sheets/` |
| Overlays | `CommandPalette`, `IngestionToast`, `AdvancedFilterPanel` |

---

## 7. Migration Status (July 1, 2026)

| Layer | Status |
|-------|--------|
| `DesignTokens.swift` | ✅ Complete |
| Shell chrome | 🟡 ~60% |
| Dashboards | ❌ Legacy hex + adaptive grid |
| Sheets | ❌ Legacy hex |
| Components | 🟡 ~11/33 migrated |

**Next:** Phase 1 layout primitives → Hospitality reference dashboard.

---

## 8. Deprecated Values — Do Not Use

| Deprecated | Replacement |
|------------|-------------|
| `#0F1115` | `DesignTokens.canvasBase` |
| `#1A1D24` | `DesignTokens.surfacePanel` |
| `#2E333F` | `DesignTokens.dividerStructural` |
| `#10B981` / `#F59E0B` / `#EF4444` | `statusGo` / `statusWarn` / `statusCritical` |
| `#D4AF37` (Gold RE) | `#C25E30` profile rust |
| Inter font | JetBrains Mono |
| `GridItem(.adaptive(...))` | Fixed 4-column grid |
| SF Symbols in chrome | Bracket text or JetBrains glyphs |

---

*This document is canonical. In-app copy at `PorteosIntelligence/01_TERMINAL_DESIGN_SYSTEM.md` redirects here.*
