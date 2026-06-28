# Porteos Intelligence - Native Terminal Design System V3.1

**Purpose:** The absolute source of truth for all UI, layout, typography, and component styling.
**Target Platform:** macOS 14.0+ (SwiftUI)
**Last Updated:** June 27, 2026

---

## 0. DESIGN PHILOSOPHY: "INSTITUTIONAL TERMINAL"

We are building a native macOS application that mimics the aesthetic and density of a high-end terminal emulator (like Apple Terminal/iTerm2) while retaining native macOS interaction models.

- **Core Aesthetic:** Institutional Brutalist / Terminal TUI Hybrid.
- **Zero Rounded Corners:** `cornerRadius: 0` everywhere. Sharp rectangles only.
- **Monospace Dominance:** JetBrains Mono exclusively for 100% of the UI. No proportional fonts.
- **Strict Grid Alignment:** Every element snaps to an 8pt character/cell grid.
- **Native Implementation:** Use standard SwiftUI views (`VStack`, `HStack`, `Grid`) styled to *look* like a terminal. **DO NOT** use `NSTextView` or raw TUI libraries.

### 0.1 Color & Richness Philosophy (CRITICAL RULE)

**The "State vs. Identity" Rule:**

We DO NOT assign unique colors to specific metrics (e.g., Teal for RevPAR, Purple for MCI). This creates cognitive overload. Richness is achieved through:

1. **State Semantics:** Colors (Green/Amber/Red) are ONLY used to indicate threshold breaches. Normal metrics are White/Grey.
2. **Typographic Hierarchy:** Font Weight (Bold vs Regular) and Brightness (White vs Dim Grey) draw the eye to primary metrics.
3. **Profile Identity:** The active Profile Accent Color (Rust, Teal, etc.) is ONLY used for section headers, active tabs, indicator bar fills, and score rings.
4. **Cell Highlighting:** Outliers are pinpointed using sharp 2px left-borders and subtle 5% opacity background tints.

---

## 1. COLOR SYSTEM (Exact Hex Values)

### 1.1 Base Shell Colors

| Token | Hex | Usage |
| --- | --- | --- |
| `shell-bg` | `#0F1115` | Main window background (near-black) |
| `shell-surface` | `#1A1D24` | Panels, sidebars, inspector backgrounds |
| `shell-elevated` | `#23262E` | Modals, popovers, tooltips |
| `shell-border` | `#2E333F` | All dividers, table borders, panel edges (1px or 2px) |
| `text-primary` | `#F8F9FA` | Primary text, high-priority metrics (near-white) |
| `text-secondary` | `#94A3B8` | Labels, secondary text, standard metrics (slate) |
| `text-tertiary` | `#64748B` | Disabled, placeholder text, column headers |

### 1.2 Profile Accent Colors (Identity Only)

| Profile | Primary | Hover | Icon |
| --- | --- | --- | --- |
| Real Estate | `#C25E30` (Rust) | `#A84D25` |  |
| Hospitality | `#14B8A6` (Teal) | `#0D9488` | 🏨 |
| Design | `#A855F7` (Purple) | `#9333EA` | ✏️ |
| Circular Economy | `#3B82F6` (Blue) | `#2563EB` | ️ |
| Pipeline | `#F59E0B` (Amber) | `#D97706` | 📊 |

**Note:** The Rust/Orange (`#C25E30`) replaces the previous Gold (`#D4AF37`) for Real Estate to match the institutional terminal aesthetic.

### 1.3 Semantic Colors (Strict Thresholds Only)

These colors are NEVER used for standard metric labels. They are ONLY applied when a metric breaches a defined threshold.

| Meaning | Hex | Usage & Threshold Examples |
| --- | --- | --- |
| Success / Optimal | `#10B981` (Green) | DSCR ≥ 1.25, LTV ≤ 75%, Positive Cash Flow, Score ≥ 80 |
| Warning / Review | `#F59E0B` (Amber) | DSCR 1.10-1.24, LTV 76-85%, Vacancy > 8%, Score 60-79 |
| Danger / Poor | `#EF4444` (Red) | DSCR < 1.10, LTV > 90%, Negative Cash Flow, Score < 60 |
| Info / Neutral | `#3B82F6` (Blue) | Informational tags, links, neutral states |

**Cell Highlight Technique (For Danger/Warning States):**

When a metric hits a Warning/Danger state:
1. Text color changes to the semantic color.
2. A sharp 2px left-border is added to the metric row/cell in the semantic color.
3. A subtle 5% opacity background tint of the semantic color is applied to the cell background.

---

## 2. TYPOGRAPHY SYSTEM

### 2.1 Font Families

- **Exclusive Font:** JetBrains Mono. Used for ALL UI elements — financial values, metrics, percentages, labels, inputs, buttons, navigation, and headers. Weights: Regular (400), Bold (700).
- **Inter has been removed entirely.** No proportional fonts anywhere in the application.

### 2.2 Typographic Hierarchy for Data Density

- **Hero Numbers (The "Pinpoints"):** JetBrains Mono, 48pt, Weight: Bold. Color: Profile Accent or `text-primary`. Usage: Porteos Score, Efficiency Score, Global Circularity Index.
- **Primary Metrics:** JetBrains Mono, 14pt, Weight: Bold. Color: `text-primary`. Usage: NOI, Cap Rate, RevPAR.
- **Secondary Metrics:** JetBrains Mono, 12pt, Weight: Regular. Color: `text-secondary`. Usage: Supporting metrics, historical data.
- **Tertiary/Contextual Data (Labels):** JetBrains Mono, 10pt, Weight: Bold, Uppercase, Tracking 0.08. Color: `text-tertiary`. Usage: Metric labels, units, column headers, module titles, section headers, field labels.

### 2.3 Numeric Style (All Numbers)

```swift
.font(.custom("JetBrains Mono", size: 14).weight(.bold))
.tracking(-0.02)
.monospacedDigit()
.foregroundColor(.textPrimary)