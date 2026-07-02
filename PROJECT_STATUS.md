# Porteos Intelligence — Project Status

**Last updated:** 1 July 2026  
**Build status:** ✅ Compiling — zero errors  
**Branch:** `main`  
**Platform:** macOS (SwiftUI + SwiftData)  
**Design system:** V2.06_STABLE — shell migrated; dashboards/sheets pending (see `DESIGN_EXECUTION_PLAN.md`)

---

## What's Built

### Shell & Navigation
| Component | File | Status |
|---|---|---|
| 3-pane app shell | `AppShell.swift` | ✅ Complete |
| Navigation pane (280pt) | `NavigationPane.swift` | ✅ Complete |
| Top header bar | `TopHeaderBar.swift` | ✅ Complete |
| Global command bar | `GlobalCommandBar.swift` | ✅ Complete |
| Inspector pane | `InspectorPane.swift` | ✅ Complete |

### Data Model
| Component | File | Status |
|---|---|---|
| Core deal model | `PropertyDeal.swift` | ✅ Complete |
| Real estate calculator | `RealEstateCalculator.swift` | ✅ Complete |
| Hospitality calculator | `HospitalityCalculator.swift` | ✅ Complete |
| Design calculator | `DesignCalculator.swift` | ✅ Complete |
| Circular economy calculator | `CircularEconomyCalculator.swift` | ✅ Complete |
| Porteos score calculator | `PorteosScoreCalculator.swift` | ✅ Complete |
| Deal view model | `PropertyDealViewModel.swift` | ✅ Complete |

### Profile Dashboards
| Dashboard | File | Modules | Status |
|---|---|---|---|
| Command Center | `CmdCenterView.swift` | Portfolio summary, profile distribution, recent activity | ✅ Complete |
| Real Estate | `RealEstateDashboardView.swift` | Revenue, OpEx audit, profitability, leverage, returns | ✅ Complete |
| Hospitality | `HospitalityDashboardView.swift` | Operational stats, profitability matrix, distribution log | ✅ Complete |
| Design | `DesignDashboardView.swift` | Space efficiency, wellness, biophilic elements, adaptability | ✅ Complete |
| Circular Economy | `CircularEconomyDashboardView.swift` | Material flow, carbon lifecycle, resource efficiency | ✅ Complete |

### Reusable Components
| Component | File | Notes |
|---|---|---|
| Terminal block | `TerminalBlock.swift` | CLI-style module wrapper |
| Terminal metric row | `TerminalMetricRow.swift` | List layout — do not use in grids |
| Metric grid cell | `MetricGridCell.swift` | Grid layout — used in all dashboards |
| Terminal input field | `TerminalInputField.swift` | String + Double bindings, stable localText state |
| Circular score ring | `CircularScoreRing.swift` | Porteos score visualisation |
| Status badge | `StatusBadge.swift` | Deal status pill |

### Deal Management
| Feature | File | Status |
|---|---|---|
| Create deal | `NewDealSheet.swift` | ✅ Complete |
| Quick edit | `QuickAddDealSheet.swift` | ✅ Complete |
| Full tabbed editor | `FullDealEditSheet.swift` | ✅ Complete — 5 tabs (Base, RE, Hospitality, Design, Circular), focus-state tab nav |
| Import deals (CSV/JSON) | `ImportDealSheet.swift` | ✅ Complete |
| Bulk export | `BulkExportSheet.swift` + `DealExporter.swift` | ✅ Complete — CSV/JSON, 3 depth tiers, 4 scope filters, NSSavePanel |
| Pipeline filter tabs | `NavigationPane.swift` | ✅ Complete — ALL / PIPELINE / REVIEW / VIABLE / REJECTED / ACQUIRED |
| Bulk delete | `NavigationPane.swift` | ✅ Complete — confirmation dialog |

### Intelligence & Data
| Feature | File | Status |
|---|---|---|
| Market benchmarks | `MarketBenchmarks.swift` | ✅ Complete — 43 cities, alias lookup, auto-populates 5 fields on city submit |

---

## Architecture Decisions

- **Fonts:** JetBrains Mono exclusively. `.monospacedDigit()` on all numbers. No Inter.
- **Colors:** `DesignTokens.swift` is code authority — `canvasBase` `#0A0A0A`, `surfacePanel` `#111111`, `dividerStructural` `#333333`. Profile accents via `ProfileType.accentColor`.
- **Corners:** Zero rounded corners everywhere — `.clipShape(Rectangle())`.
- **Data flow:** `@Model` stores raw inputs only. Calculated metrics derived on-the-fly in calculators.
- **Calculation path:** All views use `RealEstateCalculator.calculateFull()`. Legacy `calculate()` is deprecated.
- **Input fields:** `TerminalInputField` uses internal `localText` state to prevent re-render reset.
- **Deal selection:** `AppShell` holds `selectedDeal: PropertyDeal?` directly.
- **Grids (target):** 4 fixed columns via `TerminalMetricGrid` — **not yet built**. Dashboards still use adaptive grid (migration in progress).

### Design System V2.06 (July 2026)

| Document | Purpose |
|---|---|
| `01_TERMINAL_DESIGN_SYSTEM.md` | Canonical spec (colors, layout, components) |
| `DESIGN_EXECUTION_PLAN.md` | Phased rollout Phases 0–9 |
| `DesignTokens.swift` | Runtime token source |
| `.cursor/rules/project-rules.mdc` | AI enforcement rules |

| Layer | Migration status |
|---|---|
| Shell (nav, header, command bar) | ~60% |
| Dashboards (5 profiles + comparison) | ❌ Legacy hex + adaptive grid |
| Sheets (12) | ❌ Legacy hex |
| Components (33) | ~11 migrated |

### Typography Scale (V2.06 target)
| Role | Size | Weight |
|---|---|---|
| Hero score | 48pt | bold |
| Primary metric values | 14pt | medium |
| Secondary / body | 12pt | regular |
| Labels / module titles | 10pt | bold, uppercase |
| CLI prompt / buttons | 11pt | regular / bold |

---

## Known Gaps / Next Sessions

### Design (Phase 0–9 — see `DESIGN_EXECUTION_PLAN.md`)
- [x] Phase 0 — Documentation sync (`01_TERMINAL_DESIGN_SYSTEM.md`, rules, redirect)
- [x] Phase 1 — `TerminalMetricGrid`, `TerminalMetricCell`, `TerminalKeyValueRow`
- [x] Phase 2 — `PorteosScoreBlock` alignment; wire `TerminalBlock.accentColor`
- [x] Phase 3 — Hospitality dashboard as reference implementation
- [ ] Phases 4–9 — Roll profiles, sheets, detached panes, token extermination, QA

### High priority (product)
- [ ] `PorteosScoreBlock` — weight sliders interactive in main view (editable only in `FullDealEditSheet` today)
- [ ] Inspector pane — inline quick-edit capability
- [ ] Email ingestion panel on `main` (PR #1 on feature branch)

### Medium priority
- [ ] Onboarding / empty state for first-launch
- [ ] Deal duplication ("Clone Deal")
- [ ] City autocomplete in `FullDealEditSheet`

### Low priority / Polish
- [ ] Keyboard shortcut map
- [ ] Animate metric value changes when switching deals

---

## File Map

```
PorteosIntelligence/
├── App/
│   └── PorteosIntelligenceApp.swift
├── Models/
│   └── PropertyDeal.swift
├── ViewModels/
│   └── PropertyDealViewModel.swift
├── Calculators/
│   ├── RealEstateCalculator.swift
│   ├── HospitalityCalculator.swift
│   ├── DesignCalculator.swift
│   ├── CircularEconomyCalculator.swift
│   └── PorteosScoreCalculator.swift
├── Data/
│   └── MarketBenchmarks.swift
├── Utilities/
│   └── DealExporter.swift
├── Views/
│   ├── Components/
│   │   ├── TerminalBlock.swift
│   │   ├── TerminalMetricRow.swift        ← list layout only
│   │   ├── MetricGridCell.swift           ← grid layout only
│   │   ├── TerminalInputField.swift
│   │   ├── CircularScoreRing.swift
│   │   ├── StatusBadge.swift
│   │   ├── EditDealSheet.swift
│   │   ├── NewDealSheet.swift
│   │   └── PorteosScoreBlock.swift
│   ├── Shell/
│   │   ├── AppShell.swift
│   │   ├── NavigationPane.swift
│   │   ├── InspectorPane.swift
│   │   ├── TopHeaderBar.swift
│   │   └── GlobalCommandBar.swift
│   ├── Profiles/
│   │   ├── CmdCenterView.swift
│   │   ├── RealEstateDashboardView.swift
│   │   ├── HospitalityDashboardView.swift
│   │   ├── DesignDashboardView.swift
│   │   └── CircularEconomyDashboardView.swift
│   └── Sheets/
│       ├── QuickAddDealSheet.swift
│       ├── FullDealEditSheet.swift
│       ├── ImportDealSheet.swift
│       └── BulkExportSheet.swift
├── 01_TERMINAL_DESIGN_SYSTEM.md
├── 02_DATA_METRICS_AND_LOGIC.md
├── DEVELOPMENT_RULES.md
└── PROJECT_STATUS.md   ← this file
```
