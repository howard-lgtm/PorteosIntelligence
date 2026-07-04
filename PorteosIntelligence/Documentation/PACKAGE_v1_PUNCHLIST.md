# Porteos Intelligence — Package v1.0 Punchlist

**Created:** 4 July 2026  
**Purpose:** Return here after using Porteos Intelligence in the wild.  
**Status key:** `[ ]` open · `[~]` in progress · `[x]` done · `[—]` deferred / won’t fix v1

**Companion:** [`PACKAGE_v1_STATUS.md`](PACKAGE_v1_STATUS.md)

---

## Wild-use log (fill in during / after field use)

| Date | Area | Observation | Severity | Promoted ID |
|------|------|-------------|----------|-------------|
| | | | | |
| | | | | |
| | | | | |

**Severity:** blocker · major · minor · cosmetic · idea

---

## PKG — First package / release engineering

| ID | Task | Status | Notes |
|----|------|--------|-------|
| PKG-01 | App icon in `AppIcon.appiconset` | `[x]` | 1024 + all macOS slots (2026-07-04) |
| PKG-02 | Confirm version/build in Xcode (1.0 / 1) | `[ ]` | `MARKETING_VERSION` already 1.0 |
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
| P1-05 | Detached inspector | Empty horizontal margins | `[ ]` | `DetachedPaneViews` width cap |
| P1-06 | Deal rows | Right column: cap rate vs status chip | `[ ]` | Figma `img_00_22` |
| P1-07 | HTTP endpoint display | `monospacedDigit` on full URL line | `[ ]` | Server Config / nav status |

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
| P2-07 | Legacy sheets | Deprecate or align `EditDealSheet` / `NewDealSheet` / `QuickAddDealSheet` | `[ ]` | Confirm wiring vs Figma sheets |

---

## P3 — PDF report

| ID | Area | Issue | Status |
|----|------|-------|--------|
| P3-01 | PDFReportSheet UI | Ghost/double text at deal info block edge | `[ ]` |
| P3-02 | Sheet chrome | Rounded corners | `[ ]` |
| P3-03 | PDF cover output | Overlap | `[x]` |
| P3-04 | PDF page 3+ | Field mapping (e.g. GFA `400000 m²`) | `[ ]` | Data vs display |
| P3-05 | B&W mode | Untested output | `[ ]` | Smoke test toggle |
| P3-06 | External share | Cover KPI spacing OK for send-out | `[ ]` | Re-verify after wild PDFs |

---

## P4 — Admin / secondary surfaces

| ID | Surface | Issue | Status |
|----|---------|-------|--------|
| P4-01 | Server Config / Ingestion panel | Typography migrated; layout pass | `[~]` | Post-typography sweep |
| P4-02 | Email Setup / Ingestion panel | Same | `[~]` | |
| P4-03 | Settings | Legacy layout pass | `[ ]` | `SettingsView` |
| P4-04 | Command palette / shortcuts legend | Visual parity | `[ ]` | Low priority |

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
| P6-10 | Wild-test IMAP with real Gmail + 10 broker emails | `[ ]` |
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
| P7-01 | Localhost server stable under sandbox | `[ ]` | Wild test |
| P7-02 | Extension POST payload schema documented | `[ ]` | Match `DealIngestionServer` |
| P7-03 | Idealista / Zillow / Hemnet DOM drift | `[ ]` | Per-site maintenance |
| P7-04 | Extension icons + Chrome Web Store | `[—]` | If public distribution |

---

## P8 — Data & calculators (only if wild use finds bugs)

| ID | Task | Status |
|----|------|--------|
| P8-01 | Verify calculator outputs vs spreadsheet for 1 RE deal | `[ ]` |
| P8-02 | Scenario save/load edge cases | `[ ]` |
| P8-03 | Market benchmark wrong city alias | `[ ]` |
| P8-04 | SwiftData export before schema change | `[ ]` |

---

## P9 — AI / intelligence modules

| ID | Task | Status |
|----|------|--------|
| P9-01 | AI vibe panel useful on real deals | `[ ]` |
| P9-02 | LLM endpoint config + privacy note | `[ ]` |
| P9-03 | Portfolio learning engine feedback loop | `[ ]` | Scaffold exists |

---

## Recommended fix order (when you return)

1. **Wild-use log** → new P0s
2. **P6 email feed** — if inbox intake is top priority
3. **P1-04, P1-05, P2** — visual finish to match Template Picker
4. **P3** — PDF trust for external sharing
5. **PKG-04–07** — if handing app to another machine
6. **P7** — only if still using browser extension over email

---

## Completed this cycle (reference)

- [x] v2.06 typography pipeline + bundled JetBrains Mono (`5a6b27d`)
- [x] Shell DesignTokens consistency (`709e5e5`)
- [x] Navigation micro-polish (pip, meta labels, bulk footer)
- [x] P0 PDF / suffix / server port fixes
- [x] App icon asset set
- [x] User QA: dashboards + triage + server config “fantastic”

---

*Update this file in place. Do not fork punchlists — keep one living document.*
