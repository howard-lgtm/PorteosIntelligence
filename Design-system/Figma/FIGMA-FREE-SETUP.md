# Figma setup — no Tokens Studio paid plan

**€49/mo is optional.** For a solo redesign mockup, use **Figma Pro Variables (free)** + optional bulk import.

---

## Option 0 — Upload JSON (fastest, free) ⭐

**You do not need to type hex values one by one.**

### Steps

1. In Figma: **Plugins → Manage plugins → Search community**
2. Install one of these **free** plugins:
   - **[Bulk import Figma variables from file](https://www.figma.com/community/plugin/1563200720170081328)** (recommended — pick JSON, enable grouping)
   - **[JSON to Variables](https://www.figma.com/community/plugin/1557585201560807410)** (paste or upload JSON)
   - **[Variables Import](https://www.figma.com/community/plugin/1253424530216967528)** (use `porteos.tokens.w3c.json` instead)
3. Run the plugin → import this file from your repo:

   **`Design-system/Figma/porteos.figma-import.json`**

   **Note:** This plugin requires `"modes": { "light": {...}, "dark": {...} }`. The file is pre-formatted. Porteos is dark-only — both modes have identical values. After import, use **Dark** mode (or hide Light).

4. Choose **create new collection** when prompted
5. Verify ~25 color variables + 9 number variables appeared

### If import fails

- Try the other plugin from the list
- Or use **`porteos.tokens.w3c.json`** with **Variables Import**
- Fall back to manual entry below (~15 min for colors only)

### Still manual: text styles

Plugins import **Variables**, not **Text styles**. After import, spend ~5 min creating 8 text styles per section 5 below (JetBrains Mono).

---

## Option A — Figma Variables manual (no plugins)

### 1. Create collections

In Figma: **Local variables** panel → create 3 collections:

| Collection | Modes |
|------------|-------|
| `Porteos / Color` | Default only (dark) |
| `Porteos / Profile` | Default only |
| `Porteos / Layout` | Default only |

### 2. Add colors — `Porteos / Color`

Copy hex from `phase-0-cover-spec.md` or paste below:

**Shell**
- `shell/canvas-base` → `#0A0A0A`
- `shell/surface-panel` → `#111111`
- `shell/surface-elevated` → `#1A1A1A`
- `shell/divider` → `#333333`

**Text**
- `text/primary` → `#F8F9FA`
- `text/secondary` → `#94A3B8`
- `text/dim` → `#666666`

**Semantic**
- `semantic/go` → `#27C93F`
- `semantic/warn` → `#FFBD2E`
- `semantic/critical` → `#FF5F56`
- `semantic/info` → `#3B82F6`

**Status**
- `status/pipeline` → `#64748B`
- `status/review` → `#F59E0B`
- `status/viable` → `#27C93F`
- `status/rejected` → `#FF5F56`
- `status/acquired` → `#3B82F6`

### 3. Add colors — `Porteos / Profile`

- `profile/cmd-center` → `#94A3B8`
- `profile/real-estate` → `#C25E30`
- `profile/hospitality` → `#14B8A6`
- `profile/design` → `#A855F7`
- `profile/circular` → `#3B82F6`
- `profile/pipeline` → `#F59E0B`

### 4. Add layout numbers — `Porteos / Layout`

Type: **Float** (or number)

- `layout/nav-width` → `260`
- `layout/inspector-width` → `280`
- `layout/header-height` → `40`
- `layout/command-bar-height` → `32`
- `layout/row-height` → `28`
- `layout/metric-cell-min` → `52`
- `layout/window-width` → `1200`
- `layout/window-height` → `800`

### 5. Typography (free — Text styles, not variables)

**Text → Text styles → +** Create these with **JetBrains Mono**:

| Style name | Size | Weight |
|------------|------|--------|
| score/hero | 36 | Bold |
| score/grade | 20 | Bold |
| metric/value | 16 | Medium |
| metric/label | 11 | Medium, ALL CAPS, tracking +2% |
| row/value | 12 | Medium |
| row/label | 11 | Regular |
| button/primary | 11 | Bold, ALL CAPS |
| meta | 10 | Regular |

### 6. Pages + cover

Follow `PHASE-0-FIGMA-CHECKLIST.md` tasks 0.2 and 0.3 — skip token import.

**Time:** ~25 minutes once.

---

## Option B — Tokens Studio free tier (€0)

The **Starter** plan is free ([tokens.studio/pricing](https://tokens.studio/pricing)). €49 is **Starter PLUS** (multi-file sync, automation).

Free tier may be enough for a **one-time JSON import** into your file. If the plugin asks you to upgrade, **stop** and use Option A instead — don't pay.

---

## Option C — Skip variables entirely

For mockups only, you can:

1. Build the cover page with raw hex from `phase-0-cover-spec.md`
2. Design frames using those hex values directly
3. I map colors back to `DesignTokens.swift` when we implement in SwiftUI

This works fine for a **visual redesign pass** where Figma is exploratory, not the long-term source of truth.

---

## What we use at implementation time

Code authority stays **`PorteosIntelligence/Utilities/DesignTokens.swift`**. Figma is for layout and hierarchy — not a paid plugin dependency.

When mockups are done, share frames or screenshots → I align SwiftUI to your designs.
