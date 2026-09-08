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
- **Round 2 deep-dive (6 questions): queue APPROVED Sept 6.** Dispositions: currency fix (EUR hardcoding + LLM prompt € literals) → Week 2 Day 3 (AI prompt day); `pricePerSqft` in ScenarioDetailView → Week 3; PRs + PUNCHLIST → Week 3.

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

**Status: ✅ Day 1 COMPLETE (Sept 7)** — re-scoped: external services + AI Vibe validation + deep code review (planned Phase 2 doc reads: SWIFTDATA_MIGRATION + LLM_INTEGRATION covered via Week 1 live validation + Day 1 code review; CALCULATOR_SYSTEM + MULTI_WINDOW_SYSTEM deferred to Day 2; BROWSER_EXTENSION_GUIDE to Day 3 — see Sept 7 log)

**Advanced Documentation:**

- [x] Read SWIFTDATA_MIGRATION.md (45 min)  *(read in full Sept 5, Session 11 — 764 lines; backup/reset + safe-vs-unsafe validated live Day 4; testing strategy = 52-test CLI suite Day 5)*
  - [x] Understand backup + reset strategy
  - [x] Understand safe vs unsafe changes
  - [x] Understand testing strategy
- [x] Read LLM_INTEGRATION.md (60 min)  *(multi-provider architecture, prompt patterns, and error handling verified in Day 1 code review of `LLMAnalysisService.swift` — code is the stronger source)*
  - [x] Understand multi-provider architecture
  - [x] Understand prompt patterns
  - [x] Understand error handling
- [ ] Read CALCULATOR_SYSTEM.md (45 min) *(deferred to Day 2 — Day 1 code review covered CircularEconomy + currency hazards only)*
  - [ ] Understand all 5 calculator modules
  - [ ] Understand key formulas
- [ ] Read BROWSER_EXTENSION_GUIDE.md (45 min) *(deferred to Day 3 — browser extension day)*
  - [ ] Understand scraper pattern
  - [ ] Understand 12 supported sites
- [ ] Read MULTI_WINDOW_SYSTEM.md (45 min) *(deferred to Day 2 — code tangle already identified in Day 1 review, finding F4)*
  - [ ] Understand @AppStorage sync
  - [ ] Understand WindowGroup pattern

**Deliverable:** Notes on each doc's most important concepts — ✅ re-scoped Day 1 deliverable: 5 code findings + 6 new observations, see Sept 7 log

---

### Day 2: Browser Extension (Target: 3 hours)

**Status: ✅ Day 2 COMPLETE (Sept 8)** — re-scoped: browser extension pulled forward from Day 3 per user instruction ("proceed directly to browser extension"); external-services boxes below superseded by Day 1 (Ollama 7 models + in-app AI Vibe on two providers pre-verified Sept 7 — see Sept 7 log). Code review ✅ agent; **live Chrome test ✅ Howard** (Sept 8 ~20:07 — install + import succeeded, deal landed in-app; see Sept 8 log). Week 2 checkpoint "Browser extension tested" now checked.

**External Services (superseded Day 1 — boxes checked against Sept 7 evidence):**

- [x] Install Ollama: https://ollama.com/download  *(v0.32.14 installed + serving; headless re-verify Sept 7)*
- [x] Pull model: `ollama pull llama3.2:latest`  *(intent met — llama3.2 not on machine; **phi4-mini** used instead — user confirmed in-app)*
- [x] Start Ollama server: `ollama serve`  *(:11434 — HTTP 200 on `/api/tags`)*
- [x] Open app Settings → LLM Provider → Ollama
- [x] Set URL: `http://localhost:11434`
- [x] Set model: `llama3.2:latest`  *(Settings: `phi4-mini` — the model actually used)*
- [x] Test AI Vibe feature on a deal  *(in-app Sept 7: phi4-mini local ~42s; gemini-3.5-flash cloud ~60s)*
- [x] Verify SWOT analysis generates  *(both providers: coherent, deal-specific SWOT; consistent 41/100 NO GO)*

**Alternative (if Ollama fails):**

- [ ] Use OpenAI instead  *(not needed — Ollama + Gemini both worked Sept 7)*
- [ ] Add API key in Settings
- [ ] Test AI Vibe with OpenAI

**Deliverable:** Screenshot of working AI Vibe panel  ✅ pre-cleared Day 1

**Chrome install (Howard — guide :129–141, path verified):**

1. Open `chrome://extensions` (Arc/Edge/Brave: same)
2. Toggle **Developer mode** (top-right)
3. Click **Load unpacked**
4. Select: `BrowserExtension/PorteosImporter/` (repo-root-relative — **not** bare `BrowserExtension/`; the manifest lives inside `PorteosImporter/`)
5. Reload any listing page already open — the in-page **[ SEND TO PORTEOS ]** button is injected at `document_idle` (the toolbar icon does nothing — M3)

**Pre-flight (before any test):**

- App running + ingest server **enabled** — auto-start is **OFF by default** (H2: `serverAutoStartEnabled` absent in UserDefaults = off, Week 1 Day 4 evidence) — app shows green `HTTP` indicator (guide :137–141)
- `curl -s http://localhost:9000/api/health` → 200 (`DealIngestionServer.swift:156`; optional `X-Porteos-Key` 401 guard :331–338 only if a key is set in Settings)

**Per-site test matrix** *(per import, verify in-app: real name ≠ "Browser Import" (D4) · plausible price · correct city · correct currency (Portugal = EUR) · **re-click returns "already exists" toast, no second deal** (server URL dedupe; I1); server keeps last 50 request logs for post-mortem):*

- **Zillow US (primary)** — any `zillow.com/homedetails/…`: button appears (M4 gate), deal with name/price, USD + USA
- **Idealista.pt (primary)** — any `idealista.pt/imovel/…`: **EUR + Portugal** (D1); `bathrooms: 0` by design
- **Imovirtual.com** — any `/oferta/…` (or `/anuncio/`): guide has no Imovirtual section (G1) — verify name/price carefully
- **Optional:** Casa SAPO.pt (`/comprar-…` listings), Booli.se (`/bostad/…` — **verify the button appears at all** — G5)

**Expectations (do not file bugs for these):** `bathrooms: 0` on Idealista/Booli paths (DOM doesn't expose it); extension `latitude`/`longitude` dropped (D2) → app re-geocodes post-save; currency always derives from country (D1); "no button" = URL gate or JSON shape change (M4), not necessarily an error.

**Day 2 findings (all file:line-verified Sept 8):**

*Manifest* (`BrowserExtension/PorteosImporter/manifest.json`): **M1** `version: "3.0.0"` vs `content.js` **v5.0** (header :2 + 12 console markers :311–:1483). **M2** `permissions [activeTab, scripting]` never used (declarative content_scripts only) — removable, non-blocking. **M3** no background service worker → toolbar icon click does nothing. **M4** Zillow button requires `/homedetails/` URL (content.js:216) **and** parseable `__NEXT_DATA__` — no DOM-only fallback. (`host_permissions` = `:9000` + 14 www patterns for 12 sites — remax.pt ×2.)

*Protocol* (content.js payload vs `DealIngestionServer.swift` `DealIngestionPayload` :108–128): **D1** server never decodes `currency` (grep = 0) — model derives from country with `€` fallback (`PropertyDeal.swift:67`; ties Day 1 F3). **D2** server never decodes `latitude`/`longitude` — `GeocodingService` re-geocodes post-save. **D3** guide documents `images` in ~11 places (:199, :227, :514, :730…) but **no v5 scraper emits `images`** (grep = 0). **D4** no server required-field validation (guide pseudo-code :772–781 is aspirational) — near-empty payloads accepted with defaults ("Browser Import" :503; `inferCity` def :624 / call :418 with `address: ""`). **All 12 scrapers send `locationFullAddress` + `currency` + coords (grep-verified 12/12) — the server drops all of them.**

*Guide* (`BROWSER_EXTENSION_GUIDE.md`, 937 lines): **G1** Quick Stats "12 sites" (:30) vs per-site docs covering 11 — Imovirtual section missing (grep = 0); code + manifest have 12. **G2** Data Shape `sourceURL`/`address` (:198–199, :226, :721–731) vs code `url`/`locationFullAddress`. **G3** Zillow "Key Selectors" `data-test=…` (:245–252) stale vs v5 `__NEXT_DATA__` + `data-testid='price'` (:221–241). **G4** guide "3.0.0" (:28, :66) vs content.js v5 — same root cause as M1. **G5** Booli URL `/annons/*/` (:379) vs code gate `/bostad/` (:1403) → Howard: verify button appears. **G6** stale "Select `BrowserExtension/`" path was in this checklist's Day 3 box, not the guide (guide :137 correct) — fixed below.

*Hygiene + improvements:* **H1** prebuilt `PorteosImporter.zip` in source tree — already gitignored (`*.zip`) + untracked; no git change needed (leave or delete). **I1** no client idempotency token — button re-enables 4 s after success / 5 s after error; repeat clicks are caught by **server dedupe** (URL primary :428, name+city fallback :430–435, returns `duplicate: true`) but payloads with differing URLs (query params) or no URL can still duplicate; suggest keeping the button disabled after a successful send. **I2** bedroom regex `/\bT(\d)\b/` single-digit at :628 (Idealista.pt) / :754 (Remax.pt) / :898 (Casa SAPO) / :1036 (Imovirtual) — `T10`-edge + bare-`T1` false match; `T(\d+)` proposed. **I3** server should accept payload lat/lon and skip geocoding when present (D2). **I4** server should accept `locationFullAddress` + `currency` as fallbacks (D1/D2).

**Task-named Rightmove:** does not exist in the code (guide-only hypothetical at :391+) — Zillow (215–315) + Idealista.pt (608–684) + Booli (1402–1485) reviewed in full; Imovirtual / Casa SAPO / Hemnet spot-checked.

---

### Day 3: Browser Extension (Target: 2 hours)

**Status: ⬜ superseded → Day 3 free** — browser extension pulled forward to Day 2 (Sept 8) per user instruction; boxes below kept for reference. **Suggested Day 3 content:** the Phase 2 docs deferred on Day 1 — CALCULATOR_SYSTEM (5 calculator modules, key formulas) + MULTI_WINDOW_SYSTEM (@AppStorage-sync vs `WindowManager` singleton tangle, finding F4).

**Install and Test:**

- [ ] Open Chrome: `chrome://extensions/`
- [ ] Enable "Developer mode" (top right)
- [ ] Click "Load unpacked"
- [ ] Select: `BrowserExtension/PorteosImporter/` folder  *(G6-corrected — original `BrowserExtension/` was wrong; the manifest lives inside `PorteosImporter/`)*
- [ ] Navigate to Zillow listing (USA)
- [ ] Click [ SEND TO PORTEOS ] button
- [ ] Verify deal appears in app
- [ ] Test with another site (Idealista Portugal)

**Study Scraper Code:**

- [ ] Open `BrowserExtension/PorteosImporter/content.js`  *(1,486 lines; file lives inside `PorteosImporter/`)*
- [ ] Find `initZillow()` function (lines 215-315)  *(actual module range)*
- [ ] Understand scraper pattern  *(each `init*()` module = URL gate → extraction → `injectButton` :120–186 → POST)*
- [ ] ~~Find `extractZillowData()` function~~  *(doesn't exist in v5 — extraction is inline closures per module; no such function)*
- [ ] Understand data extraction utilities  *(shared helpers :23–118: `trySelect` / `parsePrice` / `priceFromJsonLd` / `extractJsonLd` / `coordsFrom*`)*

**Deliverable:** Successfully import 2 properties from different sites  *(= Day 2 test matrix — Howard)*

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

- [ ] All Phase 2 docs read *(Day 1 progress: 2 of 5 doc groups covered via code review + live validation)*
- [x] External services configured (at least one)  *(Ollama pre-verified Sept 7 — 7 models serving; in-app AI Vibe on two providers, 41/100 NO GO consistent)*
- [x] Browser extension tested  *(code review ✅ Sept 8 — 20 findings; live Chrome test ✅ Sept 8 — install + import succeeded, deal in-app with real name / correct city / EUR)*
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
- **Durable fix (Option B): user decision Sept 6 — keep parked.** Extract the 5 pure static calculators into a `PorteosCore` framework shared by app + tests (would retire the IDE quirk) — not worth the restructure cost. CLI tests work fine; tracked as known IDE quirk in KNOWN_ISSUES.md v1.2.
- `.gitignore` now includes `/build/` (the xcodebuild output dir was untracked noise).
- **Week 1 complete** — all 5 days checked off, Week 1 checkpoint green.
- Next: Week 2 Day 1 — Phase 2 docs (SWIFTDATA_MIGRATION, LLM_INTEGRATION, CALCULATOR_SYSTEM, BROWSER_EXTENSION_GUIDE, MULTI_WINDOW_SYSTEM). ✅ completed Sept 7 — see below.

---

### Sept 7 — Day 1 (Week 2) complete (handover takeover)

- **Scope re-scoped from plan:** planned Day 1 = Phase 2 doc reads; actual Day 1 = external services setup + AI Vibe validation + deep code review (session decision).
- **External services:** Ollama **v0.32.14** running, **7 models** on machine (phi4-mini, qwen2.5-coder:14b/7b/32b, gemma4:12b, deepseek-r1:14b, qwen2.5:0.5b — re-verified Sept 7 headless via `:11434/api/tags`). Live headless re-verify: **phi4-mini HTTP 200 in 15.2s / 135 tokens** on a real SWOT prompt (Lisbon deal, 1,200 m², €2.4M) → coherent deal-specific SWOT + 78/100 GO. In-app AI Vibe (prior session, user-verified): phi4-mini (local) ~42s + gemini-3.5-flash (cloud) ~60s; both produced consistent deal-specific SWOT with the same **41/100 NO GO** verdict. Planned `ollama pull llama3.2:latest` substituted with **phi4-mini** (llama3.2 not on machine; 3.8B fits the intent; user confirmed phi4-mini works in-app).
- **Portugal deal currency = EUR, displayed correctly in app ✅** — Round 2 currency question answered for the test deal; the general fix (hardcoded EUR) remains Week 2 Day 3 — finding F3.
- **Deep code analysis — 5 findings (3 interesting + 2 confusing), all with file:line:**
  - *F1 interesting:* `struct Comparable` shadows Swift's `Comparable` protocol at module level — `Models/PropertyDeal.swift:406` (`struct Comparable: Codable, Identifiable`); used at :449, :452 (`decode([Comparable].self)`), :460, and `Views/GlobalIntelligence/GlobalIntelligenceCompsView.swift:258,308`.
  - *F2 interesting:* LLM fabricates market data — chat-only providers with no web access (`Services/LLMAnalysisService.swift:6–8`); "market insights" are confident guesses. A static `MarketBenchmarks` table is injected into the prompt (:505–525, with `€` literals), the system prompt is "professional real estate investment analyst" with no tools (:547), and the prompt seeds a **fabricated example with invented stats** (:660: "ADR of €95-110 ... 15-20% above city average ... UNESCO"). My live phi4-mini run reproduced the same sourceless-claims pattern.
  - *F3 confusing:* currency logic split 3 ways — model `currencySymbol` (country→symbol map with `€` fallback, `PropertyDeal.swift:67`) vs VM hardcoded `formatted(.currency(code: "EUR"))` (`ViewModels/PropertyDealViewModel.swift:164,168`) vs prompt `€` literals (`LLMAnalysisService.swift:513–518`) mixed with `deal.currencySymbol` (:621, :691). All agree for Portugal (why EUR displays correctly); they diverge for e.g. a US deal.
  - *F4 interesting:* multi-window doc-vs-code tangle — `ARCHITECTURE.md:395,398,521` claims `@AppStorage("selectedDealID")` sync, but the code has no `@AppStorage` for selection; it uses the `WindowManager.shared.selectedDealID` singleton (`Views/Shell/ProfileWindowView.swift:22,115,168–175` "single source of truth" comment; `Views/Shell/DetachedPaneViews.swift:59–67,109,122`), while the `PorteosIntelligenceApp.swift:120` "fully self-contained" comment contradicts it. Stale-docs theme recurs from Week 1 (bundle-ID fix 241ce87, SWIFTDATA_MIGRATION.md:190).
  - *F5 confusing:* circular economy — `PropertyDealViewModel.swift:81–82` hardcodes `vendorCount: 0, averageHourlyRate: 0` into `CircularEconomyInputs`; the CE model fields default to 0 (`PropertyDeal.swift:130–141`), so a deal with no CE data scores **0 as if measured** (`Calculators/CircularEconomyCalculator.swift`).
- **New observations (6):**
  - *N1:* `LLMAnalysisService.swift:74` — `ollamaTimeoutSeconds = 45`; the in-app phi4-mini run was 42s → only 3s of headroom (a longer SWOT risks flaky timeouts; my headless run 15.2s ≈ 8.9 tok/s).
  - *N2:* hardcoded provider model names `gpt-4o-mini` (:72) / `gemini-3.5-flash` (:73); only the Ollama model is user-selectable in Settings.
  - *N3:* `PropertyDeal.swift:67` — `currencySymbol` fallback `return "€"` silently buckets ALL unlisted countries (PT, ES, DE, TR…); the "zero risk of stale data" comment (:41) is contradicted by the hardcoded-EUR VM + prompt `€` literals.
  - *N4:* `PropertyDeal.swift:452` — `comparables` stored as a JSON blob, decoded with `try?` + `?? []` — a decode failure silently discards comps.
  - *N5:* the prompt seeds a fabricated few-shot example with invented statistics (`LLMAnalysisService.swift:660`) — teaches the model to fabricate confidently (reinforces F2).
  - *N6:* app-level comment (`PorteosIntelligenceApp.swift:120`) and shell-level comment (`ProfileWindowView.swift:168`) disagree on who owns selection state.
- **Checklist:** Week 2 Day 1 boxes updated — SWIFTDATA_MIGRATION + LLM_INTEGRATION groups checked; CALCULATOR_SYSTEM + MULTI_WINDOW_SYSTEM deferred to Day 2; BROWSER_EXTENSION_GUIDE to Day 3.
- ✅ **Day 1 complete.** Week 2 checkpoint: 0/6 (day 1 of 5).
- Next: Week 2 Day 2 — Ollama/llama3.2 decision + Settings provider config + in-app AI Vibe re-verify (largely pre-cleared on Day 1); then Day 3 = OpenAI Cloud Code + browser extension. ✅ superseded Sept 8 — see below.

---

### Sept 8 — Day 2 complete (handover takeover)

- **Scope:** Day 2 re-scoped to browser extension per user instruction ("proceed directly to browser extension") — external services pre-cleared Day 1 (Sept 7 log); Day 3 freed (suggested: deferred Phase 2 docs CALCULATOR_SYSTEM + MULTI_WINDOW_SYSTEM from Day 1).
- **Successor session** (prior handoff after context overflow) — every predecessor finding **re-verified directly** this session; corrections vs the handoff: manifest `content_scripts.matches` = the same 14 specific www patterns + `:9000` (not `*://*/*`); send button **disables in-flight** and re-enables 4 s success / **5 s** error (handoff guessed 15 s); G6 stale-path bug is in this checklist's Day 3 box, not the guide (guide :137 correct); `PorteosImporter.zip` gitignored + untracked (no git change); `T(\d)` spans **4** modules (:628/:754/:898/:1036); **all 12** scrapers send `locationFullAddress` + `currency` + coords (handoff said 11/12) — server drops all three; server **does** dedupe by URL (primary :428) + name+city (:430–435) — predecessor's "no URL dedupe" in I1 retracted, I1 re-scoped to client token / URL-mismatch residual.
- **Delivered (Day 2 section):** Chrome install steps (guide :129–141 verified) · pre-flight checklist (H2 auto-start OFF by default) · per-site test matrix (Zillow + Idealista.pt primary, Imovirtual, optional Casa SAPO/Booli) · expectations (bathrooms 0, D1/D2/M4) · 20 findings M1–M4 / D1–D4 / G1–G6 / H1–H2 / I1–I4, all file:line-verified.
- **Headline:** extension is structurally healthy (MV3; 12 site modules, all v5) but the **protocol diverged** — everything useful the scrapers send beyond the 14 struct fields (`currency`, `locationFullAddress`, `latitude`/`longitude`; `images` was never emitted at all) is silently dropped by `DealIngestionServer`; currency/city are best-effort derived server-side (D1–D4).
- ✅ Checklist: Day 2 boxes updated (external-services boxes checked against Sept 7 evidence; OpenAI boxes noted "not needed"); Day 3 annotated (pulled-forward note, `PorteosImporter/` path fix, `extractZillowData` footnote); Week 2 checkpoint — "External services configured" checked (Sept 7 in-app evidence), **"Browser extension tested" left UNCHECKED** pending Howard's live Chrome test. Checklist v1.2.
- ✅ **Live Chrome test PASSED** (Howard, Sept 8 ~20:07): install + import succeeded — deal now in app (sidebar 67.0%, grade B); **real scraper name** (D4 "Browser Import" default NOT hit), city derived correctly, **EUR** (€5 486/m² — Portugal = EUR; server-side derivation works despite the D1 currency drop); HTTP indicator green, 2 requests logged. Cosmetic nit observed: macOS **window title bar strips diacritics** ("Marco Cabaco" vs in-app "MARCO CABACÇO") — punchlist candidate. **Punchlist (add more sites to extension) deferred by user** until after handover complete.
- **Next:** punchlist (extension site additions) after handover; Day 3 = deferred Phase 2 docs when scheduled. Checklist v1.3.

---

**Version:** 1.3 (Sept 8, 2026)  
**Last updated by:** Handover (Week 2 Day 2 + live test results)
