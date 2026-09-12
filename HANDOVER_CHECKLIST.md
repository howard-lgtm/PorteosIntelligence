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

### Day 3: AI Prompt Modification — Currency De-hardcoding (Target: 2 hours)

**Status: ✅ Day 3 COMPLETE (Sept 9)** — user-assigned task: make ViewModel + LLM prompts respect the deal's dynamic currency (closes Day 1 finding F3). The old browser-extension Day 3 boxes were superseded — all delivered with Day 2 (Sept 8: code review + live Chrome test, deal imported with EUR). **Handoff correction:** a successor session's handover claimed Day 3 was "complete, committed, pushed" (commit `652562d`) — **false** (object does not exist; `origin/main` was `3087698`; the work was uncommitted and non-compiling until the missing `Currency` source was written this session). See Sept 9 log.

**Task (user step list — ViewModel + LLM prompts only):**

- [x] Locate hardcoded `"EUR"` in `PropertyDealViewModel` — `formattedNOI` :164 / `formattedADR` :168 used `.currency(code: "EUR")`
- [x] Replace with `deal.currencyCode`  *(ISO 4217 code — `FormatStyle.currency(code:)` requires a code, not a display symbol)*
- [x] Locate hardcoded `€` in LLM prompts (`LLMAnalysisService`) — benchmark block :507–518 + research few-shot example :660, :665
- [x] Replace with dynamic symbols  *(benchmark block: `Currency.symbol(forCountry: bm.country)`; research example: `deal.currencySymbol`)*
- [x] Logic verified — static trace: Portugal matches no country branch, marketId prefix misses → `("€","EUR")` fallback (behavior unchanged — matches Day 1 live evidence + Day 2 import); a US deal now resolves `$`/`USD` end-to-end
- [x] Build — `xcodebuild … -destination 'platform=macOS' build` → **BUILD SUCCEEDED** (headless)

**Key design decision:** new top-level `enum Currency` in `Models/PropertyDeal.swift` — ONE classifier `resolve(country:marketId:) -> (symbol, code)` whose if-chain is byte-identical to the old `currencySymbol` logic, each branch now paired with the ISO code; public `symbol(forCountry:marketId:)` + `code(forCountry:marketId:)` wrappers. `currencySymbol` delegates to it; new `currencyCode` sits beside it. Symbol and code can no longer diverge (the actual F3 fix); a future country is added in exactly one place.

**Day 3 findings — remaining hardcoded-`€` sites (known, out of scope — user scoped Day 3 to VM + prompts; listed for a future day, NOT fixed):**

- `Services/AIAnalysisService.swift` — 10 `€` sites  *(predecessor handoff said ~15 — corrected by grep this session)*
- `Services/DealResearchImporter.swift` — 19 `€` sites  *(predecessor handoff said ~13 — corrected by grep this session)*
- `Services/DealPreloader.swift` — :99, :100 (comments), :238 (comment), **:260, :264–265 (interpolated strings)**  *(predecessor handoff path `DealPrelearner/` did not exist — real path `DealPreloader`)*
- `Views/Sheets/QuickAddSheet.swift:422–423` — `let sym = currency == "USD" ? "$" : (currency == "SEK" ? "" : "€")` — 3-way ternary with EUR default
- `Views/GlobalIntelligence/GlobalIntelligenceInspectorViews.swift:360–370` — `formatCurrency` uses `NumberFormatter` with `f.currencyCode = "EUR"` + `"€%.1fM"` for ≥1M

**Still pending (needs a slot):** the Phase 2 docs deferred on Day 1 — CALCULATOR_SYSTEM (5 calculator modules, key formulas) + MULTI_WINDOW_SYSTEM (@AppStorage-sync vs `WindowManager` singleton tangle, finding F4) — Day 3 was consumed by the user-assigned currency task.

**Deliverable:** 4-file commit (PropertyDeal.swift + PropertyDealViewModel.swift + LLMAnalysisService.swift + this checklist) — `€` literal count in the two in-scope files now 0.

---

### Day 4: Debugging Practice (Target: 2 hours)

**Status:** ✅ Day 4 COMPLETE (Sept 10) — re-scoped by user from the SWOT prompt task (SWOT moved to Day 5); handoff takeover finished the checklist.

**Task: Intentionally break something, catch it, fix it**

- [x] Pick a target — `capRate` @ `RealEstateCalculator.swift:153`
- [x] Introduce a bug — remove `* 100` (cap rate silently becomes a fraction: 0.07 instead of 7.0 — no crash)
- [x] Create a failing test — temp `testCapRate` in `RealEstateCalculatorTests.swift` (€10M purchase price, 10% vacancy → NOI €700k ⇒ expect 7.0)
- [x] RED — real `xcodebuild test` run: `testCapRate` fails `7.0 != 0.07`
- [x] Debug in Xcode — breakpoint :153; inspect `noi` / `purchasePrice` / `capRate` → ratio correct, scale missing
- [x] Fix — restore `* 100` (byte-identical vs `82b8765`)
- [x] GREEN — suite re-runs; `testCapRate` passes (0.000s)
- [x] Revert — `git restore` both files; `git diff` vs `82b8765` empty; never committed

**Prerequisite milestone — scheme test-action mystery solved:** CLI "not configured for the test action" = Xcode auto-creates an empty test plan (`shouldAutocreateTestPlan=YES` + `LastUpgradeCheck=2660`) that replaces the TestableReference. Durable one-line fix: Xcode ▸ Edit Scheme ▸ Test tab → uncheck *Automatically create test plans*.

**Deliverable:** RED/GREEN evidence + debugger walkthrough in the Sept 10 log; tree fully reverted (no code committed).

---

### Day 5: Review & Consolidation (Target: 2 hours)

**Status: ✅ Day 5 COMPLETE (Sept 11)** — re-scoped by user (Sept 11): the original Day 5 (SWOT prompt exercise, moved here from Day 4 on Sept 10) became the Week 2 final-day review & consolidation. The SWOT exercise was **not performed** — deliberately carried to backlog below, not silently dropped.

**Tasks (user step list, Sept 11):**

- [x] Read HANDOVER_CHECKLIST.md Week 2 section (Days 1–5, checkpoint, Sept 7–11 logs)
- [x] Review Days 1–4 accomplishments — Day 1 external services (Ollama 7 models + AI Vibe on two providers) · Day 2 browser extension (20 findings + live Chrome import) · Day 3 currency de-hardcoding (`Currency` enum, 4-file commit `82b8765`) · Day 4 debugging practice (real RED/GREEN + scheme test-action mystery, `f2f5596`)
- [x] Week 2 checkpoint: all 6 boxes checked (below)
- [x] Retrospective written (5 bullets below)
- [x] Checklist footer bumped (v1.5 → v1.6 — user instruction said "v1.4"; footer was already at v1.5 since Day 4, so bumped forward, not backwards)
- [x] Commit: "Complete Week 2: Knowledge transfer phase" *(agent shell dead this session (zsh ENOENT) — Howard ran add/commit/push in his terminal; this is that commit)*

**Carry-over backlog (not performed — documented for Week 3+):**

1. **SWOT prompt customization** — `generateSWOT()` ~:200 in `Services/LLMAnalysisService.swift`: add "Focus on cash-on-cash return"; build + run; generate on test deal; verify output reflects the change; revert or commit if improvement
2. **Stale `testGradeBoundaries`** (`PorteosScoreCalculatorTests.swift` ~:68) — 3 assertions (60→B, 40→C, 20→D) encode the pre-`67e67ee` 60/40/20 scale; live scale is 80/65/50/35 (`PorteosScoreCalculator.swift:117–125`, `AIAnalysisService.swift:33–39`) → update the **test**, not the calculator (found during Day 4 RED/GREEN — Sept 10 log)
3. **Phase 2 doc backlog** — `CALCULATOR_SYSTEM.md` (5 calculator modules, key formulas) + `MULTI_WINDOW_SYSTEM.md` (@AppStorage sync vs `WindowManager` singleton tangle, finding F4) — deferred Day 1, never slotted
4. **Remaining hardcoded-`€` sites** (out of Day 3 scope) — `AIAnalysisService` (10) · `DealResearchImporter` (19) · `DealPreloader` :260/:264–265 · `QuickAddSheet` :422–423 · `GlobalIntelligenceInspectorViews` :360–370 (see Day 3 section)

**Deliverable:** This commit — Week 2 closed; next: Week 3 (independent development — pick one feature from PUNCHLIST.md)

---

**Week 2 Checkpoint:**

- [x] All Phase 2 docs read  *(SWIFTDATA_MIGRATION + LLM_INTEGRATION Day 1; BROWSER_EXTENSION_GUIDE Day 2 — 937 lines, 6 guide findings; CALCULATOR_SYSTEM + MULTI_WINDOW_SYSTEM deferred to carry-over backlog on Day 5 — consolidation judged knowledge transfer complete via code review; user-confirmed at Week 2 close)*
- [x] External services configured (at least one)  *(Ollama pre-verified Sept 7 — 7 models serving; in-app AI Vibe on two providers, 41/100 NO GO consistent)*
- [x] Browser extension tested  *(code review ✅ Sept 8 — 20 findings; live Chrome test ✅ Sept 8 — install + import succeeded, deal in-app with real name / correct city / EUR)*
- [x] AI prompt modified  *(Day 3 — LLMAnalysisService prompt de-hardcoded: benchmark block + research few-shot example now use dynamic currency; Sept 9. SWOT exercise re-scoped out on Day 5 (Sept 11) — carried to backlog)*
- [x] Debugging skills validated  *(Day 4 Sept 10 — real xcodebuild test RED/GREEN; scheme test-action mystery solved, see Sept 10 log)*
- [x] Confidence level: Can make targeted changes independently  *(user-confirmed Week 2 close: 4 days of targeted changes — 1 refactor (Currency enum), 1 protocol audit (20 findings), 1 debug cycle, 1 punchlist entry — all committed + pushed)*

**Week 2 Retrospective (Day 5, Sept 11):**

- **What went well — the re-scope mechanism.** Every day pivoted cleanly (Day 1 docs → external services; Day 2 extension pulled forward; Day 3 user-assigned currency fix; Day 4 debugging; Day 5 consolidation) and the checklist + dated session logs kept the evidence chain unbroken across four agent handoffs.
- **What went well — live verification pairing.** Howard's in-app / in-browser checks (AI Vibe on two providers, Chrome import, in-app EUR) closed what an agent can't run headless; the Day 2 live import surfaced the server's protocol divergence that code review could only half-see.
- **What was hard — three kinds of drift:** extension ↔ server protocol (D1–D4: 3 of 12 payload fields silently dropped), docs vs code (guide 3.0.0 vs v5, stale selectors, wrong install path), and handoff docs vs repo (a 5th stale handoff, incl. one claimed commit that never existed). Plus the agent shell died every session (zsh ENOENT) — every commit depended on Howard's terminal.
- **Key learning 1 — code is the source of truth.** Docs over-predicted risk (SwiftData reset → actually in-place lightweight migration) and under-documented reality (server drops fields, dedupes where the guide says it doesn't). Verify against code; treat docs as leads.
- **Key learning 2 — single-source refactors beat patching.** The `Currency` enum (Day 3) is the shape of the fix for duplicated domain logic: one classifier, symbol and code can no longer diverge, one place to add a country. And real test runs caught a genuinely stale test (`testGradeBoundaries`, stale since `67e67ee`) — which became the scheme test-action milestone.

---

## Week 3: Independent Development

### Day 1: Feature Selection (Target: 1 hour)

**Status: ✅ Day 1 COMPLETE (Sat 12 Sept 2026)** — selection: **AI Vibe score display fix** (PUNCHLIST "Scoring System"). *Agent recommendation per the Week 3 task brief — flagged for Howard's confirmation; approval box below deliberately left unchecked.*

**Task:**

- [x] Review PUNCHLIST.md  *(root — all 7 sections: Today · Scoring System · High priority · V2 considerations · Low priority · Done · Quick ref — plus `Documentation/PACKAGE_v1_PUNCHLIST.md` P0–P17; full read, ~1 h)*
- [x] Review the 4 named sections  *(Scoring System — root :67 · Protocol — PACKAGE_v1 P7 :181, D1–D4 live in Day 2 entry · UI/UX — PACKAGE_v1 P1–P5 (shell / sheets / PDF / admin / visual QA) · Future Enhancements — root V2 :98 + epics P10/P14/P17)*
- [x] Select ONE feature (medium)  ✅ AI Vibe score display fix
- [x] Document choice and reasoning  ✅ below
- [x] Sync PUNCHLIST.md status  *(Scoring System :71 "deferred to Week 5+" → "selected for Week 3"; fix-directions header :82 "Week 5+" → "Week 3" — same-repo drift guard per Week 2 retrospective learning 1)*
- [ ] Get approval from original developer ← **pending Howard**

**Feature description** — the AI Vibe panel shows two quantities that don't agree: the composite-score hero reads the **cached** `deal.porteosScore` (`AIVibePanel.swift:178`, function `resultHero` :175 — the punchlist's `:174` is stale, that line is blank) while the five signal bars (`topBarSignals` :763–773, `scoreForSignal` :775) are **derived from LLM sentiment** by a positional formula (positive = min(99, 88+idx) … critical = max(25, 42 - 3·idx)) — no arithmetic relation to the composite. Observed on the 10 Sept Portugal deal: hero **100/100** vs bars **88 / 89 / 90 / 62 / 92** (avg ≈84) — the panel looks internally inconsistent. Root cause was fully investigated Week 2 (4 avenues, PUNCHLIST :73–80): 100 is a *legitimate* calculator output (saturation caps :55–56 + bonus stack + clamp :109 in the 126-line `PorteosScoreCalculator.swift`), so the 100-vs-84 gap is a **presentation / category error**, possibly compounded by hero staleness (11 write sites; e.g. `:982` after benchmark-apply).

**Why I chose it:**

1. **Right complexity tier** — PUNCHLIST rates it Priority: Medium; the brief asked for medium (not trivial, not too complex).
2. **Root cause already known** — Week 2's 4-avenue investigation is done and documented; Week 3 is execution, not archaeology.
3. **App-only scope** — no live-Chrome dependency (unlike the protocol-divergence candidate), no network re-test; verifiable via the 52-test CLI suite + Howard's in-app manual check.
4. **Highest user-visible credibility impact** — a 100/100 hero the user can't reconcile with its own bars is a direct trust hit on AI Vibe, the Week 2 headline feature.

**Estimated complexity: Medium.** One code file touched (`AIVibePanel.swift`); `PorteosScoreCalculator.swift` consumed read-only — **no formula changes in scope**. Fits Day 2 (Planning) → Day 3–5 (implement · test · manual verify). Stretch (out of default scope): staleness audit of the 11 `deal.porteosScore` write sites.

**Implementation approach (high-level):**

1. **Live-recompute the hero** — in `resultHero`, compute the composite through the same calculator path `PropertyDealViewModel(…).porteosScore.finalScore` uses, so the hero reflects current inputs (kills the staleness half of the gap).
2. **Honest bars** — label the five bars as sentiment indicators (or derive from real component inputs) so they can no longer be read as the hero's components. Presentation-only; no score-formula changes.
3. **Stretch** — audit the 11 write sites (9 recompute-via-`PropertyDealViewModel` — incl. `ResearchChatView:401`, added since the punchlist was written; 1 sample `= 78` in `PDFReportSheet:391`; 1 snapshot restore `DealHistoryManager:355`).

**Files to modify:** `AIVibePanel.swift` (only code file — `resultHero` :175–178 + `topBarSignals`/`scoreForSignal` :763–782) · `PorteosScoreCalculator.swift` (read-only) · `PropertyDeal.swift:204` only if the "show both" variant is chosen (hero = live, subtitle = last stored) · `PUNCHLIST.md` (Scoring System item → Done on completion).

**Testing strategy:** existing `PorteosScoreCalculatorTests` (6 test funcs; `testGradeBoundaries` :68) via the full 52-test xcodebuild CLI suite — with no formula changes, the calculator tests must stay green, which *proves* the fix is presentation-only · the stale `testGradeBoundaries` (stale since `67e67ee`) stays a **separate backlog item**, not part of this feature · Howard's manual in-app check on the 10 Sept Portugal deal — hero should read the live composite (a 100 is then defensible, not a contradiction, once the bars carry sentiment labels) (Week 2 learning 2: paired live verification).

**Candidates evaluated:**

| Candidate | Complexity | Verdict |
|---|---|---|
| **Score display fix (100/100 discrepancy)** | Medium | ✅ **selected** — right tier · root cause known · app-only · highest credibility impact |
| Protocol divergence (`currency` / `lat` / `long` / `locationFullAddress` missing from payload :107–128) | Medium-High | rejected — latent: 8 Sept live import worked (server derives currency/geo server-side, D1–D2); cross-codebase (extension + server + 14-field `DealIngestionPayload`); needs live re-test |
| Title-bar diacritics fix | Trivial | rejected — cosmetic, below medium tier (Week 2 Day 2 live-test nit: macOS window title "Marco Cabaco" vs in-app "MARCO CABACÇO") |

**Day 1 findings (corrections to prior docs):** punchlist hero line `:174` → `:178` (stale — `:174` is blank) · `deal.porteosScore` write sites = **11**, not the punchlist's 7 · `PorteosScoreCalculator.swift` = 126 lines, not 113 · `DealIngestionPayload` (`DealIngestionServer.swift:107–128`) = 14 fields incl. `images` — the D3 gap is that the v5 scrapers never *emit* it, not a missing struct field · PUNCHLIST status synced (drift guard).

**Template reference (original brief, kept for the archive):**

**Example features:**
- Add new property type
- Add new market benchmark city
- Add new calculator metric
- Enhance dashboard view
- Add email parsing rule

**Deliverable:** this documented selection, committed + pushed · next: Day 2 Planning (2 h) — `AIVibePanel` + calculator call graph, change list, test plan · pending: Howard's confirmation of the selection (box above).

---

### Day 2: Planning (Target: 2 hours)

**Status: ✅ Day 2 COMPLETE (Sat 12 Sept 2026)** — implementation plan ready for Day 3 execution.

- [x] Read relevant documentation for your feature
- [x] Identify files that need changes
- [x] List affected components:
  - [ ] Models? — no schema changes
  - [ ] Calculators? — read-only (PorteosScoreCalculator)
  - [ ] Services? — no
  - [ ] ViewModels? — read-only (PropertyDealViewModel.porteosScore computed property)
  - [x] Views? — YES: AIVibePanel.swift only
- [x] Sketch implementation approach
- [x] Identify potential risks
- [x] Write test plan

**Deliverable:** Implementation plan (below)

---

## Week 3 Day 2: Implementation Plan — AI Vibe Score Display Fix

**Feature:** Fix hero/bars discrepancy (hero 100/100 vs bars ≈84 sentiment average)

**Root Cause (confirmed via code inspection):**

The AI Vibe panel displays two independent quantities side-by-side that the user reads as related:

1. **Hero score** (`AIVibePanel.swift:178`): reads **cached** `deal.porteosScore` (Optional<Double> stored property on PropertyDeal model :204). This value is written from 10+ locations across the app and can become stale relative to current deal inputs.

2. **Signal bars** (`AIVibePanel.swift:775-782`): derived from LLM **sentiment** via a positional formula:
   - `positive = min(99, 88 + index)` → 88, 89, 90, 91, 92
   - `neutral = 75 + index` → 75, 76, 77, 78, 79
   - `warning = max(45, 68 - index * 2)` → 68, 66, 64, 62, 60
   - `critical = max(25, 42 - index * 3)` → 42, 39, 36, 33, 30

The bars have **no arithmetic relation** to the composite score — they visualize sentiment only. The observed 100 vs ≈84 gap is a **presentation category error** (two different metrics shown without clarification) possibly compounded by hero staleness.

---

### Files Requiring Changes

**Primary (code changes):**

1. **`PorteosIntelligence/Views/Components/AIVibePanel.swift`** (1,149 lines)
   - `resultHero` function (:175-178) — swap cached `deal.porteosScore` for live computation
   - `topBarSignals`/`scoreForSignal` (:763-782) — add "SENTIMENT" label prefix or derive from real components
   - Stretch: add breakdown tooltip showing base + bonuses/penalties

**Read-only (reference for live computation):**

2. **`PorteosIntelligence/ViewModels/PropertyDealViewModel.swift`**
   - Line 119-137: `porteosScore` computed property — this is the live calculation path
   - Instantiate a ViewModel from the deal to get `.porteosScore.finalScore`

3. **`PorteosIntelligence/Calculators/PorteosScoreCalculator.swift`** (126 lines)
   - Reference for understanding saturation (:55-56), bonuses (:64-107), clamp (:109)
   - No changes — the formula is correct

**Documentation (status update on completion):**

4. **`PUNCHLIST.md`** (root)
   - Move Scoring System item (:67-88) from current status to Done section

---

### Component Analysis

**Models:** No changes. `PropertyDeal.porteosScore` remains as stored Optional<Double> for historical/snapshot purposes (e.g. `DealHistoryManager:355` snapshot restore). The fix makes the hero ignore the cached value in favor of live computation.

**Calculators:** Read-only. `PorteosScoreCalculator.calculate()` is the source of truth; no formula changes.

**Services:** Not involved.

**ViewModels:** Read-only. `PropertyDealViewModel.porteosScore` already implements the live calculation — we just need to call it from the view layer.

**Views:** `AIVibePanel.swift` only. Changes are local to the AI Vibe panel; no ripple to dashboards, sheets, or inspector.

---

### Implementation Approach

**Option A: Live Hero + Sentiment-Labeled Bars** (recommended — lowest risk, highest clarity)

1. **Live hero computation** (`:175-178`):
   - Replace `deal.porteosScore` with live calculation:
   ```swift
   let vm = PropertyDealViewModel(deal: deal)
   let liveScore = vm.porteosScore.finalScore
   let scoreText = "\(Int(liveScore.rounded()))"
   ```
   - This ensures the hero always reflects current deal inputs (no staleness)
   
2. **Honest bar labels** (`:767`):
   - Prefix each bar label with "SENTIMENT:" or use a section header "LLM Sentiment Signals"
   - Keep the sentiment formula (:775-782) unchanged — it correctly represents LLM confidence
   - User now understands the bars are **not components** of the hero

3. **Visual separation** (optional enhancement):
   - Add a subtle divider or spacing between hero and bars
   - Add a subtitle under hero: "Composite Score (live)" vs bars section header "Sentiment Analysis"

**Option B: Show Both (cached + live)** — if we want to preserve visibility into staleness for debugging

- Hero main: live score (as in Option A)
- Hero subtitle: `"Last stored: \(cachedScore)"` when they differ by > 5 points
- Bars: keep sentiment labels (as in Option A)

**Option C: Component-Derived Bars** — higher complexity, deferred to backlog

- Replace sentiment formula with real component scores (capRate, revPAR, design, circular, weighted)
- Requires redesign of bar semantics (not just a label change)
- Out of scope for Week 3 Medium task

**Selected approach: Option A** — lowest risk, clearest user communication, fits Medium complexity tier.

---

### Risks & Mitigations

**Risk 1: Performance**
- **Concern:** Live computation on every view redraw (PropertyDealViewModel instantiation + calculator call)
- **Mitigation:** The calculator is 126 lines of pure arithmetic (no I/O, no async). Tested implicitly via 52-test suite; realistic deal count in UI = 1-20 visible, not thousands. If profiling shows slowdown, add `@State` cached computation that invalidates on deal changes.
- **Severity:** Low (calculator is trivial cost)

**Risk 2: ViewModel Instantiation Pattern**
- **Concern:** AIVibePanel creates its own ViewModel instance instead of receiving one from parent
- **Current state:** The panel takes `deal: PropertyDeal` as a binding; it does not currently have access to a ViewModel
- **Mitigation:** Instantiate `PropertyDealViewModel(deal: deal)` locally within `resultHero`. This is safe — ViewModels in this codebase are stateless read-only wrappers (confirmed by grep: no `@Published`, no side effects in computed properties).
- **Severity:** Low (pattern is consistent with read-only ViewModel usage)

**Risk 3: Grade Display**
- **Concern:** Hero also shows `r.grade.hexColor` — does this come from cached score or live analysis?
- **Investigation:** Line 176 reads `r.grade` where `r` is `AnalysisResult` (LLM response). The grade is part of the AI analysis text, not the composite calculator. No change needed — grade remains tied to the LLM verdict (correct behavior).
- **Severity:** None (grade is separate from score, intentionally)

**Risk 4: Test Coverage**
- **Concern:** No direct tests for AIVibePanel UI (it's a view, not a calculator)
- **Mitigation:** Existing `PorteosScoreCalculatorTests` (6 test functions, 52-test suite) covers the scoring logic. The view change is presentation-only. Manual verification via Howard's in-app check on the Portugal deal (100 should remain 100, now defensible with live calculation + sentiment labels).
- **Severity:** Low (formula unchanged, tests stay green)

**Risk 5: Staleness Elsewhere**
- **Concern:** 11 write sites for `deal.porteosScore` may still be reading stale values in other UI areas
- **Out of scope:** This fix targets AI Vibe panel only. A full staleness audit (Day 1 "stretch goal") is tracked separately in backlog.
- **Mitigation:** Document the 11 write sites (including `PDFReportSheet.swift:391` hardcoded `= 78` fake-value write); flag for future audit if other panels show similar discrepancies.
- **Severity:** Medium (known debt, not blocking this fix)

---

### Test Plan

**Automated Tests (must stay green):**

1. **`PorteosScoreCalculatorTests.swift`** (6 test functions)
   - Run full 52-test suite via `xcodebuild test` (CLI, since IDE test discovery is quirky per Week 2 Day 5)
   - Expected: **52 passing tests, 0 failures** (except pre-existing `testGradeBoundaries` stale assertions — tracked separately in backlog)
   - Rationale: No calculator changes = no test changes. Green suite proves the fix is presentation-only.

2. **Build verification**
   - `xcodebuild -project PorteosIntelligence.xcodeproj -scheme PorteosIntelligence -destination 'platform=macOS' build`
   - Expected: **BUILD SUCCEEDED**
   - Gate per `zero-defect-quality.mdc` — no Swift syntax/type errors introduced

**Manual Verification (Howard in-app):**

3. **Portugal deal check** (10 Sept reference case)
   - Precondition: Deal with capRate ≥ 10%, unpopulated profiles (weights redistributed), bonuses stacking → legitimate 100 composite
   - **Before fix:** Hero reads cached `deal.porteosScore` = 100, bars show 88/89/90/62/92 (sentiment formula)
   - **After fix:** Hero shows **live 100** (recomputed), bars **labeled as "SENTIMENT"** or equivalent
   - **Pass criteria:** User can now understand why 100 ≠ 84 (different metrics, not an error)

4. **Edge cases**
   - Deal with `porteosScore = nil` (never scored): hero displays live-computed value (likely low for empty inputs, since `finalScore` is non-optional). The "—" fallback is intentionally retired — all deals now show a number.
   - Deal with low score (e.g. 35, grade D): verify live computation matches expected calculator output
   - Deal with stale cached score: edit deal inputs (e.g. change capRate), verify hero updates immediately (proves live computation)

5. **Visual QA**
   - Verify hero font/color unchanged (DesignTokens compliance per `project-rules.mdc`)
   - Verify bar labels fit layout (no truncation with "SENTIMENT:" prefix)
   - Verify no layout shifts or spacing regressions

**Acceptance Criteria:**

- [ ] Build succeeds (no Swift errors)
- [ ] 52-test suite passes (calculator unchanged)
- [ ] Portugal deal hero = 100 (live), bars labeled as sentiment (not components)
- [ ] Nil-score deal computes hero live (no "—" fallback)
- [ ] Edited deal inputs update hero immediately (proves live)
- [ ] Visual compliance (DesignTokens, no layout regression)

**Out of Scope (tracked in backlog):**

- `testGradeBoundaries` fix (pre-existing stale test, separate item)
- Full staleness audit of 10+ `deal.porteosScore` write sites
- Component-derived bars (Option C above)
- Breakdown tooltip showing base + bonuses/penalties

---

**Estimated Implementation Time:**

- Day 3: Core changes (hero live computation + bar labels) — 2-3 hours
- Day 4: Testing (automated suite + manual verification) — 2 hours  
- Day 5: Documentation + PUNCHLIST update — 1 hour

**Total: 5-6 hours** (well within Day 3-5 target of 6-8 hours)

**Files Modified (predicted Day 3 diff):**

- `AIVibePanel.swift` (+8 / -2 lines — hero logic + bar label prefix)
- `HANDOVER_CHECKLIST.md` (Day 3 status)
- `PUNCHLIST.md` (Scoring System → Done)

**No Changes:**

- `PorteosScoreCalculator.swift` (read-only)
- `PropertyDealViewModel.swift` (read-only)
- `PropertyDeal.swift` (model unchanged)
- Test files (suite must stay green as-is)

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
- Week 1 complete: 6 September 2026
- Week 2 complete: 11 September 2026
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

### Sept 9 — Day 3 complete (handover takeover)

- **Handoff discrepancy discovered + recovered:** the predecessor's handover claimed Day 3 was "complete, committed, and pushed" at commit `652562d` — verified **false** this session (`git cat-file -t 652562d` → no such object; `origin/main` = `3087698`). Tree reality: uncommitted real changes in exactly the 2 files described (VM + prompts), but **non-compiling** — they referenced a `Currency` enum + `currencyCode` property the predecessor claimed to have written but never did; no checklist update; no commit. Predecessor's VM + prompt edits were correct — kept; this session supplied the missing `Currency` source.
- **What was done:** (1) top-level `enum Currency` in `Models/PropertyDeal.swift` — single classifier returning `(symbol, code)` pairs, if-chain byte-identical to the old `currencySymbol`, plus `symbol(forCountry:marketId:)` / `code(forCountry:marketId:)` wrappers; `currencySymbol` now delegates, new `currencyCode` beside it (name-collision grep clean — no pre-existing `Currency` type or `currencyCode` property). (2) predecessor's edits re-verified and kept — `PropertyDealViewModel` :164/:168 → `.currency(code: deal.currencyCode)`; `LLMAnalysisService` benchmark :507–518 → `Currency.symbol(forCountry: bm.country)`, research example :660/:665 → `deal.currencySymbol`. **`€` count now 0 in both in-scope files** (the 4 remaining in PropertyDeal.swift are the enum's own fallback + doc comments + one pre-existing field comment).
- **Static-trace evidence:** "Portugal" matches no country branch; marketId prefix misses → `("€","EUR")` — behavior unchanged, consistent with Day 1 live evidence (Portugal deal displays EUR) + Day 2 live import. A US deal now resolves `$`/`USD` end-to-end (VM + prompt) — closes F3; the N3 `€`-fallback now exists in exactly one place.
- **Build:** `xcodebuild -project PorteosIntelligence.xcodeproj -scheme PorteosIntelligence -destination 'platform=macOS' build` → **BUILD SUCCEEDED** (headless — predecessor's "not buildable headless" claim was wrong).
- **Scope guard:** ViewModel + LLM prompts only, per user instruction. Remaining hardcoded-`€` sites (AIAnalysisService 10 · DealResearchImporter 19 · DealPreloader :260/:264–265 · QuickAddSheet :422–423 · GlobalIntelligenceInspectorViews :360–370) listed in the Day 3 section as follow-ups — **not** fixed.
- ✅ Checklist v1.4: Day 3 section re-titled + rewritten (boxes checked, `Currency` decision, follow-ups with corrected counts, pending Phase 2 docs note); Week 2 checkpoint — "AI prompt modified" **checked** *(my call, flagged: Day 3 literally modified prompts; Day 4's separate SWOT exercise remains pending)*.
- **Commit:** exactly 4 files (PropertyDeal.swift, PropertyDealViewModel.swift, LLMAnalysisService.swift, HANDOVER_CHECKLIST.md); the 3 dirty Xcode user files (xcuserstate / xcscheme / xcschememanagement) excluded — tree otherwise unchanged.
- **Next: Day 4 — SWOT prompt exercise** (awaiting user instruction). Week 2 checkpoint: 3/6.

---

### Sept 10 — Day 4 complete (handover takeover)

- **Scope re-scoped by user (Sept 10):** planned Day 4 (SWOT prompt exercise) → debugging practice (bug in `capRate`); the SWOT task moved to Day 5. The debugging work was executed Sept 10 by the prior agent; this takeover verified its claims against the repo and finished the checklist.
- **The exercise:** (1) target = `capRate` @ `RealEstateCalculator.swift:153`; (2) bug = removed `* 100` — the cap rate silently becomes a fraction (0.07 instead of 7.0), no crash; (3) failing test = temp `testCapRate` in `RealEstateCalculatorTests.swift` (€10,000,000 purchase price, 10% vacancy → NOI €700,000 ⇒ expect 7.0).
- **RED (real `xcodebuild test` run):** 20 tests executed; `testCapRate` fails `7.0 != 0.07`; the only other failing case is `testGradeBoundaries` (pre-existing — see below).
- **Debugger walkthrough (Xcode):** breakpoint at :153; inspect `noi = 700,000` / `purchasePrice = 10,000,000` / `capRate = 0.07` → the ratio is correct (700k/10M) but the percent scale is missing — a silent-wrong-value bug, exactly the class the exercise targets.
- **Fix:** restored `* 100` — both files then byte-identical vs `82b8765` (`git diff` empty).
- **GREEN:** 20 tests executed; `testCapRate` passes (0.000s); the only failing case remains `testGradeBoundaries`.
- **Pre-existing failure found during RED/GREEN (re-verified by this takeover):** the only failing case is `testGradeBoundaries` (`PorteosScoreCalculatorTests.swift` ~:68) — 3 stale assertions (60→B, 40→C, 20→D) still encode the pre-`67e67ee` 60/40/20 scale; 80→A + 19→F still pass. The calculator is **not** stale: `PorteosScoreCalculator.swift:117–125` = 80/65/50/35 ("matches VibeGrade.from() — was 60, now 65") and the app's live scale `AIAnalysisService.swift:33–39` = 80/65/50/35; commit `67e67ee` (Fri Jul 31, 2026) is the realignment. **Day 5 fix = update the test to the 80/65/50/35 boundaries — not the calculator.**
- **Prerequisite milestone — scheme test-action mystery solved:** the CLI error "not configured for the test action" comes from Xcode auto-creating an *empty* test plan (`shouldAutocreateTestPlan=YES` + `LastUpgradeCheck=2660`) that replaces the TestableReference. Durable one-line fix (Howard): Xcode ▸ Edit Scheme ▸ Test tab → uncheck *Automatically create test plans* (or `shouldAutocreateTestPlan="NO"` in the scheme XML). Tail anomaly: the 01:49 final probe (`.build/day4-probe.log`, 458 B) still hit the error even with autocreate=NO + TestableReference present — unresolved, but the earlier successful probe runs stand and Howard's fix is unaffected.
- **Mach-o runner dead-end:** one alternative — dlopen-ing the test bundle after an MH_EXECUTE→MH_BUNDLE patch — loaded, but died on two-level namespace binding. Dead end, no further pursuit.
- **Revert:** `git restore` on `RealEstateCalculator.swift` + `RealEstateCalculatorTests.swift` (no `testCapRate` remains); `git diff` vs `82b8765` empty on both; never committed. The untracked handover probe scheme (`HandoverDay4Probe.xcscheme`) was deleted by this takeover to complete the full revert; Howard's scheme + the 3 dirty Xcode user files untouched.
- **Evidence note:** the prior agent's `verify_math` fallback is superseded by these real test runs.
- ✅ Checklist v1.5: Day 4 section rewritten (debugging practice — 8 boxes, complete); Day 5 re-titled to the moved SWOT task + bonus `testGradeBoundaries` box; Week 2 checkpoint: 4/6.
- **Commit:** `HANDOVER_CHECKLIST.md` only (3 dirty Xcode user files excluded).
- Next: Day 5 — SWOT prompt customization + `testGradeBoundaries` fix (awaiting user instruction).

---

### Sept 11 — Day 5 complete: Week 2 closed (handover takeover)

- **Day 5 re-scoped by user (Sept 11):** planned Day 5 (SWOT prompt exercise) → Review & Consolidation, the final day of Week 2. SWOT exercise + `testGradeBoundaries` fix not performed — recorded in the Day 5 carry-over backlog, not dropped.
- **Consolidation performed:** Week 2 section re-read (Days 1–5 + checkpoint + Sept 7–11 logs); all 6 checkpoint boxes now checked ("All Phase 2 docs read" + "Confidence level" per user, with honest annotations — 3 of 5 doc groups read, CALCULATOR_SYSTEM + MULTI_WINDOW_SYSTEM in backlog); 5-bullet retrospective added; tracking dates filled (Week 1: Sept 6; Week 2: Sept 11).
- **Footer correction:** user instruction said "update footer to v1.4" — footer was already v1.5 since Day 4; bumped forward to **v1.6** (a version regression would have corrupted the history the logs describe).
- **Week 2 by the numbers:** 5 days · 6 commits (`c2b0fe7` · `16ca921` + `3087698` · `82b8765` · `f2f5596` · `715efe7`) · 21 documented findings (5 code + 6 obs Day 1; 20 M/D/G/H/I Day 2; 5-site € follow-up list Day 3) · 1 durable refactor (`Currency` enum) · 1 test-run mystery solved · 1 punchlist entry (Scoring System — hero 100 vs ≈84 component average; fix deferred Week 5+).
- **Commit mechanics:** agent shell dead this session (zsh ENOENT, retried) — Howard ran `git add HANDOVER_CHECKLIST.md && git commit && git push` in his terminal per the exact commands handed over; 3 dirty Xcode user files excluded as always.
- **Next: Week 3 — Independent Development.** Pick ONE feature from PUNCHLIST.md (recommend Medium complexity). Suggested first candidates from Week 2 backlog: `testGradeBoundaries` fix (small) or the Scoring System display (Medium — already investigated: bars are a sentiment formula, the hero is saturation + bonuses + clamp; punchlist has the analysis).

---

**Version:** 1.8 (Sept 12, 2026)  
**Last updated by:** Cursor Agent (Week 3 Day 2 — planning complete: implementation plan for AI Vibe score display fix)
