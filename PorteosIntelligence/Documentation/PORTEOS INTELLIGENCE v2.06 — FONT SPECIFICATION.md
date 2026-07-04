PORTEOS INTELLIGENCE v2.06 — FONT SPECIFICATION
NON-NEGOTIABLE. NO EXCEPTIONS.
═══════════════════════════════════════════════════════════════

RULE 1: ONE FONT FAMILY. ALWAYS. FOREVER.
  Font family: JetBrains Mono
  System fonts: FORBIDDEN
  San Francisco / SF Pro: FORBIDDEN
  Helvetica / Arial / any other font: FORBIDDEN
  Mixed fonts in one view: FORBIDDEN

RULE 2: USE TypeScale ONLY. NEVER hardcode size + weight.
  BANNED:  .custom("JetBrains Mono", size: 14)
  BANNED:  Font.system(size: 14, design: .monospaced)
  BANNED:  .font(.headline)
  BANNED:  .font(.body)
  REQUIRED: TypeScale.metricValue
  REQUIRED: TypeScale.cliPrompt
  etc.

═══════════════════════════════════════════════════════════════
COMPLETE TypeScale ENUM — copy this verbatim into DesignTokens.swift
═══════════════════════════════════════════════════════════════

enum TypeScale {

    // ── DISPLAY ─────────────────────────────────────────────
    // Large score numbers only
    static let scoreHero  = mono(36, .bold)
    // Grade letter badge only
    static let scoreGrade = mono(20, .bold)

    // ── DATA DISPLAY ─────────────────────────────────────────
    // Metric cell: value on TOP — this style
    static let metricValue = mono(16, .medium)
    // letter-spacing: -2% (tracking: -0.32)
    // line-height:    20pt fixed

    // Metric cell: label BELOW — this style
    static let metricLabel = mono(11, .medium)
    // letter-spacing: +2% (tracking: +0.22)

    // Table / row values
    static let rowValue = mono(12, .medium)

    // Table / row labels, nav links, deal names
    static let rowLabel = mono(11, .regular)

    // ── UI CHROME ─────────────────────────────────────────────
    // All button text, tab labels, CTAs
    static let buttonPrimary = mono(11, .bold)
    // letter-spacing: +2% (tracking: +0.22)

    // Timestamps, hints, metadata, status strips, tooltips
    static let meta = mono(10, .regular)
    // letter-spacing: +4% (tracking: +0.40)

    // Terminal CLI prompt lines
    static let cliPrompt = mono(11, .regular)
    // line-height: 14pt fixed

    // Module header CLI labels (01 // CORE_FINANCIALS etc.)
    static let moduleCmd = mono(11, .medium)
    // line-height: 14pt fixed

    // ── PRIVATE ───────────────────────────────────────────────
    private static func mono(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .custom("JetBrains Mono", size: size).weight(weight)
    }
}

═══════════════════════════════════════════════════════════════
LETTER-SPACING REFERENCE
═══════════════════════════════════════════════════════════════

metricValue:   -2%  →  .tracking(-0.32)   // tighter for numbers
metricLabel:   +2%  →  .tracking(0.22)
buttonPrimary: +2%  →  .tracking(0.22)
meta:          +4%  →  .tracking(0.40)
All others:     0   →  no tracking modifier needed

═══════════════════════════════════════════════════════════════
LINE-HEIGHT REFERENCE
═══════════════════════════════════════════════════════════════

metricValue:  20pt  →  .lineSpacing(4)  // (20 - 16 = 4pt extra)
cliPrompt:    14pt  →  .lineSpacing(3)  // (14 - 11 = 3pt extra)
moduleCmd:    14pt  →  .lineSpacing(3)
All others:   auto  →  no lineSpacing modifier needed

═══════════════════════════════════════════════════════════════
USAGE MAP — what style goes where
═══════════════════════════════════════════════════════════════

Score number "87"                     → TypeScale.scoreHero
Grade letter "A"                      → TypeScale.scoreGrade
Metric cell value "€350k"             → TypeScale.metricValue
Metric cell label "GPI"               → TypeScale.metricLabel
Table / list value "6.20%"            → TypeScale.rowValue
Table / list label "CAP RATE"         → TypeScale.rowLabel
Deal name in nav "Lisbon Office A"    → TypeScale.rowLabel
Button text "[ EDIT DEAL DATA ]"      → TypeScale.buttonPrimary
Tab label "WEIGHTS"                   → TypeScale.buttonPrimary
Status tab "ALL"                      → TypeScale.meta
Section label "// DEAL INFORMATION"   → TypeScale.meta
Timestamp "09:42 · 03 Jul"            → TypeScale.meta
Hint text "Supports .csv · Max 10MB"  → TypeScale.meta
Confidence pill "HIGH"                → TypeScale.meta
Terminal prompt text                  → TypeScale.cliPrompt
Module header "01 // CORE_FINANCIALS" → TypeScale.moduleCmd

═══════════════════════════════════════════════════════════════
GREP COMMAND — run before every PR to catch violations
═══════════════════════════════════════════════════════════════

# Must return ZERO lines:
grep -rn '\.custom("JetBrains Mono"' --include="*.swift"
grep -rn 'Font\.system' --include="*.swift"
grep -rn '\.headline\|\.body\|\.caption\|\.subheadline\|\.title' --include="*.swift"

═══════════════════════════════════════════════════════════════
SWIFTUI USAGE EXAMPLES
═══════════════════════════════════════════════════════════════

✅ CORRECT:
  Text("6.20%")
      .font(TypeScale.metricValue)
      .tracking(-0.32)

  Text("CAP RATE")
      .font(TypeScale.metricLabel)
      .tracking(0.22)
      .foregroundColor(.textDim)

  Text("[ EDIT DEAL DATA ]")
      .font(TypeScale.buttonPrimary)
      .tracking(0.22)
      .foregroundColor(.canvasBase)

  Text("porteos@real-estate ~ % ./dashboard")
      .font(TypeScale.cliPrompt)
      .lineSpacing(3)
      .foregroundColor(.textDim)

❌ WRONG — delete and replace:
  Text("6.20%").font(.custom("JetBrains Mono", size: 16))
  Text("CAP RATE").font(.system(size: 11, design: .monospaced))
  Text("EDIT").font(.headline)
  Text("label").font(.caption)

═══════════════════════════════════════════════════════════════
Figma file ID: 7XdLK0I2aWj7KVkvhnJEyE · Locked 2026-07-03

═══════════════════════════════════════════════════════════════
DEFINITIVE RENDERING PIPELINE (2026-07-04)
═══════════════════════════════════════════════════════════════

Three layers — all required. Missing any layer = wrong look.

LAYER 1 — FONT FILES (bundled)
  PorteosIntelligence/Fonts/JetBrainsMono-{Regular,Medium,SemiBold,Bold}.ttf
  Registered at launch via PorteosFontLoader.registerBundledFonts()
  PostScript names used in TypeScale — never synthetic .weight() on family name

LAYER 2 — STYLE SPEC (DesignTokens + PorteosTextStyle)
  Each Figma text style = font + tracking + fixed lineHeight in ONE struct
  Authority: Design-system/Figma/FIGMA-TEXT-STYLES.md
  Implementation: PorteosIntelligence/Utilities/PorteosTextStyle.swift

LAYER 3 — RENDER API (views)
  ✅ PorteosText("GPI", style: .metricLabel)
  ✅ PorteosMetricStack(label:value:)  — enforces 4pt value→label gap
  ✅ .porteosTextStyle(.meta)          — for Button labels
  ❌ .font() + .tracking() + .lineSpacing() separately — BANNED
  ❌ .tracking(0.06) ad-hoc overrides — BANNED

PR gate: ./scripts/typography-check.sh (must pass before merge)
