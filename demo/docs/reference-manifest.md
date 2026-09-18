# Reference Manifest

**Generated:** 2026-09-18  
**Purpose:** Catalog visual reference material for Porteos Intelligence demo implementation

## Reference Images Status

### Requested but Missing

The following paths were specified in the implementation brief but are not present in the repository:

**Guided workflow frames:**

- `.figma/imports/451_593.png` ❌
- `.figma/imports/451_657.png` ❌
- `.figma/imports/451_714.png` ❌
- `.figma/imports/451_771.png` ❌

**Product screenshots:**

- `.figma/attachments/d307b512ca223b71172cdf1bc373b8d50324f5fc/Screenshot 2026-09-16 at 12.59.30.png` ❌
- `.figma/attachments/32b2185abff258b807ccc65772aa226ee5f1f01a/Screenshot 2026-09-16 at 12.59.42.png` ❌
- `.figma/attachments/9dfcbd32872172d380446f16349a028b26e07983/Screenshot 2026-09-16 at 13.00.32.png` ❌
- `.figma/attachments/c597c0eb79c35a0a946fdea41ae9455925019357/Screenshot 2026-09-16 at 12.59.53.png` ❌
- `.figma/attachments/33fded7aa4eb6f1fb972eff33655efbb7f2d32d8/Screenshot 2026-09-16 at 13.00.42.png` ❌
- `.figma/attachments/a540001551e54715eb5b84443f6cbfbe9d595079/Screenshot 2026-09-16 at 13.00.17.png` ❌
- `.figma/attachments/4c39733af05429b30274282185f813075987fac2/Screenshot 2026-09-16 at 12.59.36.png` ❌

### Available Alternatives

**Cursor-provided screenshots** (saved during scaffold setup):

1. Property detail view — Andrew Freeman Hotel ✓
2. Portfolio overview — €22M total value ✓
3. Circular Economy dashboard ✓
4. Hospitality dashboard ✓
5. Real Estate dashboard ✓
6. Design dashboard ✓
7. Global Intelligence map view ✓

**Existing repository assets:**

- `Design-system/Figma/visual-targets/` — Multiple PNG screenshots
- `Design-system/Figma/Global_Intelligence/` — Dashboard variants

## Observed Design Language

From available screenshots and existing `Design-system/` assets:

### Visual Aesthetic

- **Dense terminal/operator-console interface**
- Near-black backgrounds (`#0A0A0A`, `#121212`)
- Thin, subtle dividers and borders
- Monospaced typography throughout
- High information density with clear visual hierarchy

### Color Palette

- **Primary action:** Orange (`#FF6B35`)
- **Profile accents:**
  - Real Estate: Blue (`#4895EF`)
  - Hospitality: Teal (`#00D4AA`)
  - Design: Purple (`#9D4EDD`)
  - Circular Economy: Green (`#06D6A0`)
  - Global Intelligence: Cyan (`#00B4D8`)
- **Status indicators:**
  - Success/positive: Green (`#06D6A0`)
  - Warning: Yellow (`#FFD166`)
  - Critical/negative: Red (`#EF476F`)

### Layout Structure

- **Three-column layout:**
  - Left: Navigation/deal selector
  - Center: Primary analytical workspace
  - Right: Inspector panel/context
- **Modular dashboard sections** with consistent spacing
- **Tab-based profile switching** (Real Estate, Hospitality, Design, Circular, Global)

### Typography

- Monospace font family
- Small font sizes (0.75rem–0.875rem base)
- Uppercase labels with letter-spacing
- Numeric data emphasized with size/weight

### Data Visualization

- Horizontal bar charts for metrics
- Color-coded sentiment signals
- Percentage values with visual progress indicators
- Score badges with grade classifications
- Geographic map integration

## Implementation Notes

**For the next coding agent:**

1. Do NOT use these screenshots as flattened backgrounds
2. All UI elements must be semantic HTML/React components
3. Extract colors, spacing, typography from token system (`src/styles/tokens.css`)
4. Match visual density and information hierarchy
5. Ensure all controls are keyboard-navigable
6. Support `prefers-reduced-motion`
7. Minimum 44px click targets for interactive elements

## Missing Assets Protocol

If workflow frame images become available:

1. Place in `demo/public/references/`
2. Update this manifest
3. Use as visual reference only (not embedded in final build)
