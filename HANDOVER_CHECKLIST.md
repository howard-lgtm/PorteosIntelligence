# MLX Bionic Handover Checklist

**Purpose:** Track your onboarding progress for Porteos Intelligence  
**Target:** Complete all items over 4 weeks to achieve full handover  
**Update this file:** Check items as you complete them

---

## Week 1: Environment & Foundation

### Day 1: Setup (Target: 2 hours)

- [x] Clone repository to local machine
- [x] Run `chmod +x setup.sh && ./setup.sh`
- [x] Fix any FAILED checks from setup script
- [x] Verify Xcode 16.6+ installed
- [x] Verify JetBrains Mono font installed
- [x] Open `PorteosIntelligence.xcodeproj` in Xcode
- [x] Build project successfully (⌘B)
- [x] Run project successfully (⌘R)
- [x] App launches and shows empty deal list
- [x] Run unit tests (⌘U) — all pass

**Deliverable:** Screenshot of running app + passing tests

---

### Day 2: Documentation (Target: 3 hours)

**Phase 1 Documentation:**

- [x] Read HANDOVER.md (30 min)
- [x] Read README.md (15 min)
- [x] Read DEVELOPER_SETUP.md (30 min)
- [x] Read ARCHITECTURE.md (45 min)
  - [x] Understand MVVM pattern
  - [x] Understand 3-pane shell
  - [x] Understand calculator pattern
- [x] Read EXTERNAL_SERVICES.md (30 min)
- [x] Read DATA_MODEL_GUIDE.md (30 min)
  - [x] Understand PropertyDeal model
  - [x] Understand 6 model relationships

**Deliverable:** One-paragraph summary of architecture in your own words — ✅ Completed, see Notes section (Session 4 entry)

---

### Day 3: Code Exploration (Target: 3 hours)

**Core Files to Study:**

- [x] `PorteosIntelligenceApp.swift` (entry point)
- [x] `Models/PropertyDeal.swift` (read sections, not full file)
  - [x] Lines 1-100 (properties)
  - [x] Lines 100-200 (more properties)
  - [x] Lines 400-474 (computed properties)
- [x] `Calculators/RealEstateCalculator.swift` (full file, ~200 lines)  *(actual: 349 lines, read in full)*
  - [x] Understand pure function pattern
  - [x] Understand cap rate formula
  - [x] Understand NOI formula
- [x] `ViewModels/PropertyDealViewModel.swift` (sections)  *(actual: 178 lines, read in full)*
  - [x] Understand @Observable pattern
  - [x] Understand calculated metrics
- [x] `Views/Shell/AppShell.swift` (structure only)
  - [x] Understand 3-pane layout
- [x] `Utilities/DesignTokens.swift` (full file)
  - [x] Understand color system
  - [x] Understand spacing system

**Deliverable:** Document 3 things you found interesting or confusing — ✅ Completed, see Notes section (Session 9 entry)

---

### Day 4: First Code Change (Target: 2 hours)

**Task: Add a simple field to PropertyDeal**

- [x] Read SWIFTDATA_MIGRATION.md (risk mitigation)  *(read in full — 764 lines, Session 11)*
- [x] Backup database: `~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/Library/Application Support/default.store`  *(real container is `com.porteos.native.v2` — checklist path carries a stale bundle ID; 174 MiB triple saved to `~/Documents/PorteosBackups/default-2026-09-05T17-06-16Z-day4-pre.*` via SQLite online backup while app running, then graceful quit)*
- [x] Add field: `var testField: String = "default"` to PropertyDeal  *(2 lines: marker comment + field, after `status`)*
- [x] Build project (⌘B)  *(incremental `xcodebuild build` — BUILD SUCCEEDED)*
- [x] Run project (⌘R)  *(launched built .app; **no reset** — in-place lightweight migration added `ZTESTFIELD`, backfilled all 10 existing deals with the default)*
- [x] Create new deal and verify field exists  *(probe deal via ingest `POST /api/deals` on :9000 — 11 rows, all with `testField == "default"`; original 10 Z_PKs untouched; required temporarily setting `serverAutoStartEnabled` — deleted again afterwards)*
- [x] Delete test field  *(probe row removed via sqlite3 while app stopped; field removed via `git restore` — 0 occurrences left; post-revert launch confirmed migration DROPPED the residual column — schema matches model exactly, 10 deals intact, no reset/backup)*
- [x] Build again to confirm no errors  *(BUILD SUCCEEDED; safe SwiftData add-field workflow validated)*

**Deliverable:** Git diff of your changes (even if reverted) — ✅ Saved: `~/.lmstudio/scratchpads/r/day4-propertydeal-testfield.diff` (2-line addition + marker comment; `PropertyDeal.swift` restored to `main` state)

---

### Day 5: First Metric (Target: 3 hours)

**Task: Add a simple calculated metric**

- [x] Read CALCULATOR_SYSTEM.md  *(read for Day 5 context — full deep-read is Week 2 Day 1)*
- [x] Add function to RealEstateCalculator:
  ```swift
  static func pricePerSqft(purchasePrice: Double, totalArea: Double) -> Double {
      guard totalArea > 0 else { return 0 }
      return purchasePrice / totalArea
  }
  ```
  *(bannered `// MARK: - Unit Price` section with doc comments; +14 lines)*
- [x] Add computed property to PropertyDealViewModel:
  ```swift
  var pricePerSqft: Double {
      RealEstateCalculator.pricePerSqft(
          purchasePrice: deal.purchasePrice,
          totalArea: deal.totalArea
      )
  }
  ```
  *(+9 lines, after `occupancyState`)*
- [x] Display in RealEstateDashboardView  *(TerminalMetricCell "PRICE / M²" — shows `—` when area is 0; +11 lines)*
- [x] Write unit test:
  ```swift
  func testPricePerSqft() {
      let result = RealEstateCalculator.pricePerSqft(
          purchasePrice: 500000,
          totalArea: 2000
      )
      XCTAssertEqual(result, 250.0, accuracy: 0.01)
  }
  ```
  *(new file `PorteosIntelligenceTests/RealEstateCalculatorTests.swift` — happy path 500_000/2_000 → 250.0 + zero-area guard → 0)*
- [x] Run test (⌘U) and verify it passes  ✅ **via CLI** — `xcodebuild` runs the full suite (52 tests, MLX-confirmed); IDE ⌘U still reports "0 of 0, all passed" → tracked as known Xcode 26 quirk, KNOWN_ISSUES.md #1 (v1.2)
- [x] Create test deal, verify metric displays correctly  ✅ user-verified in app: **€2,000/m²** on the real estate dashboard

**Deliverable:** Git commit with working metric + test — ✅ committed + pushed (3 source files + new test file + `.gitignore` `/build/` + docs updates)

---

**Week 1 Checkpoint:**

- [x] Environment fully configured
- [x] All Phase 1 docs read
- [x] Core files explored
- [x] First code change completed
- [x] First metric added with test
- [x] Confidence level: Can navigate codebase independently  *(user-confirmed: 5 days of solo builds, data probes, and code changes)*

---

## Week 2: Knowledge Transfer

### Day 1: Phase 2 Documentation (Target: 4 hours)

**Advanced Documentation:**

- [ ] Read SWIFTDATA_MIGRATION.md (45 min)
  - [ ] Understand backup + reset strategy
  - [ ] Understand safe vs unsafe changes
  - [ ] Understand testing strategy
- [ ] Read LLM_INTEGRATION.md (60 min)
  - [ ] Understand multi-provider architecture
  - [ ] Understand prompt patterns
  - [ ] Understand error handling
- [ ] Read CALCULATOR_SYSTEM.md (45 min)
  - [ ] Understand all 5 calculator modules
  - [ ] Understand key formulas
- [ ] Read BROWSER_EXTENSION_GUIDE.md (45 min)
  - [ ] Understand scraper pattern
  - [ ] Understand 12 supported sites
- [ ] Read MULTI_WINDOW_SYSTEM.md (45 min)
  - [ ] Understand @AppStorage sync
  - [ ] Understand WindowGroup pattern

**Deliverable:** Notes on each doc's most important concepts

---

### Day 2: External Services (Target: 3 hours)

**Optional but Recommended:**

- [ ] Install Ollama: https://ollama.com/download
- [ ] Pull model: `ollama pull llama3.2:latest`
- [ ] Start Ollama server: `ollama serve`
- [ ] Open app Settings → LLM Provider → Ollama
- [ ] Set URL: `http://localhost:11434`
- [ ] Set model: `llama3.2:latest`
- [ ] Test AI Vibe feature on a deal
- [ ] Verify SWOT analysis generates

**Alternative (if Ollama fails):**

- [ ] Use OpenAI instead
- [ ] Add API key in Settings
- [ ] Test AI Vibe with OpenAI

**Deliverable:** Screenshot of working AI Vibe panel

---

### Day 3: Browser Extension (Target: 2 hours)

**Install and Test:**

- [ ] Open Chrome: `chrome://extensions/`
- [ ] Enable "Developer mode" (top right)
- [ ] Click "Load unpacked"
- [ ] Select: `BrowserExtension/` folder
- [ ] Navigate to Zillow listing (USA)
- [ ] Click [ SEND TO PORTEOS ] button
- [ ] Verify deal appears in app
- [ ] Test with another site (Idealista Portugal)

**Study Scraper Code:**

- [ ] Open `BrowserExtension/content.js`
- [ ] Find `initZillow()` function (lines 200-300)
- [ ] Understand scraper pattern
- [ ] Find `extractZillowData()` function
- [ ] Understand data extraction utilities

**Deliverable:** Successfully import 2 properties from different sites

---

### Day 4: AI Prompt Modification (Target: 2 hours)

**Task: Customize SWOT prompt**

- [ ] Read LLM_INTEGRATION.md (refresh)
- [ ] Open `Services/LLMAnalysisService.swift`
- [ ] Find `generateSWOT()` function (line ~200)
- [ ] Find prompt template string
- [ ] Add custom instruction: "Focus on cash-on-cash return"
- [ ] Build and run app
- [ ] Generate SWOT on test deal
- [ ] Verify output reflects your change
- [ ] Revert change (or commit if improvement)

**Deliverable:** Git diff of prompt change + screenshot of result

---

### Day 5: Debugging Practice (Target: 2 hours)

**Task: Intentionally break something and fix it**

- [ ] Open `Calculators/RealEstateCalculator.swift`
- [ ] Find `capRate()` function
- [ ] Comment out guard statement (introduce crash)
- [ ] Build and run
- [ ] Create deal with zero purchase price
- [ ] Observe crash or error
- [ ] Enable Exception Breakpoint (⌘7 → Breakpoints → +)
- [ ] Reproduce crash with breakpoint
- [ ] Inspect variables in debugger
- [ ] Identify issue
- [ ] Uncomment guard
- [ ] Verify fix

**Deliverable:** Written explanation of debugging process

---

**Week 2 Checkpoint:**

- [ ] All Phase 2 docs read
- [ ] External services configured (at least one)
- [ ] Browser extension tested
- [ ] AI prompt modified
- [ ] Debugging skills validated
- [ ] Confidence level: Can make targeted changes independently

---

## Week 3: Independent Development

### Feature Selection

**Pick ONE feature from PUNCHLIST.md:**

- [ ] Review PUNCHLIST.md
- [ ] Select feature (recommend: Medium complexity)
- [ ] Document choice and reasoning
- [ ] Get approval from original developer (optional)

**Example features:**
- Add new property type
- Add new market benchmark city
- Add new calculator metric
- Enhance dashboard view
- Add email parsing rule

---

### Planning (Target: 2 hours)

- [ ] Read relevant documentation for your feature
- [ ] Identify files that need changes
- [ ] List affected components:
  - [ ] Models?
  - [ ] Calculators?
  - [ ] Services?
  - [ ] ViewModels?
  - [ ] Views?
- [ ] Sketch implementation approach
- [ ] Identify potential risks
- [ ] Write test plan

**Deliverable:** Implementation plan (1-2 pages)

---

### Implementation (Target: 6-8 hours)

**Development Process:**

- [ ] Create feature branch: `git checkout -b feature/my-feature`
- [ ] Make small, incremental changes
- [ ] Test after each change
- [ ] Write unit tests for new logic
- [ ] Update documentation if needed
- [ ] Follow design system (DesignTokens, JetBrains Mono)
- [ ] Check for linter warnings
- [ ] Run full test suite (⌘U)
- [ ] Manual testing in app

**Quality Gates (from .cursor/rules/zero-defect-quality.mdc):**

- [ ] No compiler warnings
- [ ] No force unwraps
- [ ] No hardcoded colors
- [ ] No rounded corners
- [ ] JetBrains Mono font used
- [ ] All tests pass
- [ ] No crashes during testing
- [ ] Feature works as intended

**Deliverable:** Working feature on branch

---

### Code Review Prep (Target: 1 hour)

- [ ] Clean up debug code
- [ ] Remove commented-out code
- [ ] Review your own changes (git diff)
- [ ] Write clear commit messages
- [ ] Update PUNCHLIST.md if feature complete
- [ ] Document any decisions made
- [ ] Prepare questions for review

**Deliverable:** Pull request or email to original developer

---

**Week 3 Checkpoint:**

- [ ] Feature selected and planned
- [ ] Feature implemented
- [ ] All quality gates passed
- [ ] Ready for code review
- [ ] Confidence level: Can complete features independently

---

## Week 4: Handover Completion

### Code Review (Target: 2 hours)

- [ ] Submit code to original developer
- [ ] Address review feedback
- [ ] Make requested changes
- [ ] Re-test after changes
- [ ] Get approval
- [ ] Merge to main branch

**Deliverable:** Merged feature

---

### Documentation Updates (Target: 2 hours)

- [ ] Update relevant .md files with new knowledge
- [ ] Add any gotchas you discovered
- [ ] Document decisions made
- [ ] Update PUNCHLIST.md
- [ ] Update PROJECT_STATUS.md

**Deliverable:** Documentation commits

---

### Knowledge Transfer (Target: 2 hours)

**Create handover notes:**

- [ ] List 5 things you wish you knew on Day 1
- [ ] Document any confusing areas
- [ ] Suggest documentation improvements
- [ ] Note any tools/scripts you created
- [ ] Identify areas needing more tests

**Deliverable:** HANDOVER_RETROSPECTIVE.md

---

### Final Validation (Target: 2 hours)

**Complete all validation tasks:**

- [ ] Validation Task 1: Read & Build ✅
- [ ] Validation Task 2: Add Simple Field ✅
- [ ] Validation Task 3: Add Simple Metric ✅
- [ ] Validation Task 4: Modify AI Prompt ✅
- [ ] Validation Task 5: Debug an Issue ✅
- [ ] Validation Task 6: Complete Independent Feature ✅

**Self-assessment:**

- [ ] I can build the app from scratch
- [ ] I understand the MVVM architecture
- [ ] I can safely modify SwiftData models
- [ ] I can add/modify calculator metrics
- [ ] I can modify AI prompts
- [ ] I can debug issues independently
- [ ] I can complete features without guidance
- [ ] I feel confident owning this codebase

---

### Handover Meeting (Target: 1 hour)

**Schedule call with original developer:**

- [ ] Demo your completed feature
- [ ] Walk through code changes
- [ ] Discuss architecture decisions
- [ ] Ask clarifying questions
- [ ] Confirm transition plan
- [ ] Discuss ongoing support
- [ ] Get final approval

**Deliverable:** Handover signed off ✅

---

**Week 4 Checkpoint:**

- [ ] Code reviewed and merged
- [ ] Documentation updated
- [ ] All validation tasks complete
- [ ] Self-assessment: Confident
- [ ] Handover meeting complete
- [ ] Officially own the codebase 🎉

---

## Post-Handover (Ongoing)

### First 30 Days After Handover

- [ ] Complete 2-3 more features from PUNCHLIST.md
- [ ] Write additional unit tests for coverage
- [ ] Improve documentation based on your experience
- [ ] Optimize any performance issues
- [ ] Fix any bugs discovered

### First 60 Days

- [ ] Implement larger feature
- [ ] Consider architecture improvements
- [ ] Add integration tests
- [ ] Enhance error handling
- [ ] Document new patterns

### First 90 Days

- [ ] You're now the expert 🎓
- [ ] Update handover docs for next developer
- [ ] Mentor others if needed
- [ ] Plan next major features

---

## Escalation Protocol

**If you get stuck:**

1. Re-read relevant documentation
2. Search codebase for similar patterns
3. Check TROUBLESHOOTING.md (when created)
4. Check GitHub Issues
5. Email original developer: info@htdstudio.net (24-48h response)

**Emergency contact (critical production issues only):**
- Original developer: info@htdstudio.net
- Include: "URGENT - Porteos Intelligence" in subject

---

## Success Criteria

**Handover is COMPLETE when all of these are ✅:**

- [ ] Week 1 checkpoint complete
- [ ] Week 2 checkpoint complete
- [ ] Week 3 checkpoint complete
- [ ] Week 4 checkpoint complete
- [ ] All validation tasks complete
- [ ] At least one feature merged
- [ ] Self-assessment: Confident
- [ ] Original developer sign-off

**🎉 CONGRATULATIONS! You now own Porteos Intelligence! 🎉**

---

**Tracking:**

- Start date: _______________
- Week 1 complete: _______________
- Week 2 complete: _______________
- Week 3 complete: _______________
- Week 4 complete: _______________
- Handover date: _______________

**Notes:**

(Use this space for personal notes, questions, or observations)

---

### Session 4 — Day 2 complete (handover takeover)

- All 6 Phase 1 docs read in full: HANDOVER, README, DEVELOPER_SETUP, ARCHITECTURE, EXTERNAL_SERVICES, DATA_MODEL_GUIDE. Reading queue complete.
- **Day 2 deliverable — architecture summary (own words):** Porteos Intelligence is a zero-dependency SwiftUI + SwiftData macOS app (~35k lines, 142 files) built on strict MVVM. SwiftData `@Model` classes (6 total; `PropertyDeal` is the core, with 85+ raw inputs grouped into Base / Real Estate / Hospitality / Design / Circular Economy / Regulatory / Geocoding / Metadata) hold data only and contain no logic. `@Observable` ViewModels (e.g., `PropertyDealViewModel`) bridge model and view, exposing 50+ computed metrics by delegating to five pure-function calculator structs (RealEstate, Hospitality, Design, CircularEconomy, PorteosScore 0–100) — stateless, synchronous, guard-clause-returns-0, never persisted (the sole exception is `porteosScore`, cached for list sorting and recomputed on launch). Views are dumb renderers. The shell is a fixed 3-pane layout — 260pt NavigationPane | flexible center hosting 6 profile dashboards (⌘1–⌘6) | 280pt InspectorPane (WEIGHTS / AI VIBE / RESEARCH / MEDIA tabs) — plus a 40pt TopHeaderBar and 32pt GlobalCommandBar, with multi-window profile instances kept in sync via `@AppStorage("selectedDealID")`. All side effects are quarantined in singleton Services (multi-provider LLM, HTTP ingest server :9000 for the 12-site browser extension, IMAP mail polling, RSS news aggregation, MapKit geocoding, PDF reports, deal history, window management); every one is optional, so the core app works fully offline. Design authority is `DesignTokens.swift` (JetBrains Mono only, zero rounded corners, 8pt grid, monospaced digits). Persistence is SwiftData with a backup-and-reset migration strategy (schema mismatch → backup to `~/Documents/PorteosBackups/` + fresh store; only add-with-default field changes are safe).
- `xcodebuild test` CLI failure is a known sandbox/environment limitation (documented in KNOWN_ISSUES.md, commit 5910e89). Workaround: ⌘U in Xcode IDE. Non-blocking.
- ✅ User instruction (via Cursor, Sept 4): removed stale `PorteosUnitTests` scheme reference from KNOWN_ISSUES.md (v1.1) — the scheme was deleted in Session 3 and stays deleted; `PorteosIntelligence` scheme (with its TestableReference) is the only one.
- ✅ Day 1 checked off — user confirmed: environment setup confirmed (setup 27 pass / 1 warn / 0 fail, build SUCCEEDED, ⌘U passes in IDE).
- ✅ User feedback: "Architecture summary demonstrates solid understanding."
- Next: Day 3 code exploration (PorteosIntelligenceApp.swift, PropertyDeal.swift in sections, RealEstateCalculator.swift, PropertyDealViewModel.swift, AppShell.swift, DesignTokens.swift). Deliverable: 3 things found interesting or confusing.

---

### Session 9 — Day 3 complete (handover takeover)

- All 6 core files read and verified against current `main` (0df230d): PorteosIntelligenceApp.swift (150), PropertyDeal.swift (473), RealEstateCalculator.swift (349), PropertyDealViewModel.swift (178), AppShell.swift (515), DesignTokens.swift (306). Per-file notes posted in chat (files 1–2 in Session 5; files 3–4 in Session 8; files 5–6 in Session 9).
- **Day 3 deliverable — 3 interesting + 3 confusing (line refs verified this session):**
  - *Interesting:* `DesignTokens.swift` is the single design authority — Figma-annotated colors, 8pt-grid layout constants, JetBrains-Mono TypeScale — plus `MetricState`/`DealStatus`/`TerminalSemanticAction` semantic-color extensions and a `@deprecated` alias block (V2.06_STABLE token governance). The "tokens" file doubles as the semantic-state color spec.
  - *Interesting:* `RealEstateCalculator.swift:177–179` — silent 3-step exit-cap fallback (exitCapRate → capRate → 5.0%) with no warning; hidden 5-yr return assumptions (flat NOI, 80%/39-yr depreciation :151, flat 25% tax :163). Also `sanityCheck` (:333–348) uses `print()` — a soft side-effect in an otherwise pure calculator; it returns 0, so the UI silently shows "—" on bad data.
  - *Interesting:* `AppShell.swift` — the entire 6-dashboard ⌘1–⌘6 surface is one `@ViewBuilder` if/else-if cascade on `wm.activeProfile` (:333–357); terminal-style empty state `ls ./deals` + `[ ./LOAD_SAMPLE_DEAL ]` hardcoded Lisbon sample deal (:364–371); "MODULE NOT YET IMPLEMENTED" placeholder (:418); a `Binding` get/set bridges AppStorage ↔ `wm.activeProfile` (:46–47).
  - *Confusing:* `PropertyDeal.swift:449` — `var comparables: [Comparable]` shadows Foundation's `Comparable` protocol (JSON round-trips on every access, "for simplicity, no migration").
  - *Confusing:* `PropertyDealViewModel.swift:164,168` — `formattedNOI`/`formattedADR` hardcode `.currency(code: "EUR")` while the model derives `currencySymbol` per country.
  - *Confusing:* multi-window source-of-truth tangle — App file comment "each window fully self-contained" + AppShell reading selection from `wm`, vs ARCHITECTURE.md's `@AppStorage("selectedDealID")` sync claim. Stale doc or mid-migration; reconcile in Week 2 `MULTI_WINDOW_SYSTEM.md`.
- Carried-forward doc inconsistencies (non-blocking): README "80+ cities" vs MarketBenchmarks 43; "7 test bundles" count unverified; README "Running Tests" still documents CLI `xcodebuild test` (left as-is per user instruction; see KNOWN_ISSUES.md).
- ✅ Day 3 checked off — all 19 boxes.
- Next: Day 4 — first code change (add `testField` to PropertyDeal; 6-step workflow in DATA_MODEL_GUIDE.md + DB backup step).

---

### Session 11 — Day 4 complete (handover takeover)

- **Day 4 headline — the docs over-predicted the risk.** Adding a stored property *with a default value* (`var testField: String = "default"`) → `ModelContainer(for:)` succeeded via Core Data **in-place lightweight migration**; the backup+reset catch branch (`PorteosIntelligenceApp.swift:26–87`) never fired, no new backup triple appeared, and all 10 existing deals were silently backfilled with the default. **`SWIFTDATA_MIGRATION.md:190`'s claim that "even safe changes trigger reset" is contradicted by observation** — one-line doc-correction candidate for Week 2 (SWIFTDATA_MIGRATION.md intentionally NOT touched during Day 4).
- **Workflow executed (all 8 plan steps + cleanup + final launch check):**
  1. Backup: 174 MiB triple (`default-2026-09-05T17-06-16Z-day4-pre.store` + `-shm` + `-wal`) → `~/Documents/PorteosBackups/` via SQLite online-backup while the app ran, then graceful quit. (Checklist backup path uses stale bundle ID `net.htdstudio.PorteosIntelligence`; real is `com.porteos.native.v2` — carried to Week 2, not fixed here.)
  2. 2-line test-field edit in `PropertyDeal.swift` (after `status`) → incremental build SUCCEEDED.
  3. Launch → no reset; `ZTESTFIELD` column added in-place, all 10 rows backfilled `'default'`.
  4. Probe deal created via ingest HTTP: `serverAutoStartEnabled` was absent in UserDefaults (auto-start is off by default when the key is missing) → set temporarily; `POST /api/deals` → `{"dealID":"6C875B93-1DF8-4D47-B366-19EB6ADF6AA9","success":true}`; 11 rows, all with `testField == "default"`.
  5. Persistence: quit (≈2s) → relaunch → health 200 in 5s → 11 rows, probe intact → **persistence validated** ✅ (no second reset).
  6. Cleanup + revert: quit app; probe row deleted via sqlite3 (surgical, app stopped); `git restore` on PropertyDeal.swift (0 `testField` occurrences left; tree back to only the 2 known dirty files); rebuild SUCCEEDED.
  7. Final post-revert launch check: Core Data lightweight migration ran **in reverse** — the residual `ZTESTFIELD` column was **dropped** (91 columns, exact model match), 10 original deals intact (Z_PK 3,5,6,7,16–21), no reset, no new backup triple. The store is byte-equivalent in content to pre-Day 4.
  8. Environment restored: app quit; `serverAutoStartEnabled` UserDefaults key deleted again (absent before Day 4 → behavior exactly as found).
- **Deliverable:** git diff saved as `~/.lmstudio/scratchpads/r/day4-propertydeal-testfield.diff` — the 2-line addition (marker comment + `var testField: String = "default"`) after `status` in `PropertyDeal.swift`; file restored to `main` state and rebuilt clean.
- Carried forward, not fixed in Day 4 (Week 2 candidates): SWIFTDATA_MIGRATION.md §181–190 reset claim vs observed in-place migration (above); README "80+ cities" vs MarketBenchmarks 43; "7 test bundles" count unverified; app displays backup path `~/Documents/PorteosBackups/` but the sandboxed app lands them in `~/Library/Containers/com.porteos.native.v2/Data/Documents/PorteosBackups/`.
- ✅ Day 4 checked off — all 8 boxes + deliverable.
- Next: Day 5 — first metric (`pricePerSqft` in RealEstateCalculator + computed property in PropertyDealViewModel + RealEstateDashboardView display + unit test). ✅ completed Sept 6 — see below.

---

### Sept 6 — Day 5 complete (handover takeover)

- **Day 5 deliverable (all verified):** `pricePerSqft` pure function in `RealEstateCalculator` (bannered `// MARK: - Unit Price`, +14) → `PropertyDealViewModel.pricePerSqft` computed property (+9) → `RealEstateDashboardView` TerminalMetricCell "PRICE / M²" (`—` when area 0, +11) → new `RealEstateCalculatorTests.swift` (happy path + zero-area guard). Display verified in app by user (**€2,000/m²**); suite runs via CLI (**52 tests**, MLX-confirmed).
- **Test-runner reality inverted vs KNOWN_ISSUES v1.1:** CLI *does* run the full suite; the IDE ⌘U is the side reporting "0 of 0, all passed". The 4-line fix (remove `TEST_HOST`/`BUNDLE_LOADER`) is **not viable** — the tests `@testable import` app-target code, so the hosted-bundle wiring is load-bearing; removal broke the test target's link (`ld: symbol(s) not found`, both archs) and was fully reverted (`project.pbxproj` diff empty, build green). Host app is healthy (store writes observed, no crash reports), so the IDE 0-runs is IDE-side discovery/state — leading suspect is stale build (⌘⇧K + ⌘U is the next diagnostic). KNOWN_ISSUES.md rewritten to match reality (v1.2).
- **Durable fix parked (needs explicit approval):** Option B — extract the 5 pure static calculators into a `PorteosCore` framework shared by app + tests; tests become non-hosted, ⌘U and CLI behave identically, issue retires. Not done here (restructure beyond the fix).
- `.gitignore` now includes `/build/` (the xcodebuild output dir was untracked noise).
- **Week 1 complete** — all 5 days checked off, Week 1 checkpoint green.
- Next: Week 2 Day 1 — Phase 2 docs (SWIFTDATA_MIGRATION, LLM_INTEGRATION, CALCULATOR_SYSTEM, BROWSER_EXTENSION_GUIDE, MULTI_WINDOW_SYSTEM).

---

**Version:** 1.0 (Sept 4, 2026)  
**Last updated by:** Original development team
