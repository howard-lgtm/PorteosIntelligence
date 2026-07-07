# Figma V2.06 — Font Map

**Authority:** `PORTEOS INTELLIGENCE v2.06 — FONT SPECIFICATION.md` (non-negotiable)  
**Rule:** Views use `DesignTokens.TypeScale.*` + `Tracking`/`LineSpacing` modifiers only.

## TypeScale tokens

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `scoreHero` | 36 | Bold | Score number "87" |
| `scoreGrade` | 20 | Bold | Grade letter "A" |
| `metricValue` | 16 | Medium | Metric cell value (+ tracking −0.32, lineSpacing 4) |
| `metricLabel` | 11 | Medium | Metric cell label (+ tracking +0.22) |
| `rowValue` | 12 | Medium | Table/list values |
| `rowLabel` | 11 | Regular | Nav links, deal names, row labels |
| `buttonPrimary` | 11 | Bold | Buttons, tabs, CTAs (+ tracking +0.22) |
| `meta` | 10 | Regular | Status tabs, sections, hints (+ tracking +0.40) |
| `cliPrompt` | 11 | Regular | Terminal prompt (+ lineSpacing 3) |
| `moduleCmd` | 11 | Medium | Module headers (+ lineSpacing 3) |

## View modifiers

| Modifier | Applies |
|----------|---------|
| `.porteosMetricValue()` | metricValue + tracking + lineSpacing |
| `.porteosMetricLabel()` | metricLabel + tracking |
| `.porteosButtonPrimary()` | buttonPrimary + tracking |
| `.porteosMeta()` | meta + tracking |
| `.porteosCliPrompt()` | cliPrompt + lineSpacing |
| `.porteosModuleCmd()` | moduleCmd + lineSpacing |
| `.porteosRowLabel()` / `.porteosRowValue()` | row styles |

## Migration phases

| Phase | Scope | Status |
|-------|-------|--------|
| **1** | Shell panes | ✅ |
| **2** | Shared components | ✅ |
| **3** | Dashboards + all views → `PorteosText` / `.porteosTextStyle()` | ✅ Complete |
| **4** | Remaining sheets + admin | Pending |

## PR grep (must return zero in Views/)

```bash
grep -rn '\.custom("JetBrains Mono"' --include="*.swift" PorteosIntelligence/Views
grep -rn 'DesignTokens\.mono(' --include="*.swift" PorteosIntelligence/Views
grep -rn 'Font\.system' --include="*.swift" PorteosIntelligence/Views
```
