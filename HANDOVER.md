# MLX Bionic Handover — Porteos Intelligence

**Handover Date:** September 4, 2026  
**From:** Original Development Team  
**To:** MLX Bionic (Qwen3.8-27b 4-bit)  
**Project:** Porteos Intelligence — Real Estate Investment Intelligence Platform  

---

## Welcome to Porteos Intelligence

You are taking over development of a **35,000-line SwiftUI/SwiftData macOS app** for real estate investment analysis. This handover package contains everything you need to build, understand, and continue developing the application.

---

## 📦 What's in This Handover Package

### Phase 1: Critical Setup (Read First)
1. ✅ [README.md](README.md) — Project overview, quick start
2. ✅ [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) — Environment setup, first build
3. ✅ [ARCHITECTURE.md](ARCHITECTURE.md) — System design, MVVM pattern
4. ✅ [EXTERNAL_SERVICES.md](EXTERNAL_SERVICES.md) — AI, browser extension, email setup
5. ✅ [DATA_MODEL_GUIDE.md](DATA_MODEL_GUIDE.md) — SwiftData schema, relationships

### Phase 2: Knowledge Transfer (Read Second)
6. ✅ [SWIFTDATA_MIGRATION.md](SWIFTDATA_MIGRATION.md) — Safe schema modifications
7. ✅ [LLM_INTEGRATION.md](LLM_INTEGRATION.md) — Multi-provider AI architecture
8. ✅ [CALCULATOR_SYSTEM.md](CALCULATOR_SYSTEM.md) — Financial metrics, pure functions
9. ✅ [BROWSER_EXTENSION_GUIDE.md](BROWSER_EXTENSION_GUIDE.md) — Property scraping, 12 sites
10. ✅ [MULTI_WINDOW_SYSTEM.md](MULTI_WINDOW_SYSTEM.md) — Independent windows, state sync

### Existing Project Documentation
- 📋 [PROJECT_STATUS.md](PROJECT_STATUS.md) — Current state, recent changes
- 📋 [PUNCHLIST.md](PUNCHLIST.md) — Known incomplete features
- 📋 [BetaGuide.md](BetaGuide.md) — User-facing feature guide
- 📋 [BetaTesterGuide.txt](BetaTesterGuide.txt) — Testing checklist
- 📋 [01_TERMINAL_DESIGN_SYSTEM.md](01_TERMINAL_DESIGN_SYSTEM.md) — UI design spec
- 📋 [02_DATA_METRICS_AND_LOGIC.md](PorteosIntelligence/02_DATA_METRICS_AND_LOGIC.md) — Financial formulas
- 📋 [DEVELOPMENT_RULES.md](PorteosIntelligence/DEVELOPMENT_RULES.md) — Coding standards

### Cursor AI Rules (Enforce Quality)
- 🤖 [.cursor/rules/project-rules.mdc](.cursor/rules/project-rules.mdc) — Design compliance
- 🤖 [.cursor/rules/zero-defect-quality.mdc](.cursor/rules/zero-defect-quality.mdc) — Quality gates
- 🤖 [.cursor/rules/tiered-model-protocol.mdc](.cursor/rules/tiered-model-protocol.mdc) — Model selection (you can ignore this)

---

## 🚀 Quick Start (30 Minutes)

### Step 1: Run Setup Script (5 min)

```bash
cd /path/to/PorteosIntelligence
chmod +x setup.sh
./setup.sh
```

This checks:
- ✅ Xcode 16.6+ installed
- ✅ macOS 14.6+ version
- ✅ JetBrains Mono font installed
- ✅ Git repository status
- ✅ Build succeeds

### Step 2: Read Core Documentation (15 min)

**Critical reading order:**

1. **[README.md](README.md)** (5 min) — Understand what the app does
2. **[ARCHITECTURE.md](ARCHITECTURE.md)** (10 min) — Understand how it's built
   - Focus on: MVVM pattern, 3-pane shell, calculator pattern

### Step 3: Build and Run (10 min)

```bash
# Open in Xcode
open PorteosIntelligence.xcodeproj

# Build (⌘B)
# Run (⌘R)

# Expected: App launches, shows empty deal list
# Action: Click [ ./NEW_DEAL ] and create test property
```

---

## 📚 Documentation Reading Guide

### For Your First Week

**Day 1: Setup & Overview**
- [ ] Run `setup.sh`
- [ ] Read [README.md](README.md)
- [ ] Read [ARCHITECTURE.md](ARCHITECTURE.md)
- [ ] Build and run app successfully
- [ ] Create a test deal manually

**Day 2: Data Layer**
- [ ] Read [DATA_MODEL_GUIDE.md](DATA_MODEL_GUIDE.md)
- [ ] Understand PropertyDeal model (474 lines, 85+ properties)
- [ ] Read [SWIFTDATA_MIGRATION.md](SWIFTDATA_MIGRATION.md)
- [ ] Practice: Add a simple optional field to PropertyDeal

**Day 3: Business Logic**
- [ ] Read [CALCULATOR_SYSTEM.md](CALCULATOR_SYSTEM.md)
- [ ] Understand pure function pattern
- [ ] Study RealEstateCalculator formulas
- [ ] Practice: Add a simple metric (e.g., price per sqft)

**Day 4: External Integrations**
- [ ] Read [EXTERNAL_SERVICES.md](EXTERNAL_SERVICES.md)
- [ ] Read [LLM_INTEGRATION.md](LLM_INTEGRATION.md)
- [ ] Set up Ollama locally (optional)
- [ ] Test AI Vibe feature

**Day 5: Browser Extension**
- [ ] Read [BROWSER_EXTENSION_GUIDE.md](BROWSER_EXTENSION_GUIDE.md)
- [ ] Install extension in Chrome
- [ ] Test import from Zillow or Idealista
- [ ] Study one scraper implementation

### When You Need It (Reference Material)

**Multi-Window System:**
- Read [MULTI_WINDOW_SYSTEM.md](MULTI_WINDOW_SYSTEM.md) when working on UI or state management

**Design System:**
- Read [01_TERMINAL_DESIGN_SYSTEM.md](01_TERMINAL_DESIGN_SYSTEM.md) when creating new UI components
- Reference [DesignTokens.swift](PorteosIntelligence/Utilities/DesignTokens.swift) for colors/spacing

**Financial Formulas:**
- Reference [02_DATA_METRICS_AND_LOGIC.md](PorteosIntelligence/02_DATA_METRICS_AND_LOGIC.md) when adding metrics

**Current Work:**
- Check [PUNCHLIST.md](PUNCHLIST.md) for incomplete features
- Check [PROJECT_STATUS.md](PROJECT_STATUS.md) for recent changes

---

## 🎯 Validation Tasks

**Before considering handover complete, you should be able to:**

### Task 1: Read & Build ✅
- [ ] Clone repository
- [ ] Build app in Xcode
- [ ] Run app and create a test deal
- [ ] Run unit tests (⌘U)

### Task 2: Add Simple Field ✅
- [ ] Add optional field `propertyTaxMonthly: Double?` to PropertyDeal
- [ ] Add input in FullDealEditSheet
- [ ] Build without errors
- [ ] Test that field persists

### Task 3: Add Simple Metric ✅
- [ ] Add `pricePerSqft()` to RealEstateCalculator
- [ ] Formula: `purchasePrice / totalArea`
- [ ] Add computed property in PropertyDealViewModel
- [ ] Display in dashboard
- [ ] Write unit test

### Task 4: Modify AI Prompt ✅
- [ ] Locate SWOT prompt in LLMAnalysisService
- [ ] Add instruction: "Focus on investment ROI"
- [ ] Test with Ollama (if set up) or OpenAI
- [ ] Verify prompt change reflected in output

### Task 5: Debug an Issue ✅
- [ ] Intentionally break something (comment out a guard)
- [ ] Build and observe crash
- [ ] Use Xcode debugger to find issue
- [ ] Fix and verify

---

## 🗂️ Codebase Navigation

### Key File Locations

```
PorteosIntelligence/
├── PorteosIntelligenceApp.swift          # Entry point, ModelContainer
├── Models/
│   └── PropertyDeal.swift                # Core model (474 lines, study this first)
├── ViewModels/
│   └── PropertyDealViewModel.swift       # MVVM bridge, calculated metrics
├── Views/
│   ├── Shell/
│   │   ├── AppShell.swift               # 3-pane layout
│   │   ├── NavigationPane.swift         # Left sidebar (618 lines)
│   │   └── InspectorPane.swift          # Right sidebar
│   ├── Profiles/
│   │   ├── RealEstateDashboardView.swift
│   │   └── HospitalityDashboardView.swift
│   ├── Components/
│   │   ├── AIVibePanel.swift           # SWOT analysis (1,149 lines)
│   │   └── ResearchChatView.swift       # AI chat
│   └── Sheets/
│       └── FullDealEditSheet.swift      # Main edit form (1,274 lines)
├── Services/
│   ├── LLMAnalysisService.swift         # AI gateway (778 lines)
│   ├── DealIngestionServer.swift        # HTTP server for browser extension
│   └── EmailMonitorService.swift        # IMAP email import
├── Calculators/
│   ├── RealEstateCalculator.swift      # Cap rate, NOI, DSCR
│   ├── HospitalityCalculator.swift     # RevPAR, ADR, GOP
│   └── PorteosScoreCalculator.swift    # 0-100 composite score
├── Data/
│   ├── MarketBenchmarks.swift           # 43 cities preloaded
│   └── DealPropertyTypes.swift          # Property type registry
└── Utilities/
    └── DesignTokens.swift               # Colors, spacing (NEVER hardcode colors)
```

### Large Files (Use Summaries First)

**Context Window Strategy for Qwen3.8-27b:**

These files are **too large to read in full** (>500 lines). Read my documentation first, then request specific sections:

- ❌ `FullDealEditSheet.swift` (1,274 lines) → Read [ARCHITECTURE.md](ARCHITECTURE.md) first
- ❌ `AIVibePanel.swift` (1,149 lines) → Read [LLM_INTEGRATION.md](LLM_INTEGRATION.md) first
- ❌ `AIAnalysisService.swift` (989 lines) → Read [LLM_INTEGRATION.md](LLM_INTEGRATION.md) first
- ❌ `NavigationPane.swift` (618 lines) → Read [ARCHITECTURE.md](ARCHITECTURE.md) first
- ❌ `PropertyDeal.swift` (474 lines) → Read [DATA_MODEL_GUIDE.md](DATA_MODEL_GUIDE.md) first
- ❌ `content.js` (1,487 lines) → Read [BROWSER_EXTENSION_GUIDE.md](BROWSER_EXTENSION_GUIDE.md) first

**Strategy:** Load documentation → Understand pattern → Request specific code sections as needed.

---

## ⚠️ Critical Warnings

### High-Risk Areas (Proceed with Caution)

1. **PropertyDeal Schema Changes**
   - ⚠️ Current: Backup + reset (data loss)
   - ✅ Always read [SWIFTDATA_MIGRATION.md](SWIFTDATA_MIGRATION.md) first
   - ✅ Test on copy of database
   - ✅ Add defaults to new fields

2. **Large File Modifications**
   - ⚠️ Files >500 lines risk context overflow
   - ✅ Make small, incremental changes
   - ✅ Test after each change
   - ✅ Use documentation to understand before editing

3. **Design System Violations**
   - ⚠️ Terminal aesthetic is strict (zero rounded corners, JetBrains Mono only)
   - ✅ Always use DesignTokens (never hardcode colors)
   - ✅ Cursor rules will flag violations
   - ✅ Review [01_TERMINAL_DESIGN_SYSTEM.md](01_TERMINAL_DESIGN_SYSTEM.md) when adding UI

4. **Calculator Purity**
   - ⚠️ Calculators MUST be pure functions (no side effects)
   - ✅ Never add async/await to calculators
   - ✅ Never access Models directly from calculators
   - ✅ Review [CALCULATOR_SYSTEM.md](CALCULATOR_SYSTEM.md) pattern

---

## 🤝 Support During Transition

### First 30 Days

**Original developer available for:**
- ✅ Answering questions (response: 24-48 hours)
- ✅ Code review on first 3-5 PRs
- ✅ Architecture clarifications
- ✅ Debugging complex issues

**Weekly sync calls:**
- Week 1-2: Check-in after setup and first task
- Week 3-4: Review progress, address blockers

### After 30 Days

**Long-term support:**
- Original developer available for critical escalations only
- You own the codebase
- Update documentation as you learn

---

## 📊 Project Statistics

**Codebase:**
- **Lines of Code:** ~35,000 Swift
- **Files:** 142 Swift files
- **Models:** 6 SwiftData models
- **Calculators:** 5 modules, 50+ metrics
- **Views:** 60+ SwiftUI views
- **Services:** 12 service classes
- **Tests:** 7 test files

**External Dependencies:**
- Zero package manager dependencies
- Native frameworks only (SwiftUI, SwiftData, MapKit)
- JetBrains Mono font (must install manually)

**Supported Features:**
- 6 profile dashboards
- Multi-window system
- AI-powered analysis (3 providers)
- Browser extension (12 sites)
- Email monitoring (IMAP)
- PDF export
- Market intelligence feeds

---

## 🎓 Learning Resources

### SwiftUI + SwiftData (If Needed)

**SwiftUI:**
- Apple Tutorials: https://developer.apple.com/tutorials/swiftui
- Focus on: `@State`, `@Binding`, `@Observable`

**SwiftData:**
- Apple Docs: https://developer.apple.com/documentation/swiftdata
- Focus on: `@Model`, `@Query`, `ModelContainer`

**MVVM Pattern:**
- This codebase is strict MVVM
- Read [ARCHITECTURE.md](ARCHITECTURE.md) for our specific implementation

### Real Estate Investment (Domain Knowledge)

**Key concepts explained in docs:**
- Cap Rate, NOI, DSCR → [CALCULATOR_SYSTEM.md](CALCULATOR_SYSTEM.md)
- RevPAR, ADR, GOP → [CALCULATOR_SYSTEM.md](CALCULATOR_SYSTEM.md)
- All formulas → [02_DATA_METRICS_AND_LOGIC.md](PorteosIntelligence/02_DATA_METRICS_AND_LOGIC.md)

---

## ✅ Handover Checklist

### Pre-Development
- [ ] Run `setup.sh` successfully
- [ ] Read Phase 1 docs (README, DEVELOPER_SETUP, ARCHITECTURE)
- [ ] Build and run app
- [ ] Create test deal manually
- [ ] Run unit tests (all pass)

### Week 1
- [ ] Read Phase 2 docs (Migration, LLM, Calculators, Extension, Multi-Window)
- [ ] Complete Validation Task 1 (Read & Build)
- [ ] Complete Validation Task 2 (Add Simple Field)
- [ ] Complete Validation Task 3 (Add Simple Metric)

### Week 2
- [ ] Set up external services (Ollama recommended)
- [ ] Install browser extension, test import
- [ ] Complete Validation Task 4 (Modify AI Prompt)
- [ ] Complete Validation Task 5 (Debug an Issue)

### Week 3
- [ ] Pick feature from [PUNCHLIST.md](PUNCHLIST.md)
- [ ] Implement independently
- [ ] Pass zero-defect quality gates
- [ ] Submit for code review

### Week 4
- [ ] Address code review feedback
- [ ] Merge first feature
- [ ] Handover declared successful ✅

---

## 🚦 Go/No-Go Criteria

**Handover is SUCCESSFUL when:**

✅ You can build the app from scratch  
✅ You understand the MVVM architecture  
✅ You can add a field to PropertyDeal safely  
✅ You can add a metric to a calculator  
✅ You can modify an AI prompt  
✅ You can debug issues using Xcode  
✅ You complete a feature independently  

**If all ✅ → You're ready to own the codebase.**

---

## 📞 Contact Information

**Original Developer:** info@htdstudio.net  
**Repository:** https://github.com/howard-lgtm/PorteosIntelligence  
**Issues:** GitHub Issues or direct email  

---

## 🎉 Welcome Aboard!

You now have everything needed to take over Porteos Intelligence development. This is a well-architected, thoroughly documented codebase following strict MVVM and pure function patterns.

**Start with:** `./setup.sh` → [README.md](README.md) → [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) → Build the app!

**Questions?** Reference the documentation first, then reach out if needed.

**Good luck!** 🚀

---

*Handover package created: September 4, 2026*  
*Documentation version: 1.0*  
*Total documentation: 10 guides, ~6,000 lines*
