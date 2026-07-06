# Porteos Intelligence — Project Status

**Last updated:** 6 July 2026  
**Build status:** ✅ Compiling — zero errors  
**Branch:** `main`  
**Platform:** macOS (SwiftUI + SwiftData)

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

- **Fonts:** JetBrains Mono exclusively at 100% of UI elements. No Inter.
- **Colors:** `#0F1115` shell-bg, `#1A1D24` shell-surface, `#2E333F` shell-border. Profile accents: Rust `#C25E30`, Teal `#14B8A6`, Purple `#A855F7`, Blue `#3B82F6`.
- **Corners:** Zero rounded corners everywhere — `.clipShape(Rectangle())`.
- **Data flow:** `@Model` stores raw inputs only. Calculated metrics (NOI, Cap Rate, DSCR, etc.) are derived on-the-fly in calculators. No stale data in the database.
- **Calculation path:** All views use `RealEstateCalculator.calculateFull()`. The legacy `calculate()` is `@available(*, deprecated)`.
- **Input fields:** `TerminalInputField` uses an internal `localText: String` state to prevent field-reset-to-zero on re-render (fixed critical bug).
- **Deal selection:** `AppShell` holds `selectedDeal: PropertyDeal?` directly. New deals use `pendingDealID` + `.onChange(of: deals)` to resolve after `@Query` fires.
- **Grids:** Dashboards use `LazyVGrid(GridItem(.adaptive(minimum: 160, maximum: 250)))` with `MetricGridCell`. `TerminalMetricRow` is list-only.

### Typography Scale (current)
| Role | Size | Weight |
|---|---|---|
| Headers / CLI commands / module titles | 13pt | medium / bold |
| Navigation links | 13pt | regular / bold |
| Metric labels | 13pt | regular |
| Metric values | 17pt | bold |
| Buttons | 13pt | regular / bold |
| Body text | 14pt | regular |
| Preview / secondary hints | 11pt | regular |

---

## Known Gaps / Next Sessions

### High priority
- [ ] **Startup splash** — Figma PNG sequence on app open (`SplashView` + `RootView` scaffold ready; awaiting frames in `Resources/Splash/`)
- [ ] `PorteosScoreBlock` — the score ring at the top of the center pane; currently renders but the 4 profile weight sliders are not yet interactive in the main view (editable only in `FullDealEditSheet`)
- [ ] Inspector pane — shows deal metadata but lacks inline quick-edit capability
- [ ] `TopHeaderBar` — profile name and deal name display; no active deal actions wired

### Medium priority
- [ ] Onboarding / empty state for first-launch (no deals, no tutorial)
- [ ] Deal duplication ("Clone Deal" context menu action)
- [ ] Export to PDF / print view
- [ ] City autocomplete in `FullDealEditSheet` using `MarketBenchmarks.suggestions(matching:)`

### Low priority / Polish
- [ ] Keyboard shortcut map (`⌘N` new deal, `⌘E` edit, `⌘⌫` delete)
- [ ] Animate metric value changes when switching deals
- [ ] `01_TERMINAL_DESIGN_SYSTEM.md` sync — keep in step with any further type scale changes

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
