# Figma Text Styles — Porteos V2.06

Exact values from `DesignTokens.swift` + `phase-0-cover-spec.md`.  
**Page:** Cover & Tokens · **Font:** JetBrains Mono (install on Mac first)

---

## Before you start

1. **Page fill:** Design panel → Page → fill → variable **`shell/canvas-base`** (`#0A0A0A`)
2. **Frame (optional):** Press **F** → draw **1200 × 2400** → name `Cover — Porteos Intelligence v2.06`
3. Press **T** (Text) — all styles are created from typed samples on canvas

---

## How to save each style (repeat 10×)

1. **T** → click canvas → type the **Sample text** below
2. Right panel → **Text** section — set every field in the table exactly
3. Fill color → click swatch → **Libraries** tab → **Porteos** collection → pick **Color** variable
4. Right panel → **Styles** → **Text** → **+** (plus)
5. Name exactly as **Style name** (slashes create folders)

---

## Style definitions

### 1. `Porteos/score/hero`

| Field | Value |
|-------|--------|
| Font | JetBrains Mono |
| Weight | **Bold** (700) |
| Size | **36** |
| Line height | **40** (Fixed) |
| Letter spacing | **0** |
| Case | As typed |
| Fill | Variable **`text/primary`** |
| Sample text | `87` |

---

### 2. `Porteos/score/grade`

| Field | Value |
|-------|--------|
| Font | JetBrains Mono |
| Weight | **Bold** (700) |
| Size | **20** |
| Line height | **24** (Fixed) |
| Letter spacing | **0** |
| Fill | Variable **`text/primary`** *(grade color applied per component)* |
| Sample text | `A` |

---

### 3. `Porteos/metric/value`

| Field | Value |
|-------|--------|
| Font | JetBrains Mono |
| Weight | **SemiBold** (600) — if missing, use **Medium** (500) |
| Size | **16** |
| Line height | **20** (Fixed) |
| Letter spacing | **-2%** (or **-0.32** px) |
| Fill | Variable **`text/primary`** |
| Sample text | `€125,000` |
| OpenType | Enable **Tabular numbers** / **Lining figures** if shown in Type details |

---

### 4. `Porteos/metric/label`

| Field | Value |
|-------|--------|
| Font | JetBrains Mono |
| Weight | **Medium** (500) |
| Size | **11** |
| Line height | **14** (Fixed) |
| Letter spacing | **+2%** (or **+0.22** px) |
| Case | **UPPERCASE** (Type settings → uppercase icon, or type in caps) |
| Fill | Variable **`text/dim`** |
| Sample text | `NET OPERATING INCOME` |

---

### 5. `Porteos/row/value`

| Field | Value |
|-------|--------|
| Font | JetBrains Mono |
| Weight | **Medium** (500) |
| Size | **12** |
| Line height | **16** (Fixed) |
| Letter spacing | **0** |
| Fill | Variable **`text/primary`** |
| Sample text | `6.20%` |
| OpenType | Tabular numbers ON |

---

### 6. `Porteos/row/label`

| Field | Value |
|-------|--------|
| Font | JetBrains Mono |
| Weight | **Regular** (400) |
| Size | **11** |
| Line height | **14** (Fixed) |
| Letter spacing | **+2%** |
| Case | **UPPERCASE** |
| Fill | Variable **`text/dim`** |
| Sample text | `CAP RATE` |

---

### 7. `Porteos/cli/prompt`

| Field | Value |
|-------|--------|
| Font | JetBrains Mono |
| Weight | **Regular** (400) |
| Size | **11** |
| Line height | **14** (Fixed) |
| Letter spacing | **0** |
| Case | As typed (lowercase path) |
| Fill | Variable **`text/dim`** |
| Sample text | `porteos@system ~ %` |

---

### 8. `Porteos/module/cmd`

| Field | Value |
|-------|--------|
| Font | JetBrains Mono |
| Weight | **Medium** (500) |
| Size | **11** |
| Line height | **14** (Fixed) |
| Letter spacing | **0** |
| Case | As typed |
| Fill | Variable **`text/secondary`** *(profile accent applied on module headers in components)* |
| Sample text | `01 // CORE_FINANCIALS` |

---

### 9. `Porteos/button/primary`

| Field | Value |
|-------|--------|
| Font | JetBrains Mono |
| Weight | **Bold** (700) |
| Size | **11** |
| Line height | **14** (Fixed) |
| Letter spacing | **0** |
| Case | **UPPERCASE** |
| Fill | Variable **`text/primary`** *(on filled buttons use profile accent bg + primary text)* |
| Sample text | `[ EDIT DEAL DATA ]` |

---

### 10. `Porteos/meta`

| Field | Value |
|-------|--------|
| Font | JetBrains Mono |
| Weight | **Regular** (400) |
| Size | **10** |
| Line height | **12** (Fixed) |
| Letter spacing | **+4%** (optional — for timestamp feel) |
| Case | **UPPERCASE** |
| Fill | Variable **`text/dim`** |
| Sample text | `LAST TOUCH · 2D AGO` |

---

## Cover frame layout (after styles exist)

On frame **1200 × 2400**, top to bottom:

| Block | Style | Content |
|-------|--------|---------|
| Title | `Porteos/score/grade` | `PORTEOS INTELLIGENCE` |
| Subtitle | `Porteos/meta` | `V2.06 · UI REDesign · DARK MODE` |
| Section | `Porteos/metric/label` | `COLOR SWATCHES` |
| Swatches | 80×48 rects | Fill = each Porteos color variable; label with `Porteos/meta` |
| Section | `Porteos/metric/label` | `TYPE SCALE` |
| Specimen rows | label `Porteos/row/label` + sample at each style | See phase-0-cover-spec.md §4 |
| Section | `Porteos/metric/label` | `DECISIONS` |
| Table | `Porteos/row/label` + `Porteos/row/value` | 7 rows from phase-0-cover-spec.md §2 |

**Padding:** 24px frame padding (`layout` token xl). **Gap between rows:** 8px.

---

## Do not set here

| Thing | Where it lives |
|-------|----------------|
| Colors | **Variables** — already imported ✓ |
| Layout numbers | **Variables** — `layout/*` ✓ |
| `.md` / `.json` files | **Repo** `Design-system/Figma/` — reference only |
| Swift code | **Not in Figma** — later in Xcode |

---

## Acceptance checklist

- [ ] 10 text styles named `Porteos/...` in Styles panel
- [ ] All fills bound to **Porteos** variables (not raw hex)
- [ ] JetBrains Mono on every style
- [ ] Cover frame 1200×2400 with swatches + type specimen
- [ ] Page background = `shell/canvas-base`

When done → **Phase 0 Figma done**
