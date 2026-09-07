# Porteos Intelligence — Architecture Overview

Complete system design and technical architecture documentation.

---

## Table of Contents

1. [High-Level Architecture](#high-level-architecture)
2. [Design Pattern: MVVM](#design-pattern-mvvm)
3. [3-Pane App Shell](#3-pane-app-shell)
4. [Data Layer: SwiftData](#data-layer-swiftdata)
5. [Business Logic: Services](#business-logic-services)
6. [Calculation Engine](#calculation-engine)
7. [View Layer](#view-layer)
8. [Multi-Window System](#multi-window-system)
9. [Background Services](#background-services)
10. [External Integrations](#external-integrations)
11. [State Management](#state-management)
12. [File Organization](#file-organization)

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       Porteos Intelligence                       │
│                        (SwiftUI macOS App)                       │
└─────────────────────────────────────────────────────────────────┘
                                 │
                ┌────────────────┼────────────────┐
                │                │                │
                ▼                ▼                ▼
         ┌──────────┐     ┌──────────┐    ┌──────────┐
         │  Views   │────▶│ViewModels│───▶│  Models  │
         │ (SwiftUI)│     │(@Observe)│    │(SwiftData)│
         └──────────┘     └──────────┘    └──────────┘
                                 │
                                 ▼
                          ┌──────────┐
                          │ Services │
                          └──────────┘
                                 │
                ┌────────────────┼────────────────┐
                ▼                ▼                ▼
         ┌──────────┐     ┌──────────┐    ┌──────────┐
         │Calculators│    │ External  │    │Background│
         │  (Pure)   │    │  APIs     │    │ Services │
         └──────────┘     └──────────┘    └──────────┘
```

### Key Principles

1. **Strict MVVM:** Models hold data only, ViewModels orchestrate, Views render
2. **Pure Calculators:** All financial math in pure Swift structs (no side effects)
3. **Centralized Tokens:** All colors/spacing in `DesignTokens.swift`
4. **SwiftData Persistence:** No Core Data, no manual SQL
5. **Single Source of Truth:** State flows down, events flow up

---

## Design Pattern: MVVM

### Model Layer (`Models/`)

**Purpose:** SwiftData `@Model` classes for persistence only.

```swift
@Model
final class PropertyDeal {
    var propertyName: String
    var purchasePrice: Double
    var operatingExpenses: Double
    // ... 80+ raw input fields
    
    // NO business logic
    // NO calculated fields (those go in ViewModels)
    // ONLY user input and persisted data
}
```

**Critical Rule:** Models NEVER contain calculation logic. See [`DATA_MODEL_GUIDE.md`](DATA_MODEL_GUIDE.md) for schema details.

### ViewModel Layer (`ViewModels/`)

**Purpose:** `@Observable` classes that bridge Models and Views.

```swift
@Observable
final class PropertyDealViewModel {
    let deal: PropertyDeal
    
    // Computed metrics using Calculators
    var capRate: Double {
        RealEstateCalculator.capRate(
            noi: deal.grossPotentialIncome - deal.operatingExpenses,
            purchasePrice: deal.purchasePrice
        )
    }
    
    var porteosScore: PorteosScoreResult {
        PorteosScoreCalculator.calculate(deal: deal)
    }
}
```

**Key Responsibilities:**
- Instantiate Calculators with Model data
- Expose computed properties to Views
- Handle user interactions (button taps, form submissions)
- Coordinate with Services for side effects

### View Layer (`Views/`)

**Purpose:** SwiftUI Views that render UI, no business logic.

```swift
struct DealDetailView: View {
    let viewModel: PropertyDealViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Cap Rate: \(viewModel.capRate, specifier: "%.2f")%")
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(DesignTokens.textPrimary)
        }
    }
}
```

**Critical Rules:**
- NO `if capRate > 8.0 { ... }` logic in Views — use ViewModel computed properties
- NO hardcoded colors — use `DesignTokens` only
- NO business logic — Views are "dumb" displays

---

## 3-Pane App Shell

### Layout Structure

```
┌────────────────────────────────────────────────────────────────┐
│                     TopHeaderBar (40pt)                         │
├──────────┬────────────────────────────────────┬─────────────────┤
│          │                                    │                 │
│          │                                    │                 │
│   Nav    │          Center Content            │    Inspector    │
│  Pane    │         (Dashboard / Map)          │      Pane       │
│ (260pt)  │                                    │     (280pt)     │
│          │                                    │                 │
│          │                                    │                 │
├──────────┴────────────────────────────────────┴─────────────────┤
│                    Global Command Bar (32pt)                    │
└────────────────────────────────────────────────────────────────┘
```

### Components

**1. `AppShell.swift`** — Master layout coordinator
- Manages 3-pane split
- Routes profile selection
- Handles deal selection state
- Coordinates inspector mode

**2. `NavigationPane.swift`** (260pt fixed width)
- Deal list with search/filter
- Profile switcher (6 profiles)
- Pipeline tabs (ALL, VIABLE, REVIEW, etc.)
- Multi-window launch buttons

**3. Center Content** (flexible width)
- Dashboard views (per profile)
- Global Intelligence map
- Comparison grid

**4. `InspectorPane.swift`** (280pt fixed width)
- WEIGHTS tab: Score breakdowns
- AI VIBE tab: SWOT analysis + regenerate
- RESEARCH tab: Chat interface
- MEDIA tab: Image gallery

**5. `TopHeaderBar.swift`** (40pt height)
- Current deal name/location
- HTTP server status indicator
- Settings/notifications buttons

**6. `GlobalCommandBar.swift`** (32pt height)
- CLI-style input field (currently decorative)
- Keyboard shortcuts legend

---

## Data Layer: SwiftData

### Schema (6 Models)

| Model | Purpose | Key Relationships |
|-------|---------|------------------|
| **`PropertyDeal`** | Core deal entity | → `DealImage[]`, `DealScenario[]`, `ResearchMessage[]` |
| **`DealImage`** | Property photos | ← `PropertyDeal` |
| **`DealScenario`** | Alternative financing scenarios | ← `PropertyDeal` |
| **`ResearchMessage`** | AI chat history | ← `PropertyDeal` |
| **`EmailImportRecord`** | Dedup tracking for email imports | (standalone) |
| **`MarketTrend`** | Historical score snapshots | (standalone) |

### Persistence Strategy

**Location:** `~/Library/Containers/com.porteos.native.v2/Data/Library/Application Support/default.store`

**Migration:** Backup + reset on failure (see [`PorteosIntelligenceApp.swift:26-87`](PorteosIntelligence/PorteosIntelligenceApp.swift))
- On schema change: Attempts to migrate
- On failure: Backs up to `~/Documents/PorteosBackups/`
- Alerts user, creates fresh DB
- **No lightweight migrations yet** (future improvement)

**Critical:** Never store calculated fields. Cap rate, NOI, score, etc. are computed in ViewModels from raw data.

**See:** [`DATA_MODEL_GUIDE.md`](DATA_MODEL_GUIDE.md) for detailed schema and migration guide.

---

## Business Logic: Services

Services live in `Services/` and handle side effects (network, file I/O, external APIs).

### Core Services

| Service | Responsibility | Port/Protocol |
|---------|---------------|---------------|
| **`LLMAnalysisService`** | Multi-provider AI gateway (Ollama, OpenAI, Gemini) | HTTP (various) |
| **`DealIngestionServer`** | HTTP server for browser extension | `http://localhost:9000` |
| **`EmailMonitorService`** | IMAP polling for listing emails | IMAP/SSL |
| **`NewsAggregatorService`** | RSS feed fetching and caching | HTTP/RSS |
| **`GeocodingService`** | MapKit forward geocoding | Native MapKit |
| **`PDFReportGenerator`** | Render deals to PDF | Native PDFKit |
| **`DealHistoryManager`** | Snapshot/undo system | SwiftData |
| **`WindowManager`** | Multi-window coordination | Native AppKit |

### Service Pattern

```swift
final class ExampleService {
    static let shared = ExampleService()
    private init() {}  // Singleton
    
    func doWork() async throws -> Result {
        // 1. Validate inputs
        // 2. Call external API or perform I/O
        // 3. Transform response
        // 4. Return or throw
    }
}
```

**Usage in ViewModels:**
```swift
Task {
    do {
        let result = try await ExampleService.shared.doWork()
        self.data = result
    } catch {
        self.errorMessage = error.localizedDescription
    }
}
```

---

## Calculation Engine

### Calculator Pattern

**Location:** `Calculators/`  
**Pattern:** Pure Swift structs with static methods (no state, no side effects)

```swift
struct RealEstateCalculator {
    static func capRate(noi: Double, purchasePrice: Double) -> Double {
        guard purchasePrice > 0 else { return 0 }
        return (noi / purchasePrice) * 100
    }
    
    static func dscr(noi: Double, debtService: Double) -> Double {
        guard debtService > 0 else { return 0 }
        return noi / debtService
    }
}
```

### Calculator Modules

| Calculator | Metrics |
|------------|---------|
| **`RealEstateCalculator`** | Cap rate, yield, NOI, DSCR, LTV, cash-on-cash |
| **`HospitalityCalculator`** | RevPAR, ADR, GOP, profitability matrix |
| **`DesignCalculator`** | Space efficiency, biophilic score, wellness index |
| **`CircularEconomyCalculator`** | Material flow, carbon lifecycle, resource efficiency |
| **`PorteosScoreCalculator`** | 0-100 composite score across all profiles |

### Why Pure Functions?

1. **Testable:** Easy to unit test (no mocks, no state)
2. **Reusable:** Same calculator used in Views, ViewModels, PDF export, tests
3. **No Side Effects:** Given same inputs, always returns same output
4. **Fast:** No async/await, no network calls

**See:** [`PorteosIntelligence/02_DATA_METRICS_AND_LOGIC.md`](PorteosIntelligence/02_DATA_METRICS_AND_LOGIC.md) for formula documentation.

---

## View Layer

### View Hierarchy

```
PorteosIntelligenceApp (entry point)
└── WindowGroup
    └── AppShell
        ├── NavigationPane
        │   └── Deal list + profile switcher
        ├── Center Content (switches per profile)
        │   ├── CmdCenterView (⌘1)
        │   ├── RealEstateDashboardView (⌘2)
        │   ├── HospitalityDashboardView (⌘3)
        │   ├── DesignDashboardView (⌘4)
        │   ├── CircularEconomyDashboardView (⌘5)
        │   └── GlobalIntelligenceDashboardView (⌘6)
        └── InspectorPane
            ├── Weights tab
            ├── AI Vibe tab (AIVibePanel)
            ├── Research tab (ResearchChatView)
            └── Media tab (DealMediaGalleryView)
```

### Component Library

**Reusable Components** in `Views/Components/`:

| Component | Purpose |
|-----------|---------|
| **`TerminalBlock`** | Module container with CLI header |
| **`TerminalMetricRow`** | Label + value + sparkline slot |
| **`MetricGridCell`** | 4-column dashboard metric cell |
| **`PorteosScoreBlock`** | Hero 0-100 score display |
| **`TerminalSparkline`** | Trend microcharts |
| **`TerminalTagChip`** | Pill-shaped tags |
| **`TerminalButtonStyle`** | `[ ACTION ]` bracket buttons |
| **`TerminalAsciiGauge`** | Threshold bar charts |
| **`CompactDealInspector`** | Collapsible deal summary |
| **`AIVibePanel`** | SWOT analysis + regenerate |
| **`ResearchChatView`** | AI chat interface |

**Design Authority:** All components follow [`01_TERMINAL_DESIGN_SYSTEM.md`](01_TERMINAL_DESIGN_SYSTEM.md)

---

## Multi-Window System

### Architecture

```
Main Window (AppShell)
  └── All 6 profiles available

Profile Window 1 (RealEstateDashboardView)
  └── Independent state, synced deal selection

Profile Window 2 (HospitalityDashboardView)
  └── Independent state, synced deal selection
```

### Implementation

**1. `ProfileWindowValue`** — Codable struct identifying window type:
```swift
struct ProfileWindowValue: Codable, Hashable {
    let profileType: ProfileType
    let timestamp: Date
}
```

**2. WindowGroup for Profiles:**
```swift
WindowGroup("Profile", id: "profile", for: ProfileWindowValue.self) { $value in
    ProfileWindowView(windowValue: $value)
        .modelContainer(sharedModelContainer)
}
```

**3. Launch from NavigationPane:**
- Hover over profile name → `[ ↗ ]` button appears
- Click → Opens new window with that profile
- Deal selection syncs across all windows via `@AppStorage`

**4. State Sync:**
- Selected deal ID stored in `@AppStorage("selectedDealID")`
- All windows observe this key
- When any window changes selection, all update

**See:** `WindowManager.swift` and `ProfileWindowView.swift` for implementation details.

---

## Background Services

### DealIngestionServer

**Purpose:** HTTP server for browser extension imports  
**Port:** 9000  
**Lifecycle:** Starts on app launch, stops on quit

```swift
DealIngestionServer.shared.start()
// Listens on http://localhost:9000/ingest
// Accepts POST with JSON payload
// Creates PropertyDeal and saves to SwiftData
```

**Security:** Localhost-only, no external access.

### EmailMonitorService

**Purpose:** Poll IMAP inbox for property listing emails  
**Schedule:** Every 10 minutes (when configured)  
**Storage:** Credentials in Keychain (`IMAPCredentials`)

```swift
EmailMonitorService.shared.startMonitoring()
// Connects to IMAP server via curl
// Fetches unseen messages
// Parses listings, imports as deals
// Marks as read
```

**Parser:** `ListingEmailParser.swift` extracts structured data from common listing formats.

### NewsAggregatorService

**Purpose:** Fetch RSS feeds for Global Intelligence  
**Schedule:** Daily (on demand)  
**Cache:** 60-day window  
**Registry:** `MarketFeedRegistry.swift` (35 metros, 10 sectors)

```swift
await NewsAggregatorService.shared.fetchAllFeeds()
// Fetches RSS from configured feeds
// Caches articles in memory
// Filters by sector keywords
```

---

## External Integrations

### AI/LLM Providers

**Service:** `LLMAnalysisService.swift` (778 lines)

**Providers:**
1. **Ollama (local):** `http://localhost:11434/api/chat`
2. **OpenAI:** `https://api.openai.com/v1/chat/completions`
3. **Gemini:** `https://generativelanguage.googleapis.com/v1beta/models/...`

**Features:**
- Multi-provider switching via UserDefaults
- Token limits per provider (Ollama: 4096, Cloud: 3000)
- Streaming support for RESEARCH chat
- Error handling and fallbacks

**Credentials:** OpenAI/Gemini API keys stored in UserDefaults (Keychain migration planned); none needed for Ollama.

### MapKit Geocoding

**Service:** `GeocodingService.swift`  
**API:** `MKGeocodingRequest` (native macOS 14+)

**Flow:**
1. User saves deal with address + city + country
2. `GeocodingService.geocodeIfNeeded()` called
3. Forward geocode via MapKit
4. Lat/lon saved to `PropertyDeal.latitude` / `.longitude`
5. Deal appears on Global Intelligence map

**No API key required** — native Apple service.

### Browser Extension Protocol

**Extension:** Chrome Manifest V3 (`BrowserExtension/PorteosImporter/`)  
**Sites:** 12 sites (Zillow, Idealista, Casa SAPO, RE/MAX, etc.)

**Flow:**
1. Content script scrapes listing page
2. POST to `http://localhost:9000/ingest` with JSON:
```json
{
  "propertyName": "Modern Villa",
  "address": "123 Main St",
  "purchasePrice": 1500000,
  "locationCity": "Lisbon",
  ...
}
```
3. `DealIngestionServer` receives, validates, creates `PropertyDeal`
4. Extension shows success toast

**See:** [`EXTERNAL_SERVICES.md`](EXTERNAL_SERVICES.md) for setup guide.

---

## State Management

### SwiftUI State

**Local State (`@State`):**
- Sheet visibility (`.sheet(isPresented: $showSheet)`)
- Text field inputs
- Temporary UI state

**Shared State (`@AppStorage`):**
- Selected deal ID (multi-window sync)
- AI provider selection
- Unit system (metric/imperial)
- Display density (1×/2×)

**Environment (`@Environment`):**
- `\.modelContext` — SwiftData context
- `\.displayDensity` — Custom environment key for UI scaling

**Observable Objects (`@Observable`):**
- ViewModels (e.g., `PropertyDealViewModel`)
- Singletons (e.g., `WindowManager`)

### Data Flow

```
User taps button
    → View calls ViewModel method
        → ViewModel updates Model (via SwiftData)
            → SwiftData saves to disk
                → View observes Model change
                    → UI updates
```

**Key:** State flows DOWN, events flow UP. Views never directly mutate Models.

---

## File Organization

```
PorteosIntelligence/
├── PorteosIntelligenceApp.swift      # Entry point, ModelContainer setup
├── Models/                            # SwiftData @Model classes
│   ├── PropertyDeal.swift            # Core deal model (474 lines)
│   ├── DealScenario.swift
│   ├── DealImage.swift
│   ├── ResearchMessage.swift
│   └── ...
├── ViewModels/                        # @Observable ViewModels
│   └── PropertyDealViewModel.swift
├── Views/
│   ├── Shell/                         # App shell structure
│   │   ├── AppShell.swift            # Master layout
│   │   ├── NavigationPane.swift      # Left sidebar
│   │   ├── InspectorPane.swift       # Right sidebar
│   │   └── ...
│   ├── Profiles/                      # 6 dashboard views
│   │   ├── CmdCenterView.swift
│   │   ├── RealEstateDashboardView.swift
│   │   ├── HospitalityDashboardView.swift
│   │   └── ...
│   ├── Components/                    # Reusable UI
│   │   ├── TerminalBlock.swift
│   │   ├── AIVibePanel.swift         # (1,149 lines)
│   │   └── ...
│   ├── Sheets/                        # Modal flows
│   │   ├── FullDealEditSheet.swift   # (1,274 lines)
│   │   ├── SettingsView.swift
│   │   └── ...
│   └── GlobalIntelligence/            # GI-specific views
│       ├── GeoPortfolioMapView.swift
│       ├── MarketNewsFeedModule.swift
│       └── ...
├── Services/                          # Business logic
│   ├── LLMAnalysisService.swift      # (778 lines)
│   ├── AIAnalysisService.swift       # (989 lines)
│   ├── DealIngestionServer.swift
│   ├── EmailMonitorService.swift
│   ├── NewsAggregatorService.swift
│   └── ...
├── Calculators/                       # Pure Swift structs
│   ├── RealEstateCalculator.swift
│   ├── HospitalityCalculator.swift
│   ├── DesignCalculator.swift
│   ├── CircularEconomyCalculator.swift
│   └── PorteosScoreCalculator.swift
├── Data/                              # Static data
│   ├── MarketBenchmarks.swift        # 43 cities
│   ├── MarketFeedRegistry.swift      # RSS feeds
│   ├── DealPropertyTypes.swift
│   └── PorteosGlossary.swift
├── Utilities/                         # Helpers
│   ├── DesignTokens.swift            # Color/spacing tokens
│   ├── DashboardHelpers.swift
│   ├── DealExporter.swift
│   └── ...
└── Resources/
    ├── Fonts/                         # JetBrains Mono
    └── Assets.xcassets
```

**Total:** 142 Swift files, ~35,000 lines of code.

---

## Design System Integration

**Authority:** [`DesignTokens.swift`](PorteosIntelligence/Utilities/DesignTokens.swift)

**Key Principles:**
1. **Zero rounded corners:** `.clipShape(Rectangle())`
2. **JetBrains Mono exclusively:** `.font(.custom("JetBrains Mono", size: 13))`
3. **Monospaced digits:** `.monospacedDigit()` on all numbers
4. **8pt grid:** All spacing multiples of 8
5. **Semantic color only on threshold breach:** Red = bad, green = good, otherwise neutral

**Enforcement:** `.cursor/rules/project-rules.mdc` flags violations during AI-assisted coding.

**See:** [`01_TERMINAL_DESIGN_SYSTEM.md`](01_TERMINAL_DESIGN_SYSTEM.md) for complete design specification.

---

## Performance Considerations

### Lazy Loading

- **Deal list:** `LazyVStack` in `NavigationPane` (handles 1000+ deals)
- **Images:** `AsyncImage` with placeholder
- **News feeds:** Paginated, load on scroll

### Computed Properties

- Calculators are instant (pure math, no I/O)
- ViewModels cache expensive computations
- SwiftData queries use predicates to limit results

### Background Work

- Email monitoring: Async Task, not on main thread
- LLM requests: Async/await, can cancel
- News fetching: Detached Task, low priority

---

## Testing Architecture

**Unit Tests** (`PorteosIntelligenceTests/`):
- Calculator tests (pure functions, easy to test)
- Score algorithm validation
- Edge case handling

**UI Tests** (`PorteosIntelligenceUITests/`):
- Launch tests
- Basic navigation smoke tests

**Manual QA:**
- See [`BetaTesterGuide.txt`](BetaTesterGuide.txt) for test matrix
- Zero-defect quality gates: [`.cursor/rules/zero-defect-quality.mdc`](.cursor/rules/zero-defect-quality.mdc)

---

## Future Architectural Improvements

**From PUNCHLIST.md:**
1. **Lightweight SwiftData migrations** (avoid backup+reset)
2. **Break up large files** (`FullDealEditSheet` @ 1,274 lines)
3. **Command palette wiring** (currently decorative)
4. **Investor Score calculator** (specified but not built)
5. **Live market data** (replace static 2024-25 estimates)

---

## Summary

Porteos Intelligence is a **strict MVVM macOS app** built with:
- **SwiftUI** for native UI
- **SwiftData** for persistence
- **Pure calculators** for business logic
- **Service layer** for side effects
- **3-pane shell** with multi-window support
- **Background services** for ingestion, email, news

**Critical Rules:**
- Models = data only
- Calculators = pure functions
- ViewModels = orchestration
- Views = dumb displays
- No hardcoded colors (use DesignTokens)
- Zero rounded corners (terminal aesthetic)

**Next:** Read [`DATA_MODEL_GUIDE.md`](DATA_MODEL_GUIDE.md) to understand the SwiftData schema.
