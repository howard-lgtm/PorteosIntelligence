# PORTEOS INTELLIGENCE: MULTI-PROFILE COLOR ARCHITECTURE V2.06_FINAL

## 1. THE FOUNDATIONAL CORE (GLOBAL SHELL)
These tokens form the tectonic base for the entire application, ensuring a character-perfect native terminal aesthetic with zero-margin adjacency.

| Token | Hex | Usage |
| :--- | :--- | :--- |
| `CANVAS_BASE` | `#0A0A0A` | Absolute background (The Void). Used for the main window background. |
| `SURFACE_PANEL` | `#111111` | Primary container background for Nav, Workspace, and Inspector panes. |
| `DIVIDER_STRUCTURAL` | `#333333` | 1px solid lines separating all regions. Absolute prohibition of background gaps. |
| `TEXT_PRIMARY` | `#F8F9FA` | Active metrics, headers, and high-contrast data. |
| `TEXT_SECONDARY` | `#94A3B8` | Standard data, secondary metrics, and technical values. |
| `TEXT_DIM` | `#666666` | Labels, directory paths, and inactive system states. |

---

## 2. PROFILE IDENTITY MATRIX
Each profile maintains a distinct identity through its **Primary Accent** and **Hover** states. These are applied to the `[ PROFILE // MODULE ]` header, section headers, and navigation selection indicators.

### 2.1 REAL ESTATE (Gold/Rust)
- **Primary Accent**: `#D4AF37` (Metallic Gold)
- **Selection/Alert**: `#A34121` (Institutional Rust)
- **Concept**: Signifies luxury, high-value asset tracking, and robust financial authority.

### 2.2 HOSPITALITY (Teal)
- **Primary Accent**: `#14B8A6` (Hospitality Teal)
- **Concept**: High-end service mapping, revenue efficiency, and operational fluidity.

### 2.3 DESIGN (Purple)
- **Primary Accent**: `#A855F7` (Design Purple)
- **Concept**: Structural creativity, wellness metrics, and space-efficiency diagnostics.

### 2.4 CIRCULAR ECONOMY (Green)
- **Primary Accent**: `#10B981` (Circularity Green)
- **Concept**: Material recovery, carbon lifecycle, and sustainable asset longevity.

### 2.5 PIPELINE (Amber)
- **Primary Accent**: `#F59E0B` (Pipeline Amber)
- **Concept**: Deal flow tracking, status monitoring, and risk-sensitive triage.

---

## 3. SEMANTIC STATE LOGIC (THE STATUS LAYER)
Semantic colors are used strictly for threshold diagnostics (Go/Warn/Critical) regardless of the active profile.

| Meaning | Hex | Condition Examples |
| :--- | :--- | :--- |
| `STATUS_GO` | `#27C93F` | Optimized returns, approvals, MCI > 0.80, LTV < 65% |
| `STATUS_WARN` | `#FFBD2E` | Watchlist, limits, high OpEx ratio, moderate vacancy risk |
| `STATUS_CRITICAL` | `#FF5F56` | Rejects, high-risk flags, negative cash flow, DSCR < 1.10 |

---

## 4. COMPONENT STYLING RULES
- **Bracketed Inputs `[ VALUE ]`**: Border: `DIVIDER_STRUCTURAL`. Hover: Profile Primary Accent. Active: Text Primary.
- **Nav Selection**: Active row background: `#1A1A1A`. Left border: 2px sharp stroke in the **Active Profile Primary Accent**.
- **Diagnostic Gauges `[██████░░░░]`**: Fill: Semantic Status Color or Profile Primary Accent. Background: `CANVAS_BASE`.
- **Telemetry Indicators**: All indicator fills strictly use the Profile Primary Accent unless a semantic threshold (Warn/Critical) is breached.
