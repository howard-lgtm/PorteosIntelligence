# Porteos Intelligence - AI Development & Execution Rules
**CRITICAL:** Read this file before writing ANY code. These rules override general AI coding tendencies.

## 1. PROJECT ARCHITECTURE (Strict MVVM)
- **Models:** SwiftData `@Model` classes ONLY hold raw user input and persisted data. NEVER put calculation logic in the Model.
- **Calculators:** Create a dedicated `struct MetricCalculator` (or similar) in a `Calculators/` folder. All formulas from `02_DATA_METRICS_AND_LOGIC.md` live here. They take raw inputs and return calculated values.
- **ViewModels:** Use `@Observable` (Swift 5.9+). ViewModels hold the raw data, instantiate the Calculator, and expose the calculated metrics to the View.
- **Views:** SwiftUI Views are DUMB. They only display data passed from the ViewModel. No business logic, no math, no `if/else` for metric thresholds inside the View body (use computed properties in the ViewModel instead).

## 2. SWIFTUI UI IMPLEMENTATION (Native Terminal)
Translate all design spec concepts to native SwiftUI. DO NOT use CSS or UIKit hacks.
- `border-radius: 0` -> `.cornerRadius(0)` or `.clipShape(Rectangle())`
- `font-variant-numeric: tabular-nums` -> `.monospacedDigit()`
- `letter-spacing` -> `.tracking(0.08)`
- `text-transform: uppercase` -> `.textCase(.uppercase)`
- `box-shadow: none` -> `.shadow(radius: 0)`
- **Layout:** Use `Grid`, `HStack`, `VStack`, and `LazyVStack`. Do NOT use `GeometryReader` unless absolutely necessary for the 3-pane split.
- **Scrolling:** Use `ScrollView` with `LazyVStack` for long lists (like the Deal List or Metric Tables) to ensure 60fps performance.

## 3. SWIFTDATA & PERSISTENCE
- Keep `@Model` relationships simple. Use `@Relationship(deleteRule: .cascade)` where appropriate.
- Do NOT store calculated metrics (like Cap Rate, NOI, DSCR) in the database. Store only the raw inputs (Purchase Price, NOI, Loan Amount). Calculate the rest on the fly in the ViewModel. This prevents data drift.

## 4. FILE STRUCTURE
Organize the Xcode project strictly as follows:
```text
PorteosIntelligence/
── App/ (App entry point, ModelContainer setup)
├── Models/ (SwiftData @Model classes)
├── ViewModels/ (@Observable classes)
├── Views/
│   ├── Components/ (Reusable UI: TerminalMetricRow, CommandButton, etc.)
│   ├── Shell/ (AppShell, NavigationPane, InspectorPane)
│   ── Profiles/ (RealEstateView, HospitalityView, etc.)
├── Calculators/ (Pure Swift structs for metric math)
├── Utilities/ (Formatters, Extensions, OllamaClient)
└── Resources/ (Fonts, Assets)