# Figma V2.06 — Visual QA Punchlist

**Last updated:** 2026-07-04  
**Authority:** Running app vs `Design-system/Figma/visual-targets/` + user QA notes.

> **Superseded for v1 return work by** [`PACKAGE_v1_PUNCHLIST.md`](PACKAGE_v1_PUNCHLIST.md) — use that as the living checklist; this file retains visual QA detail.

Status key: `[ ]` open · `[~]` in progress · `[x]` done

---

## P0 — Layout / overlap bugs

| ID | Area | Issue | Notes / fix target |
|----|------|-------|-------------------|
| P0-01 | **PDF cover (page 1)** | Jumbled/overlapped text in **// KEY FINANCIAL INDICATORS** block | `[x]` Fixed spacing in `drawCover` (2026-07-04). |
| P0-02 | **Full Edit — CIRCULAR tab** | Unit suffix **`tCO2e/yr`** overlaps value | `[x]` Dynamic suffix width in `TerminalInputField`. |
| P0-03 | **Full Edit — DESIGN tab** | **`ACH`** unit wraps/stacked | `[x]` Same fix. |
| P0-04 | **Server Config sheet** | Endpoint URLs show broken port: `localhost:9 000` | `[x]` URL on own line with `fixedSize`. |

---

## P1 — Shell parity (left nav vs right inspector)

Inspector (`img_00_21`) reads finished; **NavigationPane (left) still feels a generation behind.**

| ID | Area | Issue | Target |
|----|------|-------|--------|
| P1-01 | **Nav pane header** | Lacks `./NAV_V2`-style path label | `[x]` Added `./NAV_V2` + dividers (2026-07-04). |
| P1-02 | **Nav section headers** | `NAVIGATION` / `DEALS` labels lighter weight than inspector | `[x]` Now `// NAVIGATION` meta-bold style. |
| P1-03 | **Deal rows** | List density and selection pip OK; bulk-action row (`./BULK_EXPORT`) feels disconnected from Figma nav footer. | Compare `img_00_21` left column in full-shell target. |
| P1-04 | **Filter panel inline** | Advanced filter panel functional but visually “admin” — not yet Figma-polished. | Token pass done; layout/spacing pass still needed. |
| P1-05 | **Detached inspector window** | Large empty margins left/right; content column too narrow vs window chrome. | `DetachedPaneViews` — fill width or cap window to content. |

---

## P2 — Sub-menu sheets (Full Edit tabs)

Sheets open and work; **tab content still behind dashboard/inspector finish.**

| ID | Area | Issue | Target |
|----|------|-------|--------|
| P2-01 | **Tab bar** | Tabs correct (underline accents) but lack Figma bracket style / full-width segment bar used elsewhere. | `FullDealEditSheet.tabBar` — align with `TerminalSegmentBar` or `img_00_11`. |
| P2-02 | **Section headers** | `INCOME`, `EXPENSES`, etc. are plain text | `[~]` Now `// SECTION` meta-bold (2026-07-04). |
| P2-03 | **Field grid** | Single-column stack; Figma shows tighter terminal blocks | `[~]` Tighter 12pt section spacing. |
| P2-05 | **Footer** | Cancel plain text | `[x]` `[ CANCEL ]` uses outlined muted style. |
| P2-06 | **Sheet chrome** | macOS sheet presents with **rounded corners** — spec is `cornerRadius = 0`. | `.presentationBackground` / window style if feasible on macOS 14+. |

---

## P3 — PDF report UI + output

| ID | Area | Issue | Notes |
|----|------|-------|-------|
| P3-01 | **PDFReportSheet UI** | Faint ghost/double text at left edge of **// DEAL INFORMATION** block (screenshot 23:52). | Investigate double render, ScrollView clip, or sheet shadow bleed. |
| P3-02 | **PDFReportSheet chrome** | Sheet window has rounded corners (same as P2-06). | Low priority unless we move to centered overlay pattern. |
| P3-03 | **PDF output — cover** | P0-01 overlap on generated PDF. | |
| P3-04 | **PDF output — page 3** | Design GFA shows `400000 m²` (data/model issue?) — verify field mapping vs display. | Likely conflated GFA with another field; separate data bug if confirmed. |
| P3-05 | **PDF B&W mode** | Untested in QA pass; user noted screen PDF “interesting if not printing.” | Smoke-test `blackAndWhite` toggle output. |

---

## P4 — Admin / secondary surfaces (not yet migrated)

| ID | Surface | Status |
|----|---------|--------|
| P4-01 | `ServerConfigSheet` / `DealIngestionServerPanel` | Hardcoded fonts/hex; port display bug (P0-04) |
| P4-02 | `EmailSetupSheet` / `EmailIngestionPanel` | Legacy tokens |
| P4-03 | `SettingsView` | Legacy tokens |
| P4-04 | `EditDealSheet` / `NewDealSheet` / `QuickAddDealSheet` | Legacy — confirm still wired or deprecate in favor of Figma sheets |

---

## P5 — Visual QA backlog (compare to PNGs)

| Ref | Screen | Status |
|-----|--------|--------|
| `img_00_20` | App shell — empty / idle inspector | Partial |
| `img_00_21` | App shell — deal selected (FULL TARGET) | Inspector good; nav gap (P1) |
| `img_00_11` | Full Edit sheet | Functional; finish pass (P2) |
| `img_00_16` | PDF Report sheet | Good overall; P3-01 ghost text |

---

## Recommended fix order

1. **P0-01** — PDF cover KPI overlap (quick, high visibility)
2. **P0-02 / P0-03** — suffix width in `TerminalInputField`
3. **P1** — NavigationPane shell pass vs `img_00_21` left column
4. **P2** — Full Edit tab polish (`img_00_11`)
5. **P3-01** — PDF sheet ghost text
6. **P4** — Admin sheets token sweep

---

## QA session notes (2026-07-03)

- Overall direction strong; **right side (inspector) ahead of left (nav)**.
- Sub-menu edit sheets usable but **not at dashboard finish level**.
- PDF report sheet **looks good** for on-screen review; cover page KPI section needs spacing fix before sharing externally.
- Detached inspector window feels **under-filled** horizontally.
