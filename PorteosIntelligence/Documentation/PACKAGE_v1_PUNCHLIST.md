# Porteos Intelligence — Package v1.0 Punchlist

**Created:** 4 July 2026  
**Purpose:** Return here after using Porteos Intelligence in the wild.  
**Status key:** `[ ]` open · `[~]` in progress · `[x]` done · `[—]` deferred / won’t fix v1

**Companion:** [`PACKAGE_v1_STATUS.md`](PACKAGE_v1_STATUS.md)

---

## Wild-use log (fill in during / after field use)

| Date | Area | Observation | Severity | Promoted ID |
|------|------|-------------|----------|-------------|
| 2026-07-05 | Email monitor | TEST_CONNECTION OK (Gmail app password works); CHECK_NOW fails curl exit **100** on `SEARCH UNSEEN` | major | P6-17 |
| 2026-07-05 | Browser import | Casa Guerra Junqueiro — purchase price **€0.00**; price not pulled from listing | major | P7-05 |
| 2026-07-05 | Full Edit — Base | Browser import notes show `Source: BROWSER_EXTENSION` only; **listing URL not visible** in edit UI | minor | P7-06 |
| 2026-07-05 | Email Setup | Need **show/hide password** toggle on app-password field | minor | P6-19 |
| 2026-07-05 | PDF Report | **Black & white mode** toggle present but output not built out | minor | P3-07 |
| 2026-07-05 | Navigation pane | **Arrow-key nav** — need ↑↓ between profile links (REAL ESTATE, etc.) and deal rows; ←→ or focus handoff between columns | minor | P1-08 |
| 2026-07-05 | Deal list | **Duplicate PIPELINE rows** — e.g. two “LISBON OFFICE BLOCK A”, two “SEMI-DETACHED HOUSE…”; tighten dedup on import | major | P7-07 |
| 2026-07-05 | ComparisonView | OPEX panel floated centered in scroll, read-only €0 fields, no deal label | major | P2-09 |
| 2026-07-05 | ComparisonView OPEX | Input fields capped at ~**2 digits** (88pt + NumberFormatter) — can't enter e.g. €2,400 | major | P2-09 |
| 2026-07-08 | Global Intelligence | Help menu shows system *“Help isn't available”* alert | minor | P4-05 |
| 2026-07-08 | Global Intelligence | Wrong pin when deal lacks city/address (e.g. sample deal in Sweden) | major | P10-11 (fixed sample + geocode UX) |
| 2026-07-09 | Global Intelligence | Pin hover showed duplicate banners (.help tooltip + custom card) | minor | fixed — hover-only banner |
| 2026-07-09 | Deal list | Duplicate **LISBON OFFICE BLOCK A** rows still in PIPELINE | major | P7-07 |

**Severity:** blocker · major · minor · cosmetic · idea

---

## PKG — First package / release engineering

| ID | Task | Status | Notes |
|----|------|--------|-------|
| PKG-01 | App icon in `AppIcon.appiconset` | `[x]` | 1024 + all macOS slots (2026-07-04) |
| PKG-02 | Confirm version/build in Xcode (1.0 / 1) | `[x]` | Confirmed: MARKETING_VERSION=1.0, CURRENT_PROJECT_VERSION=1 Jul 12 | `MARKETING_VERSION` already 1.0 |
| PKG-03 | Clean git tree + tag `v1.0.0-wild` after icon commit | `[ ]` | Exclude `.DS_Store`, `xcuserstate` |
| PKG-04 | Archive → Export `.app` for personal install | `[~]` | See `Documentation/DISTRIBUTION.md` |
| PKG-05 | Smoke test on clean machine (fonts load, SwiftData, server port) | `[ ]` | |
| PKG-06 | Document default ingestion port + firewall note | `[x]` | Default `:9000` in DISTRIBUTION.md |
| PKG-07 | Browser extension: load-unpacked instructions | `[x]` | DISTRIBUTION.md |
| PKG-08 | Optional: CI typography gate | `[ ]` | `./scripts/typography-check.sh` |
| PKG-09 | Developer ID + notarization (no App Store) | `[~]` | `./scripts/export-wild-release.sh` |

---

## P0 — Blockers / data corruption / crash

| ID | Area | Issue | Status |
|----|------|-------|--------|
| P0-01 | PDF cover | KPI block overlap | `[x]` |
| P0-02 | Full Edit — Circular | `tCO2e/yr` suffix overlap | `[x]` |
| P0-03 | Full Edit — Design | `ACH` unit wrap | `[x]` |
| P0-04 | Server Config | Broken port spacing in URLs | `[x]` |
| P0-05 | *(wild-use)* | | `[ ]` |
| P0-06 | *(wild-use)* | | `[ ]` |

---

## P1 — Shell & navigation polish

| ID | Area | Issue | Status | Target |
|----|------|-------|--------|--------|
| P1-01 | Nav header | `./NAV_V2` path label | `[x]` | |
| P1-02 | Nav sections | `// NAVIGATION` meta-bold | `[x]` | |
| P1-03 | Nav footer | Bulk export row vs Figma nav footer | `[ ]` | `img_00_21` left column |
| P1-04 | Filter panel | Advanced filter visually “admin” | `[ ]` | `AdvancedFilterPanel` spacing/layout |
| P1-05 | Detached inspector | Empty horizontal margins | `[x]` | frame(maxWidth: inspectorPaneWidth) in DetachedPaneViews Jul 10 | `DetachedPaneViews` width cap |
| P1-06 | Deal rows | Right column: cap rate vs status chip | `[ ]` | Figma `img_00_22` |
| P1-07 | HTTP endpoint display | `monospacedDigit` on full URL line | `[ ]` | Server Config / nav status |
| P1-08 | **Keyboard nav (↑↓ ←→)** | Navigate **profile links** and **deal rows** in left pane with arrow keys; terminal-style focus ring + selection pip follows keyboard. Document in shortcuts legend. | `[ ]` | Wild-use 2026-07-05 |

---

## P2 — Sheets & Full Edit

| ID | Area | Issue | Status | Target |
|----|------|-------|--------|--------|
| P2-01 | Full Edit tab bar | Bracket / segment bar style | `[ ]` | `TerminalSegmentBar`, `img_00_11` |
| P2-02 | Section headers | `// SECTION` meta-bold | `[~]` | Sweep remaining tabs |
| P2-03 | Field grid | Tighter terminal blocks | `[~]` | 12pt section rhythm |
| P2-04 | Template Picker | Reference finish level | `[x]` | Use as sheet gold standard |
| P2-05 | Footer cancel | `[ CANCEL ]` outlined | `[x]` | |
| P2-06 | Sheet chrome | macOS rounded sheet corners | `[ ]` | `.presentationBackground` / overlay pattern |
| P2-07 | Legacy sheets | Deprecate or align `EditDealSheet` / `NewDealSheet` / `QuickAddDealSheet` | `[~]` | `QuickAddDealSheet` deleted Jul 28 (dead). `EditDealSheet` still used in NavigationPane context menu; `NewDealSheet` in DetachedPaneViews. Route both through `FullDealEditSheet` in v1.2. |
| P2-08 | Full Edit — Base | **Source URL field** — browser/email imports store URL in notes; expose as dedicated row (link or copy) in BASE tab, not buried in NOTES blob | `[x]` | `ListingURLHelpers` + BASE tab link row |
| P2-09 | **ComparisonView OPEX panel** | `[~]` Fixed layout + editable fields 2026-07-05; **fixed 2-digit input cap** same day (`OpexInlineAmountField`). **Follow-up:** OPEX per deal column; pre-fill from `operatingExpenses` | `[~]` | Wild-use |

---

## P3 — PDF report

| ID | Area | Issue | Status |
|----|------|-------|--------|
| P3-01 | PDFReportSheet UI | Ghost/double text at deal info block edge | `[ ]` |
| P3-02 | Sheet chrome | Rounded corners | `[ ]` |
| P3-03 | PDF cover output | Overlap | `[x]` |
| P3-04 | PDF page 3+ | Field mapping (e.g. GFA `400000 m²`) | `[ ]` | Data vs display |
| P3-05 | B&W mode | Untested output | `[—]` | Superseded by P3-07 (done) | Superseded by P3-07 build-out |
| P3-06 | External share | Cover KPI spacing OK for send-out | `[ ]` | Re-verify after wild PDFs |
| P3-07 | **B&W mode build-out** | Toggle exists in `PDFReportSheet` but output not fully implemented — user note: “Need to build this out”. Wire `blackAndWhite` through `PDFReportGenerator`; verify print-safe contrast. | `[x]` | `c()` greyscale resolver verified in `PDFReportGenerator` Jul 10 |

---

## P4 — Admin / secondary surfaces

| ID | Surface | Issue | Status |
|----|---------|-------|--------|
| P4-01 | Server Config / Ingestion panel | Typography migrated; layout pass | `[~]` | Post-typography sweep |
| P4-02 | Email Setup / Ingestion panel | Same | `[~]` | + P6-19 show password |
| P4-03 | Settings | Legacy layout pass | `[ ]` | `SettingsView` |
| P4-04 | Command palette / shortcuts legend | Visual parity | `[ ]` | Low priority |
| P4-05 | **macOS Help menu** | Help → shows system alert *“Help isn't available for PorteosIntelligence”* — no Help Book bundled. Wire ⌘? / menu item to in-app help (shortcuts legend + profile overview) **or** ship `.help` bundle + `CFBundleHelpBookFolder` in Info.plist. | `[—]` | Wild-use 2026-07-08; defer post-v1 |

---

## P5 — Visual QA backlog (PNG targets)

| Ref | Screen | Status | Notes |
|-----|--------|--------|-------|
| `img_00_20` | Shell — idle inspector | Partial | |
| `img_00_21` | Shell — deal selected | Partial | Inspector ✅; nav gap P1 |
| `img_00_11` | Full Edit sheet | Functional | P2 finish |
| `img_00_12` | Comparison | `[x]` | `bcc1b10` |
| `img_00_16` | PDF Report sheet | Good | P3-01 ghost text |

---

## P6 — Email feed (anti-scraper) — **post–wild-use epic**

**Goal:** Passive deal intake from Gmail (broker alerts, listing notifications) instead of scraping Idealista/Zillow/Hemnet. Aligns with “email feed mechanism” product direction.

### Current scaffold (do not rewrite blindly)

| Component | File | What it does |
|-----------|------|--------------|
| IMAP credentials + Keychain | `EmailMonitorService.swift` | Gmail/Outlook presets, poll interval |
| Poll + import loop | `EmailMonitorService` | curl IMAP fetch → parse → SwiftData |
| Email parser | `ListingEmailParser.swift` | Extract deal fields from email body |
| Import audit | `EmailImportRecord.swift` | Dedup / history |
| UI | `EmailSetupSheet.swift`, `EmailIngestionPanel.swift` | Configure + status |

### Product decisions (decide after wild use)

| ID | Decision | Options |
|----|----------|---------|
| P6-01 | Auth model | App password + IMAP (now) vs Gmail OAuth + API |
| P6-02 | Trigger model | Poll (now) vs Gmail push (Pub/Sub) vs dedicated alias |
| P6-03 | Mailbox strategy | Label/filter `Porteos/Inbound` vs full INBOX vs forward-to-parse |
| P6-04 | Parser scope | Which brokers / languages / HTML templates v1 must support |
| P6-05 | Dedup key | URL vs address hash vs message-id |
| P6-06 | Failure UX | Quarantine unparseable emails vs silent skip vs manual triage queue |
| P6-07 | Security | Keychain ✅; document Gmail “App Password” setup; no plaintext logs |

### Implementation tasks (when prioritized)

| ID | Task | Status |
|----|------|--------|
| P6-19 | **Show/hide password** toggle on `EmailSetupSheet` app-password field (verify paste, no Keychain plain-text log) | `[x]` | Wild-verify Jul 9 |
| P6-17 | **Fix CHECK_NOW curl exit 100** — bounded `SEARCH UNSEEN SINCE` + fallback `SEARCH SINCE`; surface last-result summary in UI. Wild-verify after Idealista alerts resume. | `[~]` | Code complete Jul 9 — pending live Gmail test |
| P6-18 | Improve IMAP error messages — map exit 67 → “login denied / check app password”, 100 → “inbox query too large or unsupported” | `[x]` | `humanReadableCurlError()` Jul 10 |
| P6-10 | Wild-test IMAP with real Gmail + 10 broker emails | `[~]` | Auth OK 2026-07-05; blocked on P6-17 |
| P6-11 | Parser golden fixtures per broker template | `[ ]` |
| P6-12 | Batch triage integration for email imports | `[ ]` |
| P6-13 | Badge / toast parity with HTTP ingestion | `[ ]` |
| P6-14 | Rate limits + backoff (Gmail IMAP) | `[ ]` |
| P6-15 | Optional: Gmail API migration spec | `[—]` |
| P6-16 | Deprioritize browser scraper paths if email wins | `[—]` | Product call |

### Anti-scraper rationale (for future you)

- Listing sites change DOM → extension breaks.
- Email alerts are **broker-authorized**, structured-ish, and arrive without headless browser risk.
- Same `ListingEmailParser` pipeline can feed Batch Triage as HTTP ingestion does today.

---

## P7 — Ingestion HTTP + browser extension

| ID | Task | Status | Notes |
|----|------|--------|-------|
| P7-01 | Localhost server stable under sandbox | `[x]` | Working 2026-07-05 (port conflict if multi-instance) |
| P7-02 | Extension POST payload schema documented | `[ ]` | Match `DealIngestionServer` |
| P7-03 | Idealista / Zillow / Hemnet DOM drift | `[ ]` | Per-site maintenance |
| P7-04 | Extension icons + Chrome Web Store | `[—]` | If public distribution |
| P7-05 | **Pull purchase price from listing** — browser extension import landed Casa Guerra Junqueiro at **€0.00**; fix `content.js` scrape + `DealIngestionPayload.purchasePrice` mapping | `[x]` | `parsePrice` + JSON-LD fallback |
| P7-06 | **Source URL in deal model/UI** — URL written to notes today; add first-class field or BASE tab row so imports are traceable without parsing NOTES | `[x]` | BASE tab link row |
| P7-07 | **Duplicate deals on import** — same listing imported twice (e.g. Lisbon Office Block A ×2, Semi-Detached ×2 in PIPELINE). Harden dedup: URL hash in `DealIngestionServer` + email `EmailImportRecord`; surface “duplicate skipped” in nav | `[~]` | URL-hash dedup works for imports with URL. Manual entries and partial imports (no URL) still bypass dedup — gap remains. |

---

## P8 — Data & calculators (only if wild use finds bugs)

| ID | Task | Status |
|----|------|--------|
| P8-01 | Verify calculator outputs vs spreadsheet for 1 RE deal | `[ ]` |
| P8-02 | Scenario save/load edge cases | `[ ]` |
| P8-03 | Market benchmark wrong city alias | `[ ]` |
| P8-04 | SwiftData export before schema change | `[ ]` |
| P8-05 | **Expand MarketBenchmarks PT coverage** — add Braga, Coimbra, Cascais/Sintra, Funchal (Madeira), Setúbal, Aveiro, Évora, Leiria. Also expand US: LA, Chicago, Miami, Dallas, Atlanta; IT: Florence, Naples; ES: Valencia, Bilbao. Enables granular benchmark-apply in AI Vibe for all value-add thesis markets. | `[x]` | 80+ cities: PT/ES/FR/UK/IT/HR/GR/US/JP expanded Jul 11 | Next version |

---

## P9 — AI / intelligence modules

| ID | Task | Status |
|----|------|--------|
| P9-01 | AI vibe panel useful on real deals | `[x]` | qwen2.5:0.5b wired; SWOT + DealVerdict added Jul 10 |
| P9-02 | LLM endpoint config + privacy note | `[x]` | Settings › INTELLIGENCE tab: endpoint, model, ping, privacy Jul 10 |
| P9-03 | Portfolio learning engine feedback loop | `[—]` | Deleted Jul 28 — 220 lines never called, no UI; removed to reduce dead code |

---

## P10 — Global Intelligence profile (6th profile) — **engineering epic**

**Goal:** Geo-anchored portfolio map + market news intelligence. Distinct from Command Center (portfolio CRM).

**Workflow:** Shipped on `main` via [PR #6](https://github.com/howard-lgtm/PorteosIntelligence/pull/6) (9 Jul 2026). Branch: `cursor/global-intelligence-3e3e` (merged).

**Design handoff (complete):** [`Design-system/Figma/Global_Intelligence/GLOBAL_INTELLIGENCE_HANDOFF.md`](../../Design-system/Figma/Global_Intelligence/GLOBAL_INTELLIGENCE_HANDOFF.md) + 6 PNG frames.

**Figma brief (original):** [`Design-system/Figma/GLOBAL_INTELLIGENCE_FIGMA_BRIEF.md`](../../Design-system/Figma/GLOBAL_INTELLIGENCE_FIGMA_BRIEF.md)

### Product decisions (8 Jul 2026)

| Decision | Choice |
|----------|--------|
| Geocoding | On **import/save only** — no backfill job; sample deals geocode when created/imported later |
| News feeds | **Universal registry** — see `MarketFeedRegistry.swift`. Launch markets below. Static RSS, daily cache, 30–60d. Topic tags tuned for **value-add / below-market** thesis. |
| Code weight | **Happy medium** — one registry file, native MapKit (`MKGeocodingRequest`) + URLSession RSS; no external map/news SDKs |
| AI briefing | **Deferred to P11** — map + news ship first; Ollama/Qwen exists locally but not wired in v1 |
| Inspector | **Hybrid** — see strategy below; no global InspectorPane refactor |

### Inspector strategy (v1)

| State | Center pane | Inspector (280px) |
|-------|-------------|-------------------|
| Idle (no pin) | Map + all-market news | `// SELECT_PIN_OR_MARKET` + market aggregate when filter active |
| Pin selected | Map + `GeoAssetContextCard` + filtered news | **Existing deal inspector** (weights / AI) — pin tap sets `selectedDealID` |
| Market focus only | Map zoomed + market-scoped news | `MarketContextInspector` — deal count, exposure, prime yield chip |

**Rationale:** Pin selection reuses the deal inspector users already know. Map-specific UI stays in the center pane (Figma). One `if activeProfile == .globalIntelligence` branch in inspector routing — no changes to RE/Hosp/Design/Circular inspectors.

### Launch markets (8 Jul 2026)

**ID convention:** `{COUNTRY}-{METRO}` — e.g. `UK-LON`, `US-NYC`, `US-LA`, `PT-ALG`

**Investment lens:** Below-market / value-add — quintas & ecotourism (PT), cheap rural stock (IT, JP akiya), distressed US metros, Mediterranean holiday conversion, Nordic yield.

| Region | Countries | Key metros |
|--------|-----------|------------|
| **Europe** | `PT` `ES` `IT` `FR` `UK` `HR` `GR` | `PT-LIS` `PT-OPO` `PT-ALG` · `ES-MAD` `ES-BCN` · `IT-ROM` `IT-MIL` `IT-RUR` · `FR-PAR` `FR-RUR` · `UK-LON` `UK-MAN` `UK-BIR` `UK-EDI` · `HR-ZAG` `HR-SPU` · `GR-ATH` `GR-ISL` |
| **Nordics** | `SE` `DK` `NO` `FI` | `SE-STO` `SE-GOT` · `DK-CPH` · `NO-OSL` · `FI-HEL` |
| **USA** | `US` | `US-NYC` `US-LA` `US-CHI` `US-MIA` `US-FLA` `US-TX` `US-DET` `US-ATL` `US-BOS` |
| **Asia** | `JP` | `JP-TYO` `JP-RUR` |

Registry: `PorteosIntelligence/Data/MarketFeedRegistry.swift` — **13 countries + 35 metros**. RSS URLs filled incrementally.

### Figma deliverables

| ID | Task | Status |
|----|------|--------|
| P10-01 | 6 reference frames @ 1200×800 | `[x]` |
| P10-02 | Terminal map overlay + pin component spec | `[x]` |
| P10-03 | News feed module + market filter bar | `[x]` |
| P10-04 | Nav integration — `GLOBAL_INTELLIGENCE` ⌘5 + header `porteos@geo` | `[x]` |
| P10-05 | AI module — 3 variants (engineering picks A for v2) | `[x]` |
| P10-06 | Handoff doc `GLOBAL_INTELLIGENCE_HANDOFF.md` | `[x]` |

### Engineering phases (v1 — map + news only)

| ID | Task | Status |
|----|------|--------|
| P10-10 | `ProfileType.globalIntelligence` + nav ⌘5 + accent `#06B6D4` + AppShell routing | `[x]` |
| P10-11 | `PropertyDeal` lat/lon/geocodeStatus + `GeocodingService` on save/import/ingest | `[x]` |
| P10-12 | `GlobalIntelligenceDashboardView` — map 60% / news 40% split | `[x]` |
| P10-13 | `GeoPortfolioMapView` — MapKit dark + square pins + zoom controls | `[x]` |
| P10-14 | `MarketFeedRegistry` — PT/ES/IT/FR/UK/HR/GR + Nordics + US metros + JP (value-add thesis) | `[x]` |
| P10-15 | `NewsAggregatorService` — daily fetch, JSON disk cache, 30–60d filter | `[x]` |
| P10-16 | `MarketNewsFeedModule` + filter bar + accordion rows | `[x]` |
| P10-17 | Pin tap → `selectedDealID` + `GeoAssetContextCard` + scoped news | `[x]` |
| P10-18 | Inspector routing — idle / market context modes for GI profile only | `[x]` |
| P10-19 | Geocode-empty state + `[ GEOCODE NOW ]` on pending imports | `[x]` |
| P10-20 | Settings › **Intelligence** tab — sector keyword overrides, headline preview tester, reset-to-defaults (JSON in Application Support) | `[—]` | User note 2026-07-08; defer |
| P10-21 | **Map pin hover banner** polish — show deal `status` (e.g. PIPELINE), Porteos **grade letter**, keep banner visible while pin **selected** (not hover-only) | `[x]` | `GeoPinHoverBanner` 2026-07-09 |

### Anti-scope (v1)

- Live GPS / device location tracking  
- Real-time news ticker  
- ChatGPT-style conversational agent as primary UI  
- Replacing Command Center  
- Ollama / LLM briefing (→ P11)  
- Backfill geocode for existing deals  

---

## P11 — Integrated LLM onboarding (deferred — revisit after P10 ships)

**Context:** Ollama + Qwen already on dev machine. Decide how intelligence is delivered app-wide, not only in Global Intelligence.

| ID | Decision / task | Status |
|----|-----------------|--------|
| P11-01 | **Architecture choice:** baked-in service vs optional plugin vs Settings-toggle provider | `[ ]` |
| P11-02 | `IntelAgentService` — abstract `LLMProvider` protocol (Ollama, future cloud) | `[ ]` |
| P11-03 | Settings surface — endpoint, model name (`qwen` / `llama3.2:3b`), privacy footer | `[x]` | Settings › INTELLIGENCE tab: endpoint, model, ping, privacy Jul 10 |
| P11-04 | Global Intelligence Variant A — `03 // DAILY_INTEL_BRIEF` + `[ REGENERATE ]` | `[x]` | IntelBriefView + LLMAnalysisService.generateMarketBrief() Jul 10 |
| P11-05 | Reuse path for AI Vibe panel — shared provider, different prompts | `[x]` | Single LLMAnalysisService gateway for AI Vibe + INTEL tab Jul 10 |
| P11-06 | Offline fallback UX — `// AGENT_OFFLINE` + retry (per Figma handoff) | `[x]` | // AGENT_OFFLINE + RETRY + DISMISS in IntelBriefView Jul 10 |
| P11-07 | App Store / privacy — document local-only default; no portfolio data leaves device | `[ ]` |
| P11-08 | **Multi-model selection UI** — enumerate installed Ollama models (`GET /api/tags`), let user assign different models per task: *SWOT analysis* vs *market brief* vs *AI Vibe*. Enables e.g. phi4-mini for fast signals + qwen2.5:32b for deep SWOT. Builds on `LLMProvider` protocol (P11-02). Settings → INTELLIGENCE: model picker per task instead of single global field. | `[ ]` | v1.1 |
| P11-09 | **Cloud LLM fallback** (optional, user-configured) — abstract `LLMProvider` to support OpenAI-compatible endpoints (OpenAI, Mistral API, local LM Studio). User opts in explicitly; privacy note prominent. Portfolio data never sent without explicit consent toggle. | `[ ]` | v2 |

**Lean recommendation (for discussion):** Bake a thin `LLMProvider` into the app (not a separate plugin binary). Ollama is the default local backend; user configures URL + model in Settings. Global Intelligence and AI Vibe both call the same service with different system prompts. Ship P10 without any of this; add in P11.

---

## Recommended fix order (when you return)

1. **P6-17** — email CHECK_NOW exit 100 (credentials work; fetch pipeline broken)
2. **Wild-use log** → new P0s
3. **P6-19** — email show-password toggle
4. **P3-07** — PDF B&W mode build-out
5. **P6** remainder — if inbox intake is top priority
6. **P1-04, P1-05, P2** — visual finish to match Template Picker
7. **P3** — PDF trust for external sharing
8. **PKG-04–07** — if handing app to another machine
9. **P7-03** — extension DOM maintenance
10. **P11** — LLM integration (daily brief, shared provider)
11. **P4-05** — macOS Help menu (in-app sheet or `.help` bundle)
12. **P10-20** — Intelligence settings panel (sector keyword tweaks)

---

## Completed this cycle (reference)

- [x] v2.06 typography pipeline + bundled JetBrains Mono (`5a6b27d`)
- [x] Shell DesignTokens consistency (`709e5e5`)
- [x] Navigation micro-polish (pip, meta labels, bulk footer)
- [x] P0 PDF / suffix / server port fixes
- [x] App icon asset set
- [x] User QA: dashboards + triage + server config “fantastic”
- [x] **P10 Global Intelligence v1** — map, geocoding, sector news, pin UX ([PR #6](https://github.com/howard-lgtm/PorteosIntelligence/pull/6), `b9303d2`)
- [x] GI design handoff — 6 frames + `GLOBAL_INTELLIGENCE_HANDOFF.md`
- [x] Swift compiler warnings cleared (Jul 9)
- [x] Full Edit QA ([PR #5](https://github.com/howard-lgtm/PorteosIntelligence/pull/5)) — glossary, Design↔Circular sync, carbon 2dp, property type combobox, notes height
- [x] **P7 browser import cluster** — `parsePrice`, source URL row, `EmailImportRecord` dedup (Jul 9)

---

## P12 — Onboarding & first-launch experience

| ID | Task | Status |
|----|------|--------|
| P12-01 | **First-launch checklist** — `FirstLaunchSheet` shown once when `deals.isEmpty`. Four setup paths: add deal, browser extension, email, local AI. Key shortcuts. Privacy note. Dismissed to `AppStorage` flag. | `[x]` | Jul 28 |
| P12-02 | macOS Help menu — wire ⌘? to `ShortcutsLegendView` in-app (deferred from P4-05) | `[x]` | `CommandGroup(replacing: .help)` shipping Keyboard Shortcuts / Palette / Glossary Jul 28 |

---

## P13 — Security & data integrity

| ID | Task | Status |
|----|------|--------|
| P13-01 | **SwiftData backup before store wipe** — copies `.store` / `.store-shm` / `.store-wal` to `~/Documents/PorteosBackups/` with ISO8601 timestamp before deleting on migration failure. Shows `NSAlert` to user before wiping. | `[x]` | Jul 28 |
| P13-02 | **HTTP server loopback guard** — `DealIngestionServer` already drops non-loopback connections (lines 213–218); server binds to all interfaces but connection handler rejects LAN/WAN requests. | `[x]` | Pre-existing, documented Jul 28 |
| P13-03 | **Dead boilerplate removed** — deleted `Item.swift` (orphaned `@Model`), `ContentView.swift` (Xcode template), `QuickAddDealSheet.swift` (unreferenced). | `[x]` | Jul 28 |
| P13-04 | URL-less deal dedup — `findExistingDeal(byName:city:)` fallback added Jul 28. | `[x]` | Exact name+city match for imports without URL |
| P13-05 | marketId corruption post-geocode — `item.name` fallback removed from `GeocodingService`; only `deal.locationCity` used for marketId resolution. | `[x]` | Jul 28 |
| P13-06 | **Research JSON import size guard** — `DealResearchImporter.apply()` has no size cap; a crafted large file could spike memory. Add `guard data.count < 10_000_000` before parsing. | `[ ]` | Minor |
| P13-07 | **HTTP ingestion API key** — port 9000 has no auth token; any local process can POST deals. Acceptable for personal use; needs a nonce/key for multi-user or shared machine. | `[ ]` | Pre-distribution |

---

## P14 — Market intelligence & auto-preload (Jul–Aug 2026)

| ID | Task | Status |
|----|------|--------|
| P14-01 | **Country + GPS fields in edit sheet** — `locationCountry` added to `PropertyDeal`; GPS manual entry in BASE tab bypasses CLGeocoder; geocoder uses stored country first. | `[x]` | Jul 31 |
| P14-02 | **Auto-preload on ingestion** — `DealPreloader.applyToNewDeal()` called after deal creation in `DealIngestionServer` and `EmailMonitorService`; fills all-zero fields (GPI, OpEx breakdown, loan, interest, renovation, hospitality) from benchmarks; computes `porteosScore` immediately. Score backfill on launch for nil-score deals. | `[x]` | Aug 1 |
| P14-03 | **Score safety floor** — `PorteosScoreCalculator` now takes DSCR, LTV, cash-on-cash. DSCR < 0.8 = −25 pts; LTV > 90% = −20 pts; cash-on-cash ≥ 12% = +5 pts. Grade scale unified with `VibeGrade` (B: ≥65, C: ≥50, D: ≥35). | `[x]` | Aug 1 |
| P14-04 | **Exit cap rate in preloader** — `DealPreloader` sets `exitCapRate` from benchmark prime yield; 5-year NPV calculation no longer shows "—". Exposed in `PreloadReviewSheet`. | `[x]` | Aug 1 |
| P14-05 | **Condition selector + seasonal preload (Phase 3)** — `PreloadReviewSheet` has 4-button condition override (Ruin/Needs Work/Habitable/Good) and season toggle (Peak/Shoulder/Off-Season) for hospitality ADR/occupancy. | `[x]` | Aug 1 |
| P14-06 | **Sensitivity analysis metric alignment** — `HospitalitySensitivityBlock` ADR row now uses GOP delta (not RevPAR) so all three bars share the same scale. | `[x]` | Aug 1 |
| P14-07 | **Sensitivity rewrite** — hardcoded ±€10/−5%/+5pp deltas should scale to deal values; add combined stress scenario; show upside alongside downside; express as % of base GOP. | `[ ]` | Next |
| P14-08 | **Deal list pagination** — `@Query` fetchLimit requires custom `init()` refactor; deferred. Not a risk at current scale. | `[ ]` | Future |
| P14-09 | **BatchTriage benchmark apply** — email-imported deals through batch triage don't get auto-preloaded. | `[ ]` | Future |
| P14-10 | **Hospitality ↔ RE GPI auto-sync** — `[ SYNC GPI ]` button exists; sync still requires manual step. | `[ ]` | Future |
| P14-11 | **GI geocode overlay** — only blocks map when zero deals are plotted (fixed Aug 1); also fixed: market macros labelled as static estimates, ECB hardcode replaced, signal cards show headline count, undated RSS → `.distantPast`, empty-feed market chips dimmed. | `[x]` | Aug 1 |
| P14-12 | **Geocoding consistency** — country consistency check post-geocode (rejects Morocco for PT deal), MarketFeedRegistry alias lookup in `inferCountry()`, extended PT heuristic (Odemira, Silves, Portimão etc.), `inferCity()` accepts registry aliases. | `[x]` | Aug 2 |
| P14-13 | **Intel brief: scrollable, source attribution, market-focused prompt** — ScrollView + context header (N articles · market · 60d), post-hoc article matching shows source/date/link per signal, prompt enforces market relevance and passes article source names. | `[x]` | Aug 2 |
| P14-14 | **Grade/score discrepancy** — `PorteosScoreCalculator.grade()` aligned to `VibeGrade` thresholds (B:≥65); was B:≥60 causing dashboard B vs AI Vibe C for same score. | `[x]` | Aug 2 |
| P14-15 | **Research JSON size guard** — `guard data.count < 10_000_000` before parsing to prevent memory spike from crafted large files. | `[ ]` | Minor |
| P14-16 | **HTTP ingestion API key** — port 9000 unauthenticated. Acceptable personal use; add nonce before multi-user distribution. | `[ ]` | Pre-distribution |

---

*Update this file in place. Do not fork punchlists — keep one living document.*
