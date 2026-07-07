---
name: Porteos Terminal
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#ddc0b8'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#a58b84'
  outline-variant: '#57423c'
  surface-tint: '#ffb59e'
  primary: '#ffb59e'
  on-primary: '#5e1700'
  primary-container: '#a34121'
  on-primary-container: '#ffd1c4'
  inverse-primary: '#a13f20'
  secondary: '#c8c6c5'
  on-secondary: '#303030'
  secondary-container: '#474746'
  on-secondary-container: '#b6b5b4'
  tertiary: '#b7c8e1'
  on-tertiary: '#213145'
  tertiary-container: '#516177'
  on-tertiary-container: '#cbdcf6'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdbd0'
  primary-fixed-dim: '#ffb59e'
  on-primary-fixed: '#3a0a00'
  on-primary-fixed-variant: '#812909'
  secondary-fixed: '#e4e2e1'
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1b1c1b'
  on-secondary-fixed-variant: '#474746'
  tertiary-fixed: '#d3e4fe'
  tertiary-fixed-dim: '#b7c8e1'
  on-tertiary-fixed: '#0b1c2f'
  on-tertiary-fixed-variant: '#38485d'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
  institutional-rust: '#a34121'
  terminal-black: '#0a0a0a'
  terminal-gray: '#1a1a1a'
  border-gray: '#333333'
  success-green: '#27c93f'
  warning-yellow: '#ffbd2e'
  error-red: '#ff5f56'
  text-dim: '#666666'
typography:
  headline-lg:
    fontFamily: JetBrains Mono
    fontSize: 30px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.05em
  headline-md:
    fontFamily: JetBrains Mono
    fontSize: 18px
    fontWeight: '700'
    lineHeight: '1.4'
    letterSpacing: -0.02em
  body-lg:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '400'
    lineHeight: '1.5'
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '700'
    lineHeight: '1'
    letterSpacing: 0.15em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 9px
    fontWeight: '400'
    lineHeight: '1'
    letterSpacing: 0.05em
  terminal-prompt:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '600'
    lineHeight: '1.2'
spacing:
  container-padding: 1.5rem
  gutter: 1.5rem
  component-gap: 0.75rem
  row-height-sm: 2.5rem
  sidebar-width: 14rem
---

## Brand & Style
Porteos Terminal is an institutional-grade intelligence platform that blends **Modern Brutalism** with **Terminal-inspired utility**. The brand personality is technical, precise, and authoritative, designed for "power users" in finance, technology, and system administration.

The UI evokes a "Command Line Interface" (CLI) atmosphere within a sophisticated desktop application wrapper. It prioritizes data density, logical hierarchy, and rapid information scanning. The aesthetic avoids soft gradients or decorative elements in favor of sharp lines, high-contrast text against dark backgrounds, and subtle "hacker-chic" animations like terminal cursors and status-light pulses.

## Colors
The palette is rooted in a deep **Terminal Black** (#0a0a0a) and **Terminal Gray** (#1a1a1a) to minimize eye strain and maximize focus. 

The primary accent is **Institutional Rust** (#a34121), used sparingly for critical identifiers, prompts, and active status indicators. This specific shade provides a warm, industrial contrast to the cold background without being as aggressive as standard red. 

Functional colors follow the "Traffic Light" standard (Red, Yellow, Green) but are used exclusively for window controls or high-priority status alerts. Borders and dividers use a strict **Border Gray** (#333333) to maintain the grid-based structural integrity.

## Typography
The system uses **JetBrains Mono** exclusively to maintain the technical, developer-centric aesthetic. Typography is treated as a structural element rather than just content.

- **Headlines:** Use tight letter-spacing and bold weights for a dense, "compressed" feel.
- **Labels:** Use extreme tracking (letter-spacing) and all-caps for metadata and section headers to differentiate from interactive data.
- **Data Points:** Numbers should always be monospaced to ensure vertical alignment in tables and lists.
- **Scaling:** Font sizes never exceed 30px even on desktop, as high information density is preferred over large, airy headers.

## Layout & Spacing
The layout follows a **Rigid Grid** philosophy. Content is contained within a 12-column system, but the visual delivery mimics a terminal window with fixed headers, footers, and sidebars.

- **Breakpoints:** On desktop, the sidebar is fixed at 224px. On tablet, the sidebar collapses into a drawer. On mobile, the multi-column metrics grid stacks into a single column.
- **Rhythm:** A 4px baseline grid is used. Spacing is tight (8px/12px) to allow for more data on screen.
- **Layout Model:** High-level metrics are presented in a modular grid of "Bento Box" cards, while detailed transactions are presented in a full-width CLI-style table.

## Elevation & Depth
Depth is achieved through **Tonal Layering** and **Transparency** rather than shadows. 

- **Surface Levels:** The primary background is the darkest. Container surfaces (cards) use a slightly lighter opacity (e.g., `rgba(255, 255, 255, 0.05)`) to pull forward.
- **Backdrop Blur:** The main window uses a heavy backdrop blur (20px) to suggest depth against the desktop environment.
- **Outlines:** Elevation is defined by `1px` solid borders (#333333). No drop shadows are used for internal elements; shadows are reserved for the main application window to separate it from the OS.
- **Interaction:** Hover states are indicated by a subtle background shift (`white/5`) or a color change in the primary accent, never by "lifting" the element.

## Shapes
The shape language is primarily **Sharp (0px)** to reflect the brutalist, terminal nature. 

- **Exceptions:** The main application window uses a `12px` corner radius to align with modern OS window standards (macOS/Windows). 
- **Internal Elements:** All internal cards, buttons, input fields, and tags must have 0px corners. This reinforces the "blocky" and systematic feel of the interface.

## Components
- **Buttons:** Rectangular with 0px radius. Use "Institutional Rust" for primary actions and "Border Gray" outlines for secondary. Text must be all-caps and bold.
- **Terminal Input:** A fixed footer component with a persistent prompt (`porteos@system ~ %`) and a blinking vertical block cursor.
- **Data Tables:** CLI-inspired with uppercase, dimmed headers and 1px horizontal dividers. No vertical dividers.
- **Status Tags:** Small rectangular boxes with 1px borders matching the text color (e.g., a Rust border for "SETTLED").
- **Gauges:** Circular progress indicators should use thin stroke widths and monospaced center labels.
- **Metrics Cards:** Always feature a header bar with a "line-number" style prefix (e.g., `01 // Revenue_Stream`).