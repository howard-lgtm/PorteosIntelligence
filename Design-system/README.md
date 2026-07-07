# Porteos Design System — Where everything lives

Three layers. Don't mix them up.

```
┌─────────────────────────────────────────────────────────────┐
│  FIGMA (visual mockups)          ← you design here          │
│  Porteos Intelligence — UI Redesign                         │
└───────────────────────────┬─────────────────────────────────┘
                            │ screenshots / file link
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Design-system/Figma/  (.md + .json)  ← specs & handoff     │
└───────────────────────────┬─────────────────────────────────┘
                            │ Cursor implements
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  PorteosIntelligence/  (.swift)  ← running app code         │
│  DesignTokens.swift = code authority at runtime             │
└─────────────────────────────────────────────────────────────┘
```

---

## In Figma (you — not files in git)

| Page | What to build |
|------|----------------|
| **Cover & Tokens** | Variables, text styles, cover frame (copy from `Figma/phase-0-cover-spec.md`) |
| **Components** | Button, metric cell, terminal block, etc. (reference `Figma/porteos.components.json`) |
| **Shell & Navigation** | 3-pane app shell |
| **Dashboards** | 5 profile views |
| **Inspector & Overlays** | Weights, AI vibe, command palette |
| **Sheets & Modals** | All modal flows |
| **Admin & Extension** | Settings, email, server |

**Do not paste `.md` or `.swift` into Figma.** Use them as reference while you draw frames.

---

## In this repo — `Design-system/Figma/`

| File | Type | Purpose |
|------|------|---------|
| **`README.md`** | md | Start here for Figma import |
| **`FIGMA-FREE-SETUP.md`** | md | Figma Pro Variables setup (no paid Tokens Studio) |
| **`PHASE-0-FIGMA-CHECKLIST.md`** | md | Phase 0 tasks |
| **`phase-0-cover-spec.md`** | md | Content for Cover & Tokens page |
| **`porteos.figma-execution-plan.json`** | json | Phased plan for Cursor |
| **`porteos.tokens.json`** | json | Color/type/spacing values (reference or optional import) |
| **`porteos.components.json`** | json | Component sizes & variants — Phase 1 |
| **`porteos.screens.json`** | json | 27 screens checklist — Phases 2–6 |
| **`DESIGN.md`** | md | Stitch design reference |
| **`porteos_v2.06_color_spec.md`** | md | V2.06 color architecture |

**Rule:** JSON + md stay in git. Figma holds pixels only.

---

## In Swift code — `PorteosIntelligence/`

| File | When it changes |
|------|-----------------|
| **`Utilities/DesignTokens.swift`** | After design is locked — Cursor updates hex, spacing, type |
| **`Views/**`** | After Figma mockups approved — lay new UI on working app |
| **`01_TERMINAL_DESIGN_SYSTEM.md`** | Human-readable design law (synced from decisions) |

**Do not edit Swift during Figma exploration** unless fixing bugs.

---

## What to do right now (Phase 0)

1. **Figma → Cover & Tokens page**  
   Follow **`Figma/FIGMA-FREE-SETUP.md`** to create Variables + text styles.

2. **Figma → same page**  
   Build cover frame using **`Figma/phase-0-cover-spec.md`** (copy hex, type sizes, decisions table — draw rectangles and text).

3. **Repo**  
   Nothing to add unless you change a design decision — then tell Cursor; we update `porteos.tokens.json` + `DesignTokens.swift` together at implementation time.

---

## After mockups are done

1. Share Figma link (or exports)
2. Cursor runs Phase 1+ from `porteos.figma-execution-plan.json`
3. SwiftUI updated to match Figma — `DesignTokens.swift` first, then views
