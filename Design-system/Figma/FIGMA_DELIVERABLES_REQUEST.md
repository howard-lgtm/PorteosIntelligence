# Porteos Intelligence — Figma Deliverables Request

**Copy everything below the line into Figma AI, your designer brief, or a Figma Make prompt.**

---

## PROMPT START

You are designing deliverables for **Porteos Intelligence** — a native **macOS** property-deal intelligence app (SwiftUI). The aesthetic is an **institutional terminal**: dark, dense, JetBrains Mono, zero rounded corners, CLI-style module headers. This is a **look-and-feel overhaul** — preserve all existing features; do not remove screens or flows.

### Product context

- **Platform:** macOS desktop only (default window ~1200×800)
- **Layout:** 3-pane shell — Navigation (260px) · Center dashboard · Inspector (280px) · bottom command bar (32px)
- **Profiles:** Command Center, Real Estate, Hospitality, Design, Circular Economy
- **Users:** Property investors / analysts importing deals from listings, email alerts, and CSV

### Design tokens (source of truth — match these)

Import or mirror our token file: `Design-system/Figma/porteos.tokens.json` (v2.06)

**Shell colors**
- Background `#0F1115` · Surface `#1A1D24` · Elevated `#23262E` · Border `#2E333F`
- Text primary `#F8F9FA` · secondary `#94A3B8` · tertiary `#64748B`

**Profile accents (identity only — not for normal metrics)**
- Real Estate `#C25E30` (rust) · Hospitality `#14B8A6` · Design `#A855F7` · Circular `#3B82F6`

**Semantic colors (threshold states only)**
- Success `#10B981` · Warning `#F59E0B` · Danger `#EF4444` · Info `#3B82F6`

**Typography**
- Font: **JetBrains Mono** for all UI, labels, metrics, buttons
- Standard (1×) sizes: labels 11pt · metrics 14pt · nav 13pt · score hero 48pt · row height **28pt**
- **Zero rounded corners** everywhere

**Color rule:** Never assign unique colors per metric type. Color = threshold state only (green/amber/red). Profile accent = headers, active tabs, indicators only.

---

## DELIVERABLE 1 — Startup splash animation

**Purpose:** Full-window animated splash on cold app launch, then crossfade into main UI.

**Design**
- Background: `#0F1115` (full bleed — no white flash)
- Canvas: **1200×800** (or 800×600 if file size is a concern — specify which)
- Style: Match terminal brand — monospace, institutional, minimal
- Duration: **1.0–2.0 seconds** total
- Loop: **No** — play once

**Export**
- PNG frame sequence, zero-padded naming:
  ```
  porteos_splash_000.png
  porteos_splash_001.png
  …
  porteos_splash_NNN.png
  ```
- State frame rate (FPS): **24 or 30** — specify in handoff
- Include a **STARTUP_ANIMATION_HANDOFF.md** with:
  - Total frame count
  - FPS
  - Total duration (seconds)
  - Canvas dimensions
  - First and last frame filename
  - Any text shown in animation (exact copy)

**Optional:** Lottie JSON export (future — PNG sequence is primary)

---

## DELIVERABLE 2 — Display density modes (required)

Design **two complete density variants** of the same UI. Not a slider — exactly **two steps**:

| Mode | Scale | Target display | Metric label | Metric value | Row height |
|------|-------|----------------|--------------|--------------|------------|
| **Standard** | 1× | Laptop 13–14" | 11pt | 14pt | 28pt |
| **Large** | 2× | External 27"+ | 22pt | 28pt | 56pt |

Scale **typography + row heights + vertical spacing together**. Do **not** scale nav width (260) or inspector width (280).

**Minimum screens in both densities:**
1. App shell with deal selected (Real Estate dashboard)
2. Real Estate dashboard (stress test — all modules)
3. Navigation pane with deal list + status filters
4. Inspector — WEIGHTS tab
5. Settings → GENERAL (include `[ STANDARD ]` / `[ LARGE ]` toggle)

Label frames clearly: `Density: Standard` and `Density: Large`.

---

## DELIVERABLE 3 — Component library (Page: `01 — Components`)

Build as Figma components with variants. Match `porteos.components.json` in repo.

**P0 — required**
- App shell frame (header + 3 panes + command bar)
- Primary button `[ ACTION_NAME ]` — variants: rust, teal, purple, blue, green, red, amber, muted
- Secondary button `./action_name` (green text, transparent)
- Deal row — variants: default, selected, compare-selected × statuses: pipeline, review, viable, rejected, acquired
- Profile nav link — inactive / active
- Status pill (5 statuses)
- Terminal block — numbered module with CLI header `porteos@system ~ % 01 // MODULE_NAME`
- Metric grid cell — variants: neutral, optimal, warning, danger
- Metric with trend (cell + sparkline)
- Terminal input field (28pt height, focus state)
- Tab bar (WEIGHTS / AI VIBE style — 2px active underline)

**P1 — required**
- Terminal metric row (list layout, 28pt, danger left-border variant)
- Porteos score block (large number + letter grade A–F)
- Circular score ring (120px and 180px)
- Sheet chrome (header + divider + scroll body + footer)
- Template card (category badge, name, description, 2–3 key metrics)
- Comparison table (2–4 deal columns, best/worst highlighting)

**P2 — required**
- System log block (`[ERR]` / `[WARN]` entries)
- Market trend module (heat badge HOT/WARM/COOL/COLD + sparklines)
- Sensitivity block (sliders + base vs simulated + scenario save/load)
- AI Vibe panel — states: idle, running, result (grade + signal sections with + · ~ ! prefixes)
- Advanced filter panel
- Command palette overlay (⌘K)
- Ingestion toast (top-right notification)
- Triage card (batch approve/reject grid)
- Server status LED (offline / running / error)

---

## DELIVERABLE 4 — Screens (Pages 02–06)

Design every screen below at **Standard (1×)** density. Large (2×) for Deliverable 2 minimum set only unless time allows all.

### Page `02 — Shell & Navigation`
- [ ] App shell — deal selected (Real Estate + inspector)
- [ ] App shell — no deal (empty state + `[ ./LOAD_SAMPLE_DEAL ]`)
- [ ] Detached navigation pane window

### Page `03 — Dashboards`
- [ ] **Real Estate dashboard** (PRIORITY — full detail):
  - Porteos score header
  - `01 // CORE_FINANCIALS_REVENUE` (GPI, vacancy, EGI, revenue)
  - `02 // EXPENSE_AUDIT_OPEX` (OpEx line items + ratio)
  - `03 // PROFITABILITY_TELEMETRY` (NOI, cap rate, CFBT, CFAT — show threshold colors)
  - `04 // LEVERAGE_ENGINE` (LTV, DSCR, debt service)
  - `05 // RETURN_METRICS` (CoC, IRR, equity multiple)
  - `06 // SENSITIVITY` (sliders + scenarios)
  - Validation log + market trends module
- [ ] Hospitality dashboard (3 modules + sensitivity)
- [ ] Design dashboard (4 modules + sensitivity)
- [ ] Circular Economy dashboard (3 modules + sensitivity)
- [ ] Command Center (portfolio summary, profile health, recent activity, system status)
- [ ] Comparison view (2–3 deals side by side)

### Page `04 — Inspector & Overlays`
- [ ] Inspector — WEIGHTS (4 sliders, auto-rebalance to 100%)
- [ ] Inspector — AI VIBE idle
- [ ] Inspector — AI VIBE with results
- [ ] Command palette overlay
- [ ] Keyboard shortcuts legend
- [ ] Ingestion toast

### Page `05 — Sheets & Modals`
- [ ] Template picker (12 templates + blank — categories: RE, Hospitality, Mixed-Use, Design, Circular)
- [ ] Full deal editor — 5 tabs: BASE, REAL_ESTATE, HOSPITALITY, DESIGN, CIRCULAR
- [ ] Quick Add (natural language input + confidence pill HIGH/MEDIUM/LOW)
- [ ] Import deals (CSV preview + column mapping)
- [ ] Bulk export (format CSV/JSON · depth 3 tiers · scope 4 options)
- [ ] PDF report config (section toggles + page estimate)
- [ ] Batch triage (pipeline card grid + approve/reject)

### Page `06 — Admin & Extension`
- [ ] Settings — tabs: EMAIL_INGESTION, INGESTION_SERVER, GENERAL
- [ ] Email setup (IMAP form, provider presets)
- [ ] Server config (port, start/stop, request log)
- [ ] Browser extension button — `[ SEND TO PORTEOS ]` — states: default, sending, sent, error

---

## DELIVERABLE 5 — Figma file structure

Organize pages exactly as:

```
00 — Cover & Tokens       (brief, swatches, type scale, density comparison)
01 — Components
02 — Shell & Navigation
03 — Dashboards
04 — Inspector & Overlays
05 — Sheets & Modals
06 — Admin & Extension
07 — Splash & Extension   (splash frames + extension button)
```

**Cover page must include:**
- Product name: Porteos Intelligence / PORTEOS_TERMINAL
- Resolved design decisions (see below)
- Color swatch grid
- Type scale specimen (Standard vs Large)
- Link to dev handoff repo paths

---

## DELIVERABLE 6 — Design decisions (document on cover page)

Pick one option per row and note on cover:

| Decision | Options |
|----------|---------|
| RE accent | Rust `#C25E30` (current code) **or** Gold `#D4AF37` (original spec) |
| Aesthetic | Full terminal **or** Terminal data + cleaner chrome **or** Institutional SaaS |
| Button format | `[ ACTION ]` CLI syntax **or** standard labels |
| CLI headers | Keep `porteos@system ~ %` **or** simplify to module titles **or** remove |
| Splash | Every launch **or** first launch only |

---

## DELIVERABLE 7 — Export package for developers

When complete, export a folder structure for git:

```
design-system/figma/
├── STARTUP_ANIMATION_HANDOFF.md     (filled in — not template)
├── Splash Image/
│   └── porteos_splash_000.png … NNN
├── porteos.tokens.json               (sync from Tokens Studio if tokens changed)
└── exports/                        (optional PNG/PDF of key screens)

PorteosIntelligence/Resources/Splash/
└── porteos_splash_000.png … NNN     (same frames — app bundle)
```

**Tokens Studio:** Import `porteos.tokens.json` from repo at start; export back if you change tokens.

---

## DELIVERABLE 8 — Optional (nice to have)

- [ ] App icon 1024×1024 + macOS icon set (only if redesigning icon)
- [ ] App Store screenshot frames (marketing — not in-app)
- [ ] Lottie splash alternative
- [ ] Light mode exploration (app is dark-only today — document if proposing)

---

## DO NOT

- Remove any screen, module, or flow listed above
- Use rounded corners (unless explicitly proposing a breaking brand change on cover page)
- Color-code metrics by type (RevPAR teal, MCI purple, etc.) — thresholds only
- Use SF Pro for numbers — JetBrains Mono only
- Design mobile or web layouts — macOS desktop only
- Replace import-first workflow with manual-entry-first hierarchy

---

## Reference files in repo (for fidelity)

| File | Purpose |
|------|---------|
| `design-system/figma/porteos.figma-execution-plan.json` | Phased build checklist |
| `design-system/figma/porteos.components.json` | Component anatomy |
| `design-system/figma/porteos.screens.json` | Screen inventory |
| `design-system/figma/porteos.tokens.json` | Design tokens |
| `design-system/figma/DISPLAY_DENSITY.md` | 1× / 2× spec |
| `PorteosIntelligence/01_TERMINAL_DESIGN_SYSTEM.md` | Full design system rules |
| `PUNCHLIST.md` | Current project status |

---

## Acceptance criteria (definition of done)

- [ ] All 7+ Figma pages exist with correct names
- [ ] Tokens variables synced; no orphan hex outside token system
- [ ] P0 + P1 components built with variants
- [ ] Real Estate dashboard is pixel-complete at Standard density
- [ ] Standard + Large variants exist for minimum density set
- [ ] Splash PNG sequence + handoff doc exported
- [ ] Cover page documents all design decisions
- [ ] Export folder ready to drop into git

## PROMPT END

---

## How to use this document

| Audience | Action |
|----------|--------|
| **Figma AI / Figma Make** | Copy from `PROMPT START` through `PROMPT END` |
| **Human designer** | Send this file + link to Figma file + `porteos.tokens.json` |
| **Howard** | Paste into Figma chat; attach `porteos.tokens.json` as reference |
| **After delivery** | Drop exports into repo paths in Deliverable 7; tell Cursor to execute `porteos.figma-execution-plan.json` |
