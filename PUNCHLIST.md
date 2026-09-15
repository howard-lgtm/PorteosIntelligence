# Porteos Intelligence — Punchlist

**Last updated:** 10 September 2026  
**Build:** compiling  
**Platform:** macOS (SwiftUI + SwiftData)  
**Apple App Store:** approved — running locally

> **Wild-use QA:** see [`PorteosIntelligence/Documentation/PACKAGE_v1_PUNCHLIST.md`](PorteosIntelligence/Documentation/PACKAGE_v1_PUNCHLIST.md) for field-test bugs (email, browser import, PDF).

---

## Today — 6 July 2026

### Startup splash (Figma handoff → app)

| # | Task | Owner | Status |
|---|------|-------|--------|
| S1 | Copy `STARTUP_ANIMATION_HANDOFF.md` + `Splash Image/*.png` from local CascadeProjects into repo `Design-system/Figma/` | Howard | ⬜ |
| S2 | Confirm frame count, FPS, total duration, canvas size from handoff doc | Cursor + Howard | ⬜ |
| S3 | Drop PNG sequence into `PorteosIntelligence/Resources/Splash/` | Howard | ⬜ |
| S4 | Wire `SplashView` → `RootView` → `AppShell` (code scaffold in place) | Cursor | 🔄 |
| S5 | Test cold launch — splash plays, crossfades to shell, no flash | Cursor | ⬜ |
| S6 | Add “skip splash” preference (optional, post-MVP) | — | ⬜ |

**Local source paths (Howard's machine):**
```
CascadeProjects/PorteosNative/PorteosIntelligence/Design-system/Figma/STARTUP_ANIMATION_HANDOFF.md
CascadeProjects/PorteosNative/PorteosIntelligence/Design-system/Figma/Splash Image/porteos_splash_000.png
```

**Repo targets:**
```
Design-system/Figma/STARTUP_ANIMATION_HANDOFF.md
Design-system/Figma/Splash Image/
PorteosIntelligence/Resources/Splash/
```

**Integration summary:** see `Design-system/Figma/STARTUP_ANIMATION_HANDOFF.md`

---

### Figma UI redesign

| # | Task | Status |
|---|------|--------|
| F1 | Import `porteos.tokens.json` via Tokens Studio | ⬜ |
| F2 | Resolve 7 design decisions in execution plan | ⬜ |
| F3 | Phase 1 — component library | ⬜ |
| F4 | Phase 2 — shell + nav | ⬜ |
| F5 | Phase 3 — dashboards (RE stress test first) | ⬜ |
| F6 | Phases 4–7 — inspector, sheets, admin, validation | ⬜ |

**Cursor entry point:** `Design-system/Figma/porteos.figma-execution-plan.json`

---

### Apple review

| # | Task | Status |
|---|------|--------|
| A1 | App submitted — waiting on Apple | 🔄 |
| A2 | Triage any review feedback when received | ⬜ |
| A3 | Map required changes against Figma redesign (avoid double work) | ⬜ |

---

## Scoring System

**Symptom** (observed 10 Sept 2026, AI Vibe panel, Portugal deal): overall score hero shows **100/100** while the five signal bars read **88 / 89 / 90 / 62 / 92** (Location, Market Timing, Cash Flow, Risk, ESG — ≈ 84 avg). The hero looks inconsistent with its own components.
**Priority:** Medium — cosmetic, but score credibility matters.
**Status:** ✅ **RESOLVED** (Week 3 Day 3, Sept 13-14, 2026) — Hero now computes live, bars labeled as sentiment. See Done section.

Investigation (4 avenues):

1. **The bars are not components.** `AIVibePanel.swift:763–773` (`topBarSignals`) derives each bar's score from `scoreForSignal` (`:775–782`) — a **sentiment formula**: `positive = 88 + index`, `neutral = 75 + index`, `warning = max(45, 68 − 2·index)`, `critical = max(25, 42 − 3·index)`. The observed 88/89/90/**62**/92 is *exactly* positive ×4 plus one `warning` at index 3. The bars visualise LLM sentiment (and `:767` positionally renames whatever the LLM returned into the five fixed labels). They have no arithmetic relation to the composite — they were never meant to average to it.
2. **The calculator can legitimately reach 100.** `PorteosScoreCalculator.swift`: `normalizedCapRate` / `normalizedRevPAR` saturate at 100 (`:55–56`: cap ≥ 10% / revPAR ≥ €200); unpopulated profiles have their weights **redistributed into real-estate** (`:44–52`); bonuses stack (revenue > €5M +10, DSCR ≥ 2.0 +8, LTV < 65 +5, CoC ≥ 20% +10, planning/STR approved +4/+5); final clamp `min(max(…, 0), 100)` (`:109`) crushes anything ≥ 100 to exactly 100.
3. **Weights:** user-set sliders — a weighted mean of ~84-average components cannot produce 100 *without* the saturation + bonuses + clamp in #2.
4. **No error-default-to-100** — the only `100` constants in the calculator are the normalization caps and the clamp bounds; no try/catch fallback.

**Working root cause:** the UI shows two independent quantities side by side — a deterministic composite (cached `deal.porteosScore`, `AIVibePanel.swift:174`; written from 7 call sites, e.g. `:982` after benchmark-apply, so it can go stale) vs sentiment-derived bars. The 100-vs-84 gap is a presentation / category error, possibly compounded by hero staleness.

Fix directions (Week 3, pick one):

- [ ] Label the bars as sentiment indicators (drop the numbers), or derive them from real component inputs
- [ ] Recompute the hero live from `PorteosScoreCalculator` instead of the cached `deal.porteosScore` (or show both, labelled)
- [ ] Score-breakdown tooltip (base + bonuses/penalties, pre-clamp) so 100 reads as “saturated”, not “perfect”
- [ ] Audit the 7 `deal.porteosScore` write sites for staleness (recompute-on-edit on every path)

---

## High priority (app)

- [ ] **Startup splash** — Figma animated sequence on app open (in progress)
- [ ] `PorteosScoreBlock` — weight sliders interactive in main view (currently editor-only)
- [ ] Inspector pane — inline quick-edit capability
- [ ] `TopHeaderBar` — wire deal actions (bell/settings still decorative)

## V2 considerations (backlog)

| Feature | Notes |
|---------|--------|
| **Display density toggle** | **Standard 1×** (laptop) vs **Large 2×** (external monitor). Scales type + row heights together. Settings → GENERAL wired; full UI migration during Figma pass. See `DISPLAY_DENSITY.md`. |
| Deal clone | Context menu |
| Tags + favorites UI | Model fields exist |
| City autocomplete | API exists |
| JSON import | Picker allows `.json`; parser is CSV-only today |
| Investor Score / AI chat | In metrics spec, not built |

- [ ] Deal clone / duplicate context menu action
- [ ] City autocomplete in `FullDealEditSheet` (`MarketBenchmarks.suggestions`)
- [ ] Sync `01_TERMINAL_DESIGN_SYSTEM.md` with live type scale

## Low priority / polish

- [ ] Animate metric value changes when switching deals
- [ ] `tags` / `isFavorite` UI (model fields exist, no surface)
- [ ] Wire global command bar input to command execution
- [ ] Legacy sheet cleanup (`NewDealSheet`, `EditDealSheet`, `QuickAddDealSheet`)

## Done recently

- [x] **AI Vibe score display fix** (Week 3 Day 3, Sept 13-14, 2026) — Fixed hero/bars discrepancy. Hero now computes live via `PropertyDealViewModel` (no cached staleness). Bars labeled as "SENTIMENT:" indicators (clarifies they're not composite components). Also fixed window vanishing crash (`WindowStateManager` fullscreen toggle guard). Manual verification passed. Commit: d8746ee.
- [x] Figma design token package (`Design-system/Figma/`)
- [x] Cursor execution plan JSON
- [x] Full feature inventory for UI redesign
- [x] Splash integration scaffold (`SplashView`, `RootView`)

---

## Quick reference

| Doc | Path |
|-----|------|
| Punchlist | `PUNCHLIST.md` |
| Project status | `PROJECT_STATUS.md` |
| Figma execution plan | `Design-system/Figma/porteos.figma-execution-plan.json` |
| Splash handoff | `Design-system/Figma/STARTUP_ANIMATION_HANDOFF.md` |
| Display density | `Design-system/Figma/DISPLAY_DENSITY.md` |
| Wild-use punchlist | `PorteosIntelligence/Documentation/PACKAGE_v1_PUNCHLIST.md` |
| Design system | `PorteosIntelligence/01_TERMINAL_DESIGN_SYSTEM.md` |
