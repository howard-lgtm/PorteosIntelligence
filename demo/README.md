# Porteos Intelligence Usability Demo

**Status:** Scaffold ready, UI implementation pending  
**Stack:** Vite + React + TypeScript  
**Output:** Single self-contained HTML file for hotTake.it

---

## Purpose

This is an interactive browser-based demo simulating a four-step Porteos Intelligence workflow:

1. **Prepare** — Start demo and select intelligence profile
2. **Import** — Select or upload property data (fictional)
3. **Evaluate** — Review AI-generated scores, signals, and dashboards
4. **Report** — Generate and preview PDF/JSON reports

**This demo uses entirely fictional data and does NOT connect to production Porteos systems.**

---

## Setup Requirements

- **Node.js:** 20+ (LTS recommended)
- **npm:** Included with Node.js
- **Modern browser:** Chrome, Safari, Firefox (latest versions)

---

## Installation

```bash
cd demo
npm install
```

---

## Development

### Start Dev Server

```bash
npm run dev
```

Opens at `http://localhost:5173/`  
Hot module reloading enabled.

### Run Tests (Watch Mode)

```bash
npm run test:watch
```

### Type Check

```bash
npm run typecheck
```

### Lint & Format

```bash
npm run lint
npm run format
```

---

## Build for Production

### Single Command

```bash
npm run build
```

**Output:** `dist/index.html` (self-contained, all assets inlined)

### Verify Build

```bash
npm run preview
```

Opens local server at `http://localhost:4173/` serving production build.

**Manual checks:**

- Open browser DevTools (Console tab) → no errors
- Open Network tab → no requests after initial load
- Disable network (Offline mode) → demo still works

---

## Testing

### Run All Tests

```bash
npm run check
```

Runs:

- Type checking
- Linting
- Format validation
- Unit tests (Vitest)
- Production build
- E2E smoke tests (Playwright)

**All checks must pass before deployment.**

### Individual Test Commands

```bash
npm run test        # Unit tests (Vitest)
npm run test:ui     # Vitest UI
npm run test:e2e    # Playwright E2E
npm run test:e2e:ui # Playwright UI mode
```

---

## Architecture Summary

### State Management

- **React `useReducer`** — Single reducer, deterministic transitions
- **No external state library** — Redux/Zustand not needed for this scope
- **Resettable** — `RESET_DEMO` action restores initial state

### Component Structure

```
App (root)
├── Phase components (future)
│   ├── PreparePhase
│   ├── ImportPhase
│   ├── ProcessingPhase
│   ├── EvaluatePhase
│   └── ReportPhase
└── Shared components (future)
```

### Styling

- **CSS custom properties** (`src/styles/tokens.css`) for design tokens
- **No CSS framework** — Plain CSS, modular per-component styles
- **System fonts only** — No remote font CDN

### Data

- **Fictional properties** — See `src/data/demoData.ts`
- **Hardcoded evaluation results** — No API calls

---

## Implementation Status

### ✅ Complete (Scaffold)

- Project structure
- TypeScript strict mode config
- Vite + React setup
- State management foundation (reducer, types, initial state)
- CSS token system
- Fictional demo data
- Test infrastructure (Vitest + Playwright)
- Documentation (architecture, interaction contract, hotTake handoff)
- Single-file build configuration

### ⬜ Pending (UI Build)

- Prepare phase UI
- Import phase UI (property selector)
- Processing phase (progress animation)
- Evaluate phase (score hero, sentiment bars, dashboard tabs)
- Report phase (format selector, preview)
- Complete phase (summary + reset)
- Full keyboard navigation
- Accessibility (ARIA labels, focus management)
- E2E test for complete workflow

---

## hotTake.it Export

See `docs/hottake-handoff.md` for detailed instructions.

**Quick steps:**

1. Ensure all implementation is complete
2. Run `npm run check` (must pass)
3. Verify `dist/index.html` exists and is self-contained
4. Test locally: `npm run preview`
5. Upload `dist/index.html` to hotTake.it
6. Test published URL

**Privacy:** Never upload real property data, client names, API keys, or secrets.

---

## Documentation

- **`docs/architecture.md`** — State management, component boundaries, build process
- **`docs/interaction-contract.md`** — Six-phase workflow specification, UX requirements
- **`docs/reference-manifest.md`** — Design language observations, missing reference assets
- **`docs/hottake-handoff.md`** — Deployment instructions, troubleshooting

---

## Constraints & Limitations

**This demo:**

- ✅ Runs entirely in the browser (no backend)
- ✅ Uses only fictional, placeholder data
- ✅ Exports as a single portable HTML file
- ✅ Resets cleanly to starting state
- ❌ Does NOT authenticate users
- ❌ Does NOT store data persistently
- ❌ Does NOT make network requests (except initial load)
- ❌ Does NOT connect to production Porteos systems
- ❌ Does NOT access real property or client data

---

## Next Steps for Implementation Agent

1. Read `docs/interaction-contract.md` — Understand the six-phase workflow
2. Review `docs/reference-manifest.md` — Study visual design language
3. Implement phase components in `src/features/`
4. Wire phase components into `App.tsx` based on `state.phase`
5. Test each phase incrementally with `npm run dev`
6. Run `npm run check` frequently
7. Once complete, build and deploy per `docs/hottake-handoff.md`

---

## License

Private project — not for public distribution without authorization.

---

## Contact

For questions, see `docs/` folder or contact Porteos Intelligence project lead.
