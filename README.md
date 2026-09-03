# Porteos Intelligence

**Version:** 1.2 (Build 3)  
**Platform:** macOS 14.6+ (Universal: Intel & Apple Silicon)  
**Stack:** SwiftUI, SwiftData, MapKit  
**Lines of Code:** ~35,000 Swift

---

## Overview

Porteos Intelligence is a terminal-style investment intelligence platform for real estate and hospitality deal analysis. It combines financial calculators, AI-generated analysis, market benchmarks, and global intelligence feeds — all running locally on macOS with your own data.

**Key Features:**
- **Porteos Score (0-100):** Composite scoring system evaluating cap rates, yields, DSCR, LTV, cash-on-cash return, and regulatory factors
- **AI Analysis:** Multi-provider LLM support (Ollama, OpenAI, Gemini) for SWOT analysis and research chat
- **Multi-Window Profiles:** Independent windows with real-time state sync across 6 analysis profiles
- **Browser Extension:** One-click import from 12 major real estate sites (Zillow, Idealista, Casa SAPO, etc.)
- **Global Intelligence:** Market news feeds, geocoded portfolio mapping, sector-filtered intelligence
- **Market Benchmarks:** Preloaded financial data for 80+ cities across 13 countries

---

## Quick Start

### Prerequisites

- **macOS:** 14.6 Sonoma or later
- **Xcode:** 16.6 or later
- **Swift:** 5.9+ (bundled with Xcode)
- **JetBrains Mono:** Required for terminal aesthetic (download from [jetbrains.com/lp/mono](https://www.jetbrains.com/lp/mono/))

### Build & Run

```bash
# Clone repository
git clone https://github.com/howard-lgtm/PorteosIntelligence.git
cd PorteosIntelligence

# Open in Xcode
open PorteosIntelligence.xcodeproj

# Build and run (⌘R)
```

**For detailed setup instructions, see [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md)**

---

## Architecture

```
PorteosIntelligence/
├── Models/          # SwiftData @Model classes (PropertyDeal, DealScenario, etc.)
├── ViewModels/      # @Observable ViewModels (MVVM pattern)
├── Views/
│   ├── Shell/       # 3-pane app layout (Nav | Center | Inspector)
│   ├── Profiles/    # 6 dashboard views (RE, Hospitality, Design, Circular, GI, Command)
│   ├── Components/  # Reusable UI (TerminalBlock, metrics, charts)
│   └── Sheets/      # Modal flows (edit, import, settings, PDF export)
├── Services/        # Business logic (LLM, Email, News, Geocoding, PDF)
├── Calculators/     # Pure Swift structs for financial metrics
├── Data/            # Static data (market benchmarks, glossary, feed registry)
└── Utilities/       # Helpers, design tokens, formatters
```

**For architectural deep dive, see [ARCHITECTURE.md](ARCHITECTURE.md)**

---

## Key Documentation

| Document | Purpose |
|----------|---------|
| **[DEVELOPER_SETUP.md](DEVELOPER_SETUP.md)** | Environment setup, dependencies, first build |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | System design, MVVM pattern, service layer |
| **[DATA_MODEL_GUIDE.md](DATA_MODEL_GUIDE.md)** | SwiftData schema, migration strategy |
| **[EXTERNAL_SERVICES.md](EXTERNAL_SERVICES.md)** | LLM, IMAP, browser extension, RSS feeds |
| **[01_TERMINAL_DESIGN_SYSTEM.md](01_TERMINAL_DESIGN_SYSTEM.md)** | Complete UI design specification |
| **[DEVELOPMENT_RULES.md](PorteosIntelligence/DEVELOPMENT_RULES.md)** | Architecture and coding standards |
| **[BetaGuide.md](BetaGuide.md)** | Feature guide and user documentation |
| **[PROJECT_STATUS.md](PROJECT_STATUS.md)** | Current build state and recent changes |
| **[PUNCHLIST.md](PUNCHLIST.md)** | Known incomplete features |

---

## Development Workflow

### Making Changes

1. **Read the rules:** `.cursor/rules/` contains 5 MDC files covering design, quality, and prioritization
2. **Follow MVVM:** Models = data only, Calculators = pure functions, ViewModels = glue, Views = dumb display
3. **Use DesignTokens:** Never hardcode colors or spacing — use `DesignTokens.swift`
4. **Zero rounded corners:** Terminal aesthetic requires `.clipShape(Rectangle())`
5. **Test before commit:** Run unit tests (⌘U) and manual QA

### Git Workflow

```bash
# Feature branch from main
git checkout -b feature/your-feature-name

# Make changes, commit with descriptive messages
git add .
git commit -m "Add feature X to component Y"

# Push and create PR
git push -u origin feature/your-feature-name
```

### Running Tests

```bash
# Via Xcode: ⌘U
# Via command line:
xcodebuild test -scheme PorteosIntelligence -destination 'platform=macOS'
```

---

## External Services Setup

**AI/LLM (choose one):**
- **Ollama (local):** `brew install ollama && ollama pull qwen2.5:0.5b`
- **OpenAI:** API key required (Settings → AI Provider)
- **Gemini:** API key required (Settings → AI Provider)

**Browser Extension:**
- Load unpacked from `BrowserExtension/PorteosImporter/` in Chrome
- App must be running with HTTP server active (port 9000)

**Email Monitoring (optional):**
- IMAP credentials configured via Settings → Email

**See [EXTERNAL_SERVICES.md](EXTERNAL_SERVICES.md) for complete setup guide**

---

## Project Status

**Build Status:** ✅ Compiling (zero Swift warnings)  
**Current Version:** 1.2 (Build 3)  
**Latest Branch:** `main`  
**Last Updated:** September 3, 2026

**Recently Shipped:**
- RESEARCH chat tab with live streaming AI assistant
- Enhanced JSON import with OpEx and regulatory fields
- Sensitivity analysis for hospitality deals (4 scenarios)
- Multi-window profile system
- Global Intelligence dashboard with portfolio mapping

**In Progress:**
- Startup splash animation (Figma handoff)
- Figma UI redesign (Phases 1-7)
- Apple App Store submission

---

## Key Technologies

- **SwiftUI:** Native macOS UI framework
- **SwiftData:** Core Data successor for persistence
- **MapKit:** Geocoding and portfolio mapping
- **Combine:** Reactive state management
- **URLSession:** HTTP client for LLM APIs and RSS feeds
- **Security:** Keychain for API keys and IMAP credentials

---

## Design Philosophy

Porteos Intelligence uses a **terminal aesthetic** inspired by command-line interfaces:
- **JetBrains Mono** exclusively
- **Zero rounded corners** (pure rectangles)
- **8pt grid system**
- **Monospaced digits** on all numbers
- **CLI-style headers:** `porteos@system ~ % profile --hospitality`
- **Semantic color only on threshold breach** (red = bad, green = good, otherwise neutral)

Design authority: [`01_TERMINAL_DESIGN_SYSTEM.md`](01_TERMINAL_DESIGN_SYSTEM.md)

---

## Contributing

1. Read [`.cursor/rules/zero-defect-quality.mdc`](.cursor/rules/zero-defect-quality.mdc) before writing code
2. Follow the strict MVVM pattern outlined in [`DEVELOPMENT_RULES.md`](PorteosIntelligence/DEVELOPMENT_RULES.md)
3. Never hardcode colors — use [`DesignTokens.swift`](PorteosIntelligence/Utilities/DesignTokens.swift)
4. Add unit tests for new calculators
5. Update documentation when adding features
6. Schema changes require extra care (see [`DATA_MODEL_GUIDE.md`](DATA_MODEL_GUIDE.md))

---

## License

Proprietary. All rights reserved.

---

## Support

**Developer Contact:** info@htdstudio.net  
**Repository:** https://github.com/howard-lgtm/PorteosIntelligence  
**Issues:** GitHub Issues or direct email

---

## Acknowledgments

- **JetBrains Mono:** Font by JetBrains
- **Real Estate Metrics:** Industry-standard formulas for cap rate, DSCR, NOI, etc.
- **Market Data:** Static 2024-25 benchmark estimates (directional guidance)
