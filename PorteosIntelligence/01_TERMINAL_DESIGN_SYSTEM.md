# Porteos Intelligence - Native Terminal Design System V3.0
**Purpose:** The absolute source of truth for all UI, layout, typography, and component styling.
**Target Platform:** macOS 14.0+ (SwiftUI)

## 0. DESIGN PHILOSOPHY: "NATIVE TERMINAL"
We are building a native macOS application that mimics the aesthetic and density of a high-end terminal emulator (like Apple Terminal/iTerm2) while retaining native macOS interaction models.
- **Core Aesthetic:** Institutional Brutalist / Terminal TUI Hybrid.
- **Zero Rounded Corners:** `cornerRadius: 0` everywhere. Sharp rectangles only.
- **Monospace Dominance:** JetBrains Mono (or SF Mono) for 95% of the UI. 
- **Strict Grid Alignment:** Every element snaps to an 8pt character/cell grid.
- **Native Implementation:** Use standard SwiftUI views (`VStack`, `HStack`, `Grid`) styled to *look* like a terminal. **DO NOT** use `NSTextView` or raw TUI libraries.

### 0.1 Color & Richness Philosophy (CRITICAL RULE)
**The "State vs. Identity" Rule:** 
We DO NOT assign unique colors to specific metrics (e.g., Teal for RevPAR, Purple for MCI). This creates cognitive overload. Richness is achieved through:
1. **State Semantics:** Colors (Green/Amber/Red) are ONLY used to indicate threshold breaches. Normal metrics are White/Grey.
2. **Typographic Hierarchy:** Font Weight (Bold vs Regular) and Brightness (White vs Dim Grey) draw the eye to primary metrics.
3. **Profile Identity:** The active Profile Accent Color (Gold, Teal, etc.) is ONLY used for section headers, active tabs, and indicator bar fills.
4. **Cell Highlighting:** Outliers are pinpointed using sharp 2px left-borders and subtle 5% opacity background tints.

## 1. COLOR SYSTEM (Exact Hex Values)
### 1.1 Base Shell Colors
| Token | Hex | Usage |
|---|---|---|
| `shell-bg` | `#0F1115` | Main window background (near-black) |
| `shell-surface` | `#1A1D24` | Panels, sidebars, inspector backgrounds |
| `shell-elevated` | `#23262E` | Modals, popovers, tooltips |
| `shell-border` | `#2E333F` | All dividers, table borders, panel edges (1px or 2px) |
| `text-primary` | `#F8F9FA` | Primary text, high-priority metrics (near-white) |
| `text-secondary` | `#94A3B8` | Labels, secondary text, standard metrics (slate) |
| `text-tertiary` | `#64748B` | Disabled, placeholder text, column headers |

### 1.2 Profile Accent Colors (Identity Only)
| Profile | Primary | Hover | Icon |
|---|---|---|---|
| Real Estate | `#D4AF37` (Gold) | `#C4A030` |  |
| Hospitality | `#14B8A6` (Teal) | `#0D9488` | 🏨 |
| Design | `#A855F7` (Purple) | `#9333EA` | ✏️ |
| Circular Economy | `#10B981` (Green) | `#059669` | ️ |
| Pipeline | `#F59E0B` (Amber) | `#D97706` | 📊 |

### 1.3 Semantic Colors (Strict Thresholds Only)
These colors are NEVER used for standard metric labels. They are ONLY applied when a metric breaches a defined threshold.
| Meaning | Hex | Usage & Threshold Examples |
|---|---|---|
| Success / Optimal | `#10B981` (Green) | DSCR ≥ 1.25, LTV ≤ 75%, Positive Cash Flow |
| Warning / Review | `#F59E0B` (Amber) | DSCR 1.10-1.24, LTV 76-85%, Vacancy > 8% |
| Danger / Poor | `#EF4444` (Red) | DSCR < 1.10, LTV > 90%, Negative Cash Flow |
| Info / Neutral | `#3B82F6` (Blue) | Informational tags, links, neutral states |

**Cell Highlight Technique (For Danger/Warning States):**
When a metric hits a Warning/Danger state:
- Text color changes to the semantic color.
- A sharp 2px left-border is added to the metric row/cell in the semantic color.
- A subtle 5% opacity background tint of the semantic color is applied to the cell background.

## 2. TYPOGRAPHY SYSTEM
### 2.1 Font Families
- **Primary (Data & UI):** JetBrains Mono (or SF Mono). Used for ALL financial values, metrics, percentages, dates, inputs, tables, and buttons. Weights: Regular (400), Bold (700).
- **Secondary (Prose):** Inter. Used ONLY for long-form AI narratives or paragraphs exceeding 3 lines.

### 2.2 Typographic Hierarchy for Data Density
- **Primary Metrics (The "Pinpoints"):** JetBrains Mono, 14pt, Weight: Bold. Color: `text-primary`. Usage: NOI, Cap Rate, Porteos Score.
- **Secondary Metrics (Standard Data):** JetBrains Mono, 12pt, Weight: Regular. Color: `text-secondary`. Usage: Supporting metrics, historical data.
- **Tertiary/Contextual Data (Labels):** Inter, 11pt, Weight: Bold, Uppercase, Tracking 0.08. Color: `text-tertiary`. Usage: Metric labels, units, column headers.

### 2.3 Numeric Style (All Numbers)
`.font(.custom("JetBrains Mono", size: 14).weight(.bold)).tracking(-0.02).monospacedDigit().foregroundColor(.textPrimary)`

## 3. SPACING & GRID SYSTEM (The 8pt Cell Grid)
### 3.1 Spacing Tokens
- `gap-xs`: 4pt | `gap-sm`: 8pt | `gap-md`: 16pt | `gap-lg`: 24pt

### 3.2 Fixed Heights (The "Terminal Line" Height)
Every interactive element must align to a strict vertical rhythm.
- **Table Row / Input Field / Button:** 28pt (Fixed, no variation)
- **Navigation Link:** 24pt
- **Block Header (Command Line):** 24pt
- **Header Bar:** 40pt | **Tab Bar:** 36pt

## 4. COMPONENT LIBRARY
### 4.1 Buttons
- **Primary (Command Button):** Background `#D4AF37` (Gold), Text `#0F1115` (Black), Border None. Font: JetBrains Mono Bold 11pt UPPERCASE. Format: `[ ACTION_NAME ]`. Corner radius: 0.
- **Secondary (Script Button):** Background transparent, Text `#10B981` (Green) or `text-secondary`. Font: JetBrains Mono Regular 11pt. Format: `./action_name`. Corner radius: 0.

### 4.2 Input Fields
- Background: `shell-bg`. Border: 1px `shell-border`. Focus border: Profile accent color.
- Text: JetBrains Mono 14pt. Height: 28pt. Padding: 8pt horizontal. Corner radius: 0.
- Validation: Inline errors only. Red border + red icon right. Error text below field (10pt).

### 4.3 Terminal Metric Row (Standard Data Display)
This is the default component for displaying metrics.
- **Height:** 28pt. **Padding:** 12pt horizontal, 8pt vertical.
- **Layout (HStack):** 
  1. Left Border Indicator (2pt wide, semantic color, if Danger state).
  2. Label (Left): Inter Bold 11pt UPPERCASE, `text-tertiary`.
  3. Spacer.
  4. Value (Right): JetBrains Mono 14pt Bold, `monospacedDigit()`. Color: `text-primary` (Neutral), `warning` (Warning), `danger` (Danger).
- **States:** Warning = Amber text + 5% Amber bg tint. Danger = Red text + 2pt Red left-border + 5% Red bg tint.

### 4.4 Progress Bars & Indicator Fills
- **Linear:** Container `shell-bg`, 1px `shell-border`, 8pt height. Fill: **Strictly uses the ACTIVE Profile Accent Color** (e.g., Gold for Real Estate). *Exception:* If metric is in Danger state, fill overrides to `danger` (#EF4444). Corner radius: 0.
- **Circular (Score Ring):** Track `shell-border` (4pt stroke). Fill: Active Profile Accent Color (4pt stroke). Center number: JetBrains Mono Bold 24pt. Size: 120pt diameter.

### 4.5 Data Tables
- Background: `shell-surface`. Border: 1px `shell-border`. Row height: 28pt.
- Header Row: Background `shell-bg`. Text: Inter Bold 11pt UPPERCASE, `text-tertiary`. Bottom border: 1px `shell-border`.
- Data Row: Text left-aligned (Labels), Numeric right-aligned (Values). Hover state: `shell-elevated` background.

## 5. LAYOUT STRUCTURE (The 3-Pane Terminal)
### 5.1 Application Shell
The app is divided into three strict vertical panes, separated by 1px `shell-border` lines.
1. **Navigation Pane (Left):** Fixed 220pt width. Contains file-tree style navigation and deal list.
2. **Main Content Pane (Center):** Flexible width. Contains the primary dashboard/tables.
3. **Inspector Pane (Right):** Fixed 320pt width. Contains Weights and AI Vibe Check.

### 5.2 Global Command Bar (Bottom)
- Fixed 32pt height at the bottom of the window.
- Left: `porteos@system ~ % ` (dimmed) followed by a text input field.
- Right: `UTF-8  LN: [Line Count]` (dimmed).

### 5.3 Navigation Pane (File Tree)
- Header: `INSTITUTIONAL` (Bold, 12pt, Gold), `V3.0_TERMINAL` (Dim, 10pt).
- Links: Styled as file paths. Active: `/cmd_center` (White, Bold, `shell-surface` bg). Inactive: `/real_estate` (Dim).
- Actions: Styled as executable scripts. `[ ./sync_data ]` (Button styled as terminal command block).

### 5.4 Main Content Pane (Terminal Blocks)
Content is organized into "Terminal Blocks". Each block has a header that mimics a command execution.
- **Block Header Format:** `porteos@system ~ % [command_name]` (e.g., `porteos@system ~ % stats --quick-look`).
- Content below the header is the "output" of that command.

### 5.5 Inspector Panel
- Header: `./INSPECTOR_V2` (Dim, 10pt).
- Tabs: `[WEIGHTS]` `[AI VIBE]`. Active: gold underline (2px), `text-primary`.
- Action Button: Full width, terminal style. `[ CAT REPORT.PDF ]` (Gold background, Black text, Bold).