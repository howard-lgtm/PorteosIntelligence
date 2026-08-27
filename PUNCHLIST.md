# Porteos Intelligence — Punchlist

**Last updated:** 7 July 2026  
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
