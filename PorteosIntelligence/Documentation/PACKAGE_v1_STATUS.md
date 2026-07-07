# Porteos Intelligence — Package v1.0 Status Report

**Date:** 4 July 2026 (EOD)  
**Version:** 1.0 (build 1)  
**Branch:** `main` (pending EOD commit)  
**Design authority:** Figma V2.06 (`7XdLK0I2aWj7KVkvhnJEyE`)  
**Return checklist:** [`PACKAGE_v1_PUNCHLIST.md`](PACKAGE_v1_PUNCHLIST.md)  
**Distribution:** [`DISTRIBUTION.md`](DISTRIBUTION.md)

---

## Executive summary

Porteos Intelligence is **ready for first-package wild use**. The terminal shell, four profile dashboards, deal pipeline, calculators, PDF export, HTTP ingestion server, and browser extension path are functional. Typography now matches the v2.06 font specification via bundled JetBrains Mono and the `PorteosText` style pipeline.

This is a **personal / internal v1** — not App Store polish. Use it in real deal flow, capture friction in the punchlist, then return for a focused second pass.

**Shipped today (2026-07-04):**
- App icon — Pi mark; master at `Design-system/AppIcon/`, installed in `AppIcon.appiconset`
- Package v1 status report + wild-use punchlist
- Developer ID distribution guide + export script
- Archive uploaded to Apple notary service (status: **In Progress** at EOD)

---

## Build snapshot

| Item | Value |
|------|-------|
| Latest commit | `5a6b27d` — typography pipeline + bundled fonts |
| Prior UI commits | `709e5e5` (DesignTokens shell), `bcc1b10` (ComparisonView) |
| Platform | macOS 14+, SwiftUI + SwiftData |
| Marketing version | 1.0 |
| Swift sources | ~107 files under `PorteosIntelligence/` |
| Typography gate | `./scripts/typography-check.sh` (passes on `Views/`) |
| App icon | `Assets.xcassets/AppIcon.appiconset/` — Pi mark, all slots |
| Distribution | Developer ID export — see `DISTRIBUTION.md`; notarization submitted EOD |

---

## What ships in v1.0

### Core workflow
- **3-pane shell** — navigation, dashboard, inspector (`AppShell`, `NavigationPane`, `InspectorPane`)
- **Five profiles** — Real Estate, Hospitality, Design, Circular Economy + Command Center
- **Deal lifecycle** — create, edit (Full Edit 5-tab sheet), triage, pipeline filters, bulk export/delete
- **Calculators** — profile-specific metrics derived on-the-fly; Porteos score
- **Scenarios & sensitivity** — scenario manager, profile sensitivity blocks
- **Comparison view** — side-by-side deal comparison
- **PDF reports** — generate + B&W toggle (output QA still open)
- **Templates** — deal templates picker
- **Batch triage** — multi-deal review sheet
- **Market trends** — trend recording/analysis modules
- **AI analysis panel** — vibe / LLM-assisted review (local service wiring)

### Data & persistence
- **SwiftData models:** `PropertyDeal`, `DealScenario`, `EmailImportRecord`, `MarketTrend`
- **Market benchmarks** — 43-city lookup, auto-populate on city entry
- **Portfolio learning** — history / learning engine scaffold
- **Import/export** — CSV/JSON import, bulk export with depth/scope options

### Ingestion (three paths)

| Path | Mechanism | Status |
|------|-----------|--------|
| **Manual / Quick Add** | Paste or type listing text → `QuickEntryParser` | ✅ Usable |
| **HTTP localhost server** | `DealIngestionServer` on port 9000 (default) | ✅ Usable — sandbox entitlements include network server |
| **Browser extension** | `BrowserExtension/PorteosImporter/` → POST to localhost | ✅ Scaffold — Idealista, Zillow, Hemnet |
| **Email IMAP** | `EmailMonitorService` polls Gmail/Outlook/etc. via IMAP + `ListingEmailParser` | ⚠️ Scaffold — works in theory; needs wild-use validation + product pass (see punchlist P6) |

The **preferred future intake** (per product direction) is a **passive Gmail inbox feed** — broker alert emails instead of site scraping. IMAP polling exists; a full anti-scraper email product pass is deferred to post–wild-use (P6 in punchlist).

---

## Design system — current state

### Complete
- **Bundled fonts** — JetBrains Mono Regular/Medium/SemiBold/Bold; registered at launch
- **Type scale** — `DesignTokens.TypeScale` + `PorteosTextStyle` / `PorteosText` / `PorteosMetricStack`
- **Fixed line heights & tracking** — per `PORTEOS INTELLIGENCE v2.06 — FONT SPECIFICATION.md`
- **Shell typography** — navigation, inspector, header, command bar migrated
- **Dashboard typography** — all four profile dashboards + Cmd Center
- **Shared components** — terminal blocks, metrics, buttons, segments (~47 view files migrated)
- **Hard rules enforced** — `cornerRadius = 0`, DesignTokens colors, no synthetic `.weight()`

### User QA verdict (July 2026)
- **Inspector / dashboards:** “looks fantastic” — Hospitality dashboard, Batch Triage, Server Config confirmed
- **Template Picker:** reference implementation for sheet finish level
- **Left nav:** improved (NAV_V2 header, meta section labels, selection pip) but still slightly behind inspector polish

---

## P0 fixes already landed

| ID | Fix |
|----|-----|
| P0-01 | PDF cover KPI overlap |
| P0-02/03 | `TerminalInputField` suffix width (tCO2e/yr, ACH) |
| P0-04 | Server Config port display (`localhost:9000`) |

---

## Known limitations (expect in wild use)

1. **macOS sheet chrome** — system sheets may show rounded corners despite `cornerRadius = 0` in views (P2-06).
2. **PDF output** — cover fixed; page-level field mapping and B&W mode need smoke test (P3).
3. **Detached inspector window** — content column narrow vs window width (P1-05).
4. **Advanced filter panel** — functional but visually “admin” (P1-04).
5. **Full Edit tabs** — usable; not yet at Template Picker finish (P2).
6. **Email ingestion** — IMAP + app password model; no OAuth/Gmail API yet; parser coverage unknown on real broker formats.
7. **Browser extension** — not packaged/signed; manual load in Chrome; site DOM changes will break scrapers.
8. **Schema migration** — app deletes store on migration failure (logged); back up exports before major model changes.
9. **Untracked WIP** — some files in git status may not be committed; confirm clean tree before tagging a release.

---

## Entitlements & security

```
App Sandbox: ON
Network server: ON  (localhost ingestion)
Network client: ON  (IMAP, optional LLM)
User-selected files: read-write  (export/import)
```

IMAP credentials stored in Keychain (`com.porteos.intelligence` / `imap_credentials`).

---

## How to run wild-use validation

1. Build & run from Xcode (`PorteosIntelligence` scheme).
2. Create 3–5 real deals across profiles (or import sample CSV).
3. Exercise **Full Edit**, **PDF export**, **Batch Triage**, **Comparison**.
4. Start **HTTP server** → test browser extension on one listing site.
5. Optionally configure **Email Setup** with Gmail app password → run manual check.
6. Note bugs, UX friction, and data wrongness in [`PACKAGE_v1_PUNCHLIST.md`](PACKAGE_v1_PUNCHLIST.md) § Wild-use log.

---

## Recommended return order

1. Wild-use log triage → promote blockers to P0
2. Email feed product design + implementation (P6) if inbox intake is priority
3. Remaining visual polish (P1–P3)
4. **Distribution** — [`DISTRIBUTION.md`](DISTRIBUTION.md) (Developer ID, notarize, install on other Macs)

---

## Key documentation map

| Doc | Purpose |
|-----|---------|
| [`PACKAGE_v1_PUNCHLIST.md`](PACKAGE_v1_PUNCHLIST.md) | Full return checklist |
| [`FIGMA_PUNCHLIST.md`](FIGMA_PUNCHLIST.md) | Visual QA detail (subset; superseded by v1 punchlist) |
| [`PORTEOS INTELLIGENCE v2.06 — FONT SPECIFICATION.md`](PORTEOS%20INTELLIGENCE%20v2.06%20%E2%80%94%20FONT%20SPECIFICATION.md) | Typography authority |
| [`FIGMA_FONT_MAP.md`](FIGMA_FONT_MAP.md) | Figma → code token map |
| [`DISTRIBUTION.md`](DISTRIBUTION.md) | Install on multiple Macs (Developer ID, no App Store) |
| `Design-system/Figma/visual-targets/` | PNG comparison targets |

---

## App icon

Terminal badge: dark `#0A0A0A` field, rust `#C25E30` **P@** glyph, square art (macOS applies squircle mask at display time).

Source: `icon_512x512@2x.png` (1024×1024) in `AppIcon.appiconset`.  
Regenerate sizes: resize from 1024 with `sips` if art changes.

---

*Next update: after wild-use session — fill punchlist § Wild-use log and bump this doc’s date.*
