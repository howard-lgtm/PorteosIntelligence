# Architecture

**Porteos Intelligence Usability Demo**  
**Stack:** Vite + React + TypeScript

---

## Design Principles

1. **Browser-only execution** — No backend, no authentication, no network calls after load
2. **Deterministic state** — Predictable, testable, resettable
3. **Single-file output** — All assets inlined for hotTake.it upload
4. **Fictional data only** — No production connections, no real client information

---

## Project Structure

```
demo/
├── src/
│   ├── app/              # Root component & state management
│   │   ├── App.tsx       # Main component with useReducer
│   │   ├── demoReducer.ts # State transitions
│   │   └── demoState.ts   # Initial state
│   ├── components/       # Shared UI primitives (future)
│   ├── features/         # Phase-specific screens (future)
│   │   ├── prepare/
│   │   ├── import-property/
│   │   ├── evaluate/
│   │   └── report/
│   ├── data/             # Fictional demo data
│   ├── styles/           # CSS tokens, reset, global
│   ├── types/            # TypeScript interfaces
│   └── test/             # Vitest setup
├── tests/                # Playwright E2E
└── docs/                 # This file + handoff docs
```

---

## State Management

### Why `useReducer` is Sufficient

- **Single source of truth** — One reducer, one state object
- **Predictable transitions** — Explicit actions, no side effects
- **Easy to test** — Pure function, no framework coupling
- **No async complexity** — Demo flow is synchronous
- **Resettable** — `RESET_DEMO` action restores initial state

### State Shape

```typescript
DemoState {
  phase: 'prepare' | 'import' | 'processing' | 'evaluate' | 'report' | 'complete'
  selectedProperty: PropertyData | null
  importedFiles: ImportedFile[]
  processingProgress: ProcessingProgress | null
  activeProfile: IntelligenceProfile
  evaluationResult: EvaluationResult | null
  reportState: ReportState
  isComplete: boolean
}
```

### Phase Transitions

```
prepare → import → processing → evaluate → report → complete
                        ↓
                    (can reset to prepare at any time)
```

---

## Component Boundaries

### Current (Scaffold)

- `App.tsx` — Single component with state, header, status display, reset button

### Future Implementation

- `PreparePhase` — Welcome screen, profile selection
- `ImportPhase` — Property selector, file uploader (simulated)
- `ProcessingPhase` — Progress indicator, status messages
- `EvaluatePhase` — Score display, signal bars, dashboard tabs
- `ReportPhase` — PDF/JSON export preview, completion

**Recommendation:** Keep components colocated by feature phase, not by UI primitive type.

---

## Data Management

### Mock Data Location

- `src/data/demoData.ts` — Fictional properties, evaluation results

### Principles

- **No external data sources** — Everything is hardcoded
- **Realistic but safe** — Plausible values, no real addresses/entities
- **Easily swappable** — Agent can replace with different scenarios

### Anti-Pattern to Avoid

Do NOT couple layout directly to data shape. Use TypeScript interfaces to define contracts, then map data to UI.

---

## Build Output (Single-File HTML)

### How It Works

1. Vite bundles all source code into `dist/assets/`
2. `vite-plugin-singlefile` inlines JS/CSS into `dist/index.html`
3. Result: One portable HTML file, no external dependencies

### Configuration

See `vite.config.ts`:

- `viteSingleFile()` plugin enabled
- `assetsInlineLimit` set very high (100MB)
- `inlineDynamicImports: true`

### Verification

```bash
npm run build
ls -lh dist/index.html  # Should exist, ~100-500KB
open dist/index.html    # Should run without local server
```

---

## Testing Strategy

### Unit Tests (Vitest)

- **State reducer** — All phase transitions, reset behavior
- **Component rendering** — Scaffold displays correctly

### E2E Tests (Playwright)

- **Smoke test** — App loads, no console errors
- **Interactivity** — Reset button works, keyboard navigation
- **Build artifact** — `dist/index.html` exists and is self-contained

### What NOT to Test

- Unimplemented UI (will change rapidly during build)
- Visual regression (no baseline yet)
- Complex interactions (demo is linear, not exploratory)

---

## Styling Approach

### Token System

`src/styles/tokens.css` defines semantic variables:

- Colors (background, text, borders, accents)
- Spacing scale (0.25rem → 4rem)
- Typography scale + monospace font
- Z-index layers
- Transition speeds

### CSS Architecture

- **Reset** → normalize browser defaults
- **Tokens** → design system variables
- **Global** → body, focus states, motion preferences
- **Component** → scoped CSS per component (e.g., `App.css`)

### Why Not Tailwind/CSS-in-JS

- Keeps bundle size minimal
- No runtime overhead
- Easier for non-React agents to modify
- Plain CSS is universally readable

---

## Future Implementation Guidance

### Adding a New Phase

1. Create `src/features/<phase-name>/index.tsx`
2. Add action types to `src/types/demo.ts`
3. Handle actions in `demoReducer.ts`
4. Conditionally render phase component in `App.tsx`

### Adding Mock Data

1. Define TypeScript interface in `src/types/demo.ts`
2. Add fictional data to `src/data/demoData.ts`
3. Wire into state via action payload

### Styling New Components

1. Import token variables: `var(--color-bg-panel)`
2. Respect spacing scale: `var(--space-4)`
3. Use semantic color names (not hex codes directly)
4. Test with `prefers-reduced-motion: reduce`

---

## Constraints & Limitations

### What This Demo Cannot Do

- Authenticate users
- Store data persistently
- Make network requests (except initial load)
- Connect to production Porteos systems
- Access real property or client data

### What It Must Do

- Run entirely in the browser after initial load
- Reset cleanly to starting state
- Simulate a believable Porteos workflow
- Export as a single portable HTML file
- Remain accessible and keyboard-navigable
