# Porteos Intelligence Demo — Implementation Brief

**For the UI implementation agent**  
**Last updated:** 2026-09-18  
**Status:** Scaffold complete, UI implementation pending

---

## Your Mission

Build a realistic, interactive browser-based demo of the Porteos Intelligence workflow using the existing scaffold infrastructure. The demo must simulate a believable user experience without connecting to any production systems.

**Critical:** This is a usability testing prototype, not the real product. Use fictional data only.

---

## What You're Building

A **four-step guided workflow** demonstrating Porteos Intelligence:

1. **Prepare** — Welcome screen, profile selection
2. **Import** — Property selection or simulated file upload
3. **Evaluate** — AI-generated scores, sentiment signals, profile-specific dashboards
4. **Report** — PDF/JSON report preview and completion

**Target audience:** Stakeholders, investors, beta testers  
**Deployment:** Single HTML file uploaded to hotTake.it  
**Timeline:** Complete, tested, and documented

---

## Context: What Already Exists

### ✅ Scaffold Infrastructure (Complete)

**Location:** `demo/` directory in the Porteos Intelligence repository

**What's ready:**

- Vite + React + TypeScript project configured
- State management: `useReducer` with typed actions/state
- 6-phase state model: `prepare → import → processing → evaluate → report → complete`
- CSS token system with Porteos color palette
- Fictional demo data (3 properties, sample evaluation)
- Test setup (Vitest + Playwright)
- Build pipeline → single-file HTML output

**What you DON'T need to do:**

- ❌ Set up build tools or dependencies
- ❌ Configure TypeScript or linting
- ❌ Create state management from scratch
- ❌ Define types or interfaces
- ❌ Set up testing infrastructure

**What you DO need to do:**

- ✅ Implement UI components for each phase
- ✅ Wire components into the existing reducer
- ✅ Style with the existing token system
- ✅ Add animations and transitions
- ✅ Test the complete flow

---

## Design Language (Visual Reference)

### Available References

**User-provided screenshots** (7 images in Cursor assets):

1. Property detail — Andrew Freeman Hotel
2. Portfolio overview — €22M total
3. Circular Economy dashboard
4. Hospitality dashboard
5. Real Estate dashboard
6. Design dashboard
7. Global Intelligence map

**Additional assets:**

- `Design-system/Figma/` directory with more screenshots
- `docs/reference-manifest.md` catalogs all available references

### Visual Aesthetic to Match

**Terminal/operator console interface:**

- Near-black backgrounds (`#0A0A0A`, `#121212`)
- Thin, subtle borders (`#2A2A2A`)
- Monospaced typography throughout
- High information density
- Orange primary actions (`#FF6B35`)
- Profile-specific accent colors:
  - Real Estate: Blue (`#4895EF`)
  - Hospitality: Teal (`#00D4AA`)
  - Design: Purple (`#9D4EDD`)
  - Circular Economy: Green (`#06D6A0`)
  - Global Intelligence: Cyan (`#00B4D8`)

**Layout pattern:**

- Three-column when appropriate (nav | workspace | inspector)
- Tab-based profile switching
- Horizontal bar charts for metrics
- Score badges with letter grades
- Uppercase labels with letter-spacing

**All design tokens are defined in `src/styles/tokens.css`** — use CSS custom properties, not hardcoded hex values.

---

## Phase-by-Phase Implementation Guide

### Phase 1: Prepare

**User sees:**

- Large "Porteos Intelligence" heading
- Tagline: "AI-powered property intelligence for smarter decisions"
- Brief description (2-3 sentences) explaining the demo
- Profile selector (5 cards in a grid):
  - Real Estate
  - Hospitality
  - Design
  - Circular Economy
  - Global Intelligence
- Each card shows icon, name, and 1-sentence description
- Large orange "Start Demo" button at bottom

**User can:**

- Click a profile card to select it (highlights with profile accent color)
- Click "Start Demo" to proceed

**State changes:**

- On card click: `dispatch({ type: 'SWITCH_PROFILE', payload: 'hospitality' })`
- On "Start Demo": `dispatch({ type: 'START_DEMO' })` → transitions to `import` phase

**Design notes:**

- Center-aligned, spacious layout
- Profile cards should be 44px min height click targets
- Selected card gets border highlight + subtle background
- Hover states on all interactive elements

---

### Phase 2: Import

**User sees:**

- Heading: "Select Property"
- Property selector: 3 cards displaying fictional properties from `src/data/demoData.ts`
- Each card shows:
  - Property name (e.g., "Riverside Plaza")
  - Location (e.g., "Portland, OR")
  - Type (e.g., "Commercial Mixed-Use")
  - Value (e.g., "$8.5M")
- "Upload Property Data" button (simulated, non-functional)
- Selected property expands or highlights
- "Analyze This Property" button appears when property is selected

**User can:**

- Click a property card to select it
- Click "Analyze" to start processing
- Click "Back" to return to Prepare phase (optional)

**State changes:**

- On property click: `dispatch({ type: 'SELECT_PROPERTY', payload: propertyData })`
- On "Analyze": `dispatch({ type: 'START_PROCESSING' })` → transitions to `processing` phase

**Design notes:**

- Property cards in vertical list or grid
- Selected card gets orange border
- Property details visible inline or in expanded state
- "Upload" button is styled but disabled (demo constraint)

---

### Phase 3: Processing

**User sees:**

- Heading: "Analyzing Property"
- Progress bar (0% → 100%)
- Status messages updating every ~500ms:
  1. "Analyzing location data..."
  2. "Evaluating market conditions..."
  3. "Computing sentiment signals..."
  4. "Generating intelligence scores..."
  5. "Finalizing report..."
- Property name displayed at top
- No interactive controls except Reset (in header/footer)

**User can:**

- Only observe (no interactivity)

**Implementation approach:**

```typescript
useEffect(() => {
  if (state.phase === 'processing') {
    const interval = setInterval(() => {
      // Update progress 0 → 100 over ~3-5 seconds
      // Change status message at milestones
    }, 500)

    setTimeout(() => {
      dispatch({
        type: 'COMPLETE_PROCESSING',
        payload: DEMO_EVALUATION, // from src/data/demoData.ts
      })
    }, 5000) // 5 second processing simulation

    return () => clearInterval(interval)
  }
}, [state.phase])
```

**State changes:**

- Automatic progression to `evaluate` phase after 5 seconds
- Use `dispatch({ type: 'UPDATE_PROGRESS', payload: { current, total, message } })` for updates
- Final: `dispatch({ type: 'COMPLETE_PROCESSING', payload: evaluationResult })`

**Design notes:**

- Respect `prefers-reduced-motion` (disable animation if user prefers)
- Smooth progress bar animation
- Status text fades in/out or slides up

---

### Phase 4: Evaluate

**This is the core demo experience.** Most complex phase.

**User sees:**

#### Hero Score Section (top)

- Large score: 0-100 (e.g., "87")
- Grade letter: A+, A, B+, B, C+, C, D, F (derived from score)
- Verdict badge: STRONG / NEUTRAL / WEAK / TIGHT (color-coded)
- Property name as context

#### Sentiment Signals (middle)

5 horizontal bar charts with labels:

1. **SENTIMENT: LOCATION** (0-100, color: profile accent)
2. **SENTIMENT: TIMING** (0-100, color: profile accent)
3. **SENTIMENT: CASH FLOW** (0-100, color: profile accent)
4. **SENTIMENT: RISK** (0-100, color: profile accent)
5. **SENTIMENT: ESG** (0-100, color: profile accent)

Each bar:

- Shows percentage value on right
- Filled portion uses profile accent color
- Background is subtle gray
- Animates in on first display (left-to-right fill)

#### Profile Tabs (bottom)

Tabs for switching intelligence profiles:

- Real Estate
- Hospitality
- Design
- Circular Economy
- Global Intelligence

**Tab content:**
Display 3-5 key metrics per profile (simplified from screenshots):

**Real Estate:**

- Cap Rate: X.X%
- Cash-on-Cash Return: X%
- IRR: X%
- Market Rent Growth: +X%
- Comparable Sales: X properties

**Hospitality:**

- ADR (Average Daily Rate): $XXX
- Occupancy Rate: XX%
- RevPAR: $XXX
- Seasonal Demand: High/Medium/Low
- Comp Set Performance: +X%

**Design:**

- Space Efficiency: XX%
- Natural Light Score: X/10
- Material Flow Rate: X kg/m²
- Biophilic Elements: X
- ADA Compliance: XX%

**Circular Economy:**

- Recycled Content: XX%
- Water Recycling: X%
- Waste Diversion: XX%
- Embodied Carbon: X tCO2e
- Circularity Score: XX/100

**Global Intelligence:**

- Market Stability: XX/100
- Political Risk: Low/Medium/High
- Currency Exposure: $XXX
- Cross-border Flow: $X.XM
- Regulatory Compliance: XX%

_Note: Use fictional values from `src/data/demoData.ts` or generate simple placeholder data._

#### Bottom Action

- Large "Generate Report" button (orange)

**User can:**

- Switch between profile tabs (instant, no loading)
- Hover over bars to see exact values (optional tooltip)
- Click "Generate Report" to proceed

**State changes:**

- On tab click: `dispatch({ type: 'SWITCH_PROFILE', payload: 'design' })`
- On "Generate Report": `dispatch({ type: 'GENERATE_REPORT', payload: 'pdf' })` → `report` phase

**Design notes:**

- Hero score is large and prominent (48-72px font size)
- Grade letter uses semantic color (green = good, yellow = okay, red = poor)
- Sentiment bars should animate in sequentially (stagger by 100ms each)
- Active tab has underline or background highlight
- Tab content fades in when switching (150ms transition)
- Use `var(--color-profile-${activeProfile})` for accent color

---

### Phase 5: Report

**User sees:**

- Heading: "Report Generated"
- Format selector: PDF | JSON (toggle or radio buttons)
- Preview panel:
  - **If PDF:** Show mock report cover with property name, score, date
  - **If JSON:** Show formatted JSON snippet (first 10-15 lines)
- "Download Report" button (simulated)
- "Finish Demo" button

**User can:**

- Switch between PDF/JSON format (updates preview)
- Click "Download" → shows confirmation toast "Report downloaded" (no actual file)
- Click "Finish Demo" → proceeds to Complete phase

**State changes:**

- On format toggle: Update local state (or use `dispatch` if tracking format)
- On "Download": Show confirmation (no state change)
- On "Finish": `dispatch({ type: 'COMPLETE_DEMO' })` → `complete` phase

**Implementation:**

```typescript
const handleDownload = () => {
  // Simulate download (no actual file)
  alert('✓ Report downloaded to your computer')
  // Or use a toast notification component
}
```

**Design notes:**

- Preview panel has border, looks like a document/code editor
- PDF preview shows stylized report cover (use CSS, not an image)
- JSON preview uses monospace font, syntax-highlighted if possible (or just gray text)
- "Download" button is secondary style (outline or muted)
- "Finish Demo" is primary orange button

---

### Phase 6: Complete

**User sees:**

- Large checkmark or success icon
- Heading: "Demo Complete"
- Message: "Thank you for exploring Porteos Intelligence"
- Optional: Summary stats (e.g., "1 property analyzed", "5 profiles explored")
- Large "Reset Demo" button

**User can:**

- Click "Reset Demo" → returns to Prepare phase

**State changes:**

- On "Reset": `dispatch({ type: 'RESET_DEMO' })` → back to `prepare` phase

**Design notes:**

- Centered, minimal layout
- Celebratory tone (success green accent)
- Reset button is prominent and obvious

---

## Global UI Elements

### Header (persistent across all phases)

- "Porteos Intelligence" logo/wordmark (left)
- Current phase indicator (optional, subtle)
- "Reset Demo" button (right, always visible)

### Footer (optional)

- Demo disclaimer: "Fictional data for demonstration purposes only"
- Phase progress indicator: 1 of 4, 2 of 4, etc. (optional)

---

## Accessibility Requirements

**Must support:**

- Keyboard navigation (Tab, Enter, Escape)
- Focus indicators (visible outline on all interactive elements)
- Semantic HTML (`<button>`, `<nav>`, `<main>`, `<article>`)
- ARIA labels where needed (`aria-label`, `aria-describedby`)
- Minimum 44px click targets
- 4.5:1 contrast ratio for all text
- `prefers-reduced-motion` support (disable animations)

**Test checklist:**

- [ ] Can complete full workflow using only keyboard
- [ ] Focus ring visible on all interactive elements
- [ ] Screen reader announces phase changes (use `aria-live` regions)
- [ ] No keyboard traps
- [ ] Buttons have descriptive labels

---

## State Integration

### Wiring Your Components

Your components should read from and dispatch to the existing reducer:

```typescript
import { useReducer } from 'react'
import { demoReducer } from './app/demoReducer'
import { initialDemoState } from './app/demoState'

export function App() {
  const [state, dispatch] = useReducer(demoReducer, initialDemoState)

  // Render different phase components based on state.phase
  return (
    <main>
      {state.phase === 'prepare' && <PreparePhase dispatch={dispatch} state={state} />}
      {state.phase === 'import' && <ImportPhase dispatch={dispatch} state={state} />}
      {state.phase === 'processing' && <ProcessingPhase state={state} />}
      {state.phase === 'evaluate' && <EvaluatePhase dispatch={dispatch} state={state} />}
      {state.phase === 'report' && <ReportPhase dispatch={dispatch} state={state} />}
      {state.phase === 'complete' && <CompletePhase dispatch={dispatch} />}
    </main>
  )
}
```

### Available Actions

See `src/types/demo.ts` for complete action types:

```typescript
dispatch({ type: 'START_DEMO' })
dispatch({ type: 'SELECT_PROPERTY', payload: propertyData })
dispatch({ type: 'START_PROCESSING' })
dispatch({ type: 'UPDATE_PROGRESS', payload: { current: 50, total: 100, message: '...' } })
dispatch({ type: 'COMPLETE_PROCESSING', payload: evaluationResult })
dispatch({ type: 'SWITCH_PROFILE', payload: 'hospitality' })
dispatch({ type: 'GENERATE_REPORT', payload: 'pdf' })
dispatch({ type: 'COMPLETE_DEMO' })
dispatch({ type: 'RESET_DEMO' })
```

---

## Styling Guide

### Use CSS Tokens

**Always use CSS custom properties from `src/styles/tokens.css`:**

```css
/* Good */
.button {
  background-color: var(--color-orange-primary);
  padding: var(--space-3) var(--space-6);
  font-family: var(--font-mono);
}

/* Bad */
.button {
  background-color: #ff6b35;
  padding: 0.75rem 1.5rem;
  font-family: monospace;
}
```

### Component CSS Files

Create scoped CSS files per component:

```
src/features/prepare/PreparePhase.css
src/features/import-property/ImportPhase.css
src/features/evaluate/EvaluatePhase.css
src/features/report/ReportPhase.css
```

Import in component:

```typescript
import './PreparePhase.css'
```

### Responsive Design

**Minimum supported viewport:** 1024px wide (desktop only for MVP)  
**Optional:** Support 768px+ for tablets (but not required)

---

## Animation Guidelines

### Timing

- **Fast interactions:** 150ms (hover, focus)
- **Phase transitions:** 250ms (content fade in/out)
- **Processing animations:** 350ms+ (progress bars, loaders)

### Easing

Use CSS custom properties:

```css
transition: all var(--transition-fast); /* 150ms ease */
transition: all var(--transition-base); /* 250ms ease */
transition: all var(--transition-slow); /* 350ms ease */
```

### Reduced Motion

Always wrap animations:

```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## Development Workflow

### 1. Start Dev Server

```bash
cd demo
npm run dev
```

Opens at `http://localhost:5173/` with hot reload.

### 2. Implement Phase by Phase

**Recommended order:**

1. Prepare phase (simplest)
2. Import phase
3. Complete phase
4. Evaluate phase (most complex)
5. Report phase
6. Processing phase (animation)

Test each phase independently before moving to next.

### 3. Run Checks Frequently

```bash
npm run typecheck  # TypeScript errors
npm run lint       # ESLint errors
npm run format     # Auto-fix formatting
npm run test       # Unit tests
```

### 4. Test Full Workflow

- Complete the entire flow manually
- Test reset from each phase
- Test keyboard navigation
- Test with reduced motion enabled

### 5. Build and Verify

```bash
npm run build
npm run preview  # Test production build locally
```

Verify:

- [ ] `dist/index.html` exists
- [ ] File size < 1MB
- [ ] No console errors
- [ ] Works offline (disable network in DevTools)

---

## Testing Requirements

### Unit Tests to Add

Update existing tests in `src/app/App.test.tsx`:

- [ ] Each phase component renders
- [ ] Buttons dispatch correct actions
- [ ] State updates trigger re-renders

### E2E Test to Add

Update `tests/smoke.spec.ts`:

- [ ] Complete full workflow (Prepare → Complete)
- [ ] Reset button works from each phase
- [ ] Keyboard navigation works
- [ ] No console errors during workflow

Run:

```bash
npx playwright install chromium  # One-time setup
npm run test:e2e
```

---

## Completion Criteria

Before marking this complete:

- [ ] All 6 phases implemented and functional
- [ ] Keyboard navigation works (Tab through all interactive elements)
- [ ] Visual design matches Porteos aesthetic (terminal style, correct colors)
- [ ] Animations respect `prefers-reduced-motion`
- [ ] `npm run check` passes (typecheck + lint + format + test + build)
- [ ] Production build works (`npm run preview` loads without errors)
- [ ] `dist/index.html` is self-contained (no external resources)
- [ ] File size < 1MB
- [ ] E2E smoke test passes
- [ ] README.md updated with "Status: Complete"

---

## Deployment (When Complete)

Follow `docs/hottake-handoff.md` for deployment instructions.

**Quick steps:**

1. Run `npm run check` (must pass)
2. Verify `dist/index.html` (check size, test offline)
3. Upload to hotTake.it
4. Test published URL

---

## Questions?

**Reference documentation:**

- `docs/architecture.md` — State management, component boundaries
- `docs/interaction-contract.md` — Detailed phase specifications
- `docs/reference-manifest.md` — Design language, missing assets
- `docs/hottake-handoff.md` — Deployment instructions

**Need clarification?** Document assumptions in comments and proceed. This is a demo, not production — prioritize believability over pixel-perfection.

---

## Anti-Patterns to Avoid

**Don't:**

- ❌ Add real API calls or network requests
- ❌ Use production Porteos data or real property addresses
- ❌ Download fonts from CDN (use system fonts only)
- ❌ Embed large images (keep build < 1MB)
- ❌ Add authentication or user accounts
- ❌ Store data in localStorage (demo resets on refresh)
- ❌ Use hash routing or browser history (single-page, no routes)
- ❌ Install additional UI frameworks (use plain React + CSS)

**Do:**

- ✅ Use fictional data from `src/data/demoData.ts`
- ✅ Keep everything deterministic (no random values in production)
- ✅ Style with existing CSS tokens
- ✅ Make it keyboard-accessible
- ✅ Test the complete flow frequently
- ✅ Keep build output small and self-contained

---

## Estimated Scope

**Complexity breakdown:**

- **Prepare phase:** 1-2 hours (simple selection UI)
- **Import phase:** 2-3 hours (property cards + selection)
- **Complete phase:** 1 hour (success screen)
- **Evaluate phase:** 6-8 hours (hero score + bars + tabs + metrics)
- **Report phase:** 2-3 hours (preview + format toggle)
- **Processing phase:** 2-3 hours (animation + state management)
- **Testing + polish:** 3-4 hours (E2E tests, keyboard nav, accessibility)

**Total:** ~20-25 hours for full implementation

---

**Ready to build.** Start with Prepare phase and work your way through. Good luck! 🚀
