# Interaction Contract

**Porteos Intelligence Usability Demo**  
**Six-phase workflow specification**

---

## Phase Table

| Phase          | Tester Goal                                   | Trigger                                                      | State Transition                                    | Required Feedback                                                                                   | Recovery/Reset                                     | Implementation Status |
| -------------- | --------------------------------------------- | ------------------------------------------------------------ | --------------------------------------------------- | --------------------------------------------------------------------------------------------------- | -------------------------------------------------- | --------------------- |
| **Prepare**    | Understand demo purpose and start workflow    | Click "Start Demo" button                                    | `prepare` → `import`                                | Welcome message, profile selection UI appears                                                       | Reset button always visible                        | ⬜ Pending            |
| **Import**     | Select or import a property for evaluation    | Select property from list OR upload file (simulated)         | `import` → `processing`                             | Property card displays, "Analyze" button enabled                                                    | Can go back to property list, reset to start       | ⬜ Pending            |
| **Processing** | Observe AI analysis simulation                | Automatic after import                                       | `processing` → `evaluate`                           | Progress bar, status messages ("Analyzing location...", "Computing scores..."), animated indicators | Cannot interrupt once started, can reset to start  | ⬜ Pending            |
| **Evaluate**   | Review scores, signals, and intelligence tabs | Switch between profile tabs (Real Estate, Hospitality, etc.) | Stays in `evaluate` until "Generate Report" clicked | Score hero (0-100), 5 sentiment bars, tabbed dashboards, profile-specific metrics                   | Can switch profiles freely, reset to start         | ⬜ Pending            |
| **Report**     | Preview generated report and finish demo      | Click "Generate Report" (PDF or JSON)                        | `evaluate` → `report` → `complete`                  | Report preview panel, download simulation, "Finish" button                                          | Can regenerate in different format, reset to start | ⬜ Pending            |
| **Complete**   | Understand demo is finished, start over       | Click "Reset Demo"                                           | `complete` → `prepare`                              | Completion message, reset button prominent                                                          | Reset is only action available                     | ⬜ Pending            |

---

## Interaction Details

### Phase 1: Prepare

**Entry state:** Demo loads  
**Tester sees:**

- Welcome heading: "Porteos Intelligence"
- Brief description of what the demo simulates
- Profile selector (5 options: Real Estate, Hospitality, Design, Circular, Global)
- Large "Start Demo" button

**Tester can:**

- Select different profiles (changes accent color theme)
- Click "Start Demo" to proceed

**Feedback requirements:**

- Profile selection shows visual confirmation (border highlight, accent color)
- "Start Demo" button is keyboard-accessible (Tab + Enter)
- Hover states on all interactive elements

**Error states:** None (no invalid input possible)

---

### Phase 2: Import

**Entry state:** After "Start Demo" clicked  
**Tester sees:**

- Property selector: List of 3 fictional properties with key details
- "Upload Property Data" button (simulated, no real file upload)

**Tester can:**

- Click a property card to select it
- Click "Upload" to simulate file import (selects first property by default)
- Click "Back" to return to Prepare phase

**Feedback requirements:**

- Selected property card highlights with orange border
- Property details display in expanded card
- "Analyze This Property" button appears when property selected
- Click target size ≥ 44px

**Error states:**

- If no property selected and "Analyze" clicked, show inline error: "Please select a property first"

---

### Phase 3: Processing

**Entry state:** After "Analyze" clicked  
**Tester sees:**

- Progress bar (0% → 100%)
- Status messages updating every ~500ms:
  - "Analyzing location data..."
  - "Evaluating market conditions..."
  - "Computing sentiment signals..."
  - "Generating intelligence scores..."
- Processing cannot be interrupted

**Tester can:**

- Only observe (no interactive controls except Reset)

**Feedback requirements:**

- Smooth progress animation (respect `prefers-reduced-motion`)
- Clear loading indicators
- Processing completes in 3-5 seconds

**Error states:** None (simulated, cannot fail)

---

### Phase 4: Evaluate

**Entry state:** After processing completes  
**Tester sees:**

- Hero score (0-100) with grade letter (A+, B, etc.) and verdict (STRONG, NEUTRAL, WEAK)
- 5 sentiment signal bars:
  - SENTIMENT: LOCATION
  - SENTIMENT: TIMING
  - SENTIMENT: CASH FLOW
  - SENTIMENT: RISK
  - SENTIMENT: ESG
- Tabbed dashboard views (varies by active profile)
- "Generate Report" button

**Tester can:**

- Switch between profile tabs (Real Estate, Hospitality, Design, Circular, Global)
- Hover over bars to see exact values (tooltip or inline text)
- Click "Generate Report" to proceed

**Feedback requirements:**

- Tab switching is instant (no loading)
- Active tab has visual indicator (underline, background)
- Score and bars animate in on first display
- Profile accent color applied to active tab

**Error states:** None (all data is preloaded)

---

### Phase 5: Report

**Entry state:** After "Generate Report" clicked  
**Tester sees:**

- Report format selector (PDF or JSON)
- Preview panel showing report cover or data structure
- "Download" button (simulated, triggers browser download)
- "Finish Demo" button

**Tester can:**

- Switch between PDF/JSON format
- Click "Download" (simulates file download with fictional data)
- Click "Finish Demo" to complete

**Feedback requirements:**

- Format selector shows visual selection state
- Preview updates when format changes
- "Download" shows confirmation message after click
- "Finish Demo" button is prominent

**Error states:** None (all actions succeed)

---

### Phase 6: Complete

**Entry state:** After "Finish Demo" clicked  
**Tester sees:**

- Completion message: "Demo complete. Thank you for testing Porteos Intelligence."
- Large "Reset Demo" button
- Summary stats (optional): Properties analyzed, time spent, etc.

**Tester can:**

- Click "Reset Demo" to return to Prepare phase

**Feedback requirements:**

- Reset button is keyboard-accessible
- Reset confirmation (optional): "Are you sure? This will clear all demo data."

**Error states:** None

---

## Global Recovery

**Reset Button:**

- Visible in header/footer at all times
- Always functional (even during Processing phase)
- Returns state to `prepare`, clears all selections
- Keyboard shortcut: `Ctrl+R` or `Cmd+R` (optional enhancement)

**Browser Refresh:**

- Reloads demo to initial state (no persistence)
- No broken states possible

---

## Accessibility Requirements

All phases must:

- Support keyboard navigation (Tab, Enter, Escape)
- Provide focus indicators (visible outline on focused elements)
- Use semantic HTML (`<button>`, `<nav>`, `<main>`, `<article>`)
- Include ARIA labels where text is ambiguous
- Respect `prefers-reduced-motion` (disable animations)
- Maintain ≥ 4.5:1 contrast ratio for text

---

## Implementation Checklist

- [ ] Prepare phase UI
- [ ] Import phase UI (property selector + cards)
- [ ] Processing phase animation
- [ ] Evaluate phase (hero score + bars + tabs)
- [ ] Report phase (format selector + preview)
- [ ] Complete phase (summary + reset)
- [ ] Global reset button
- [ ] Keyboard navigation
- [ ] Focus states
- [ ] Reduced motion support
- [ ] E2E test for full workflow
