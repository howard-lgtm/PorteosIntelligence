import SwiftUI

// MARK: - PorteosTextStyle
// DEFINITIVE typography — mirrors Figma `Porteos/*` text styles + FONT SPECIFICATION.
// Every UI string MUST use PorteosText(_:style:) or .porteosTextStyle(_:).
// Never combine .font(), .tracking(), or .lineSpacing() separately on terminal UI text.

enum PorteosTextStyle: Equatable {

    // Figma text styles (10)
    case scoreHero
    case scoreGrade
    case metricValue
    case metricLabel
    case rowValue
    case rowLabel
    case buttonPrimary
    case meta
    case cliPrompt
    case moduleCmd

    // Stateful shell variants (same metrics, different weight)
    case shellNav(isActive: Bool)
    case shellDeal(isSelected: Bool)
    case shellAction(isActive: Bool)

    // MARK: Resolved spec

    var spec: Spec { SpecResolver.resolve(self) }

    struct Spec: Equatable {
        let font: Font
        let tracking: CGFloat
        let lineHeight: CGFloat
        let uppercase: Bool
        let tabularDigits: Bool
    }

    private enum SpecResolver {
        static func resolve(_ style: PorteosTextStyle) -> Spec {
            switch style {
            case .scoreHero:
                return Spec(font: DesignTokens.TypeScale.scoreHero,
                            tracking: 0, lineHeight: DesignTokens.LineHeight.scoreHero,
                            uppercase: false, tabularDigits: true)
            case .scoreGrade:
                return Spec(font: DesignTokens.TypeScale.scoreGrade,
                            tracking: 0, lineHeight: DesignTokens.LineHeight.scoreGrade,
                            uppercase: false, tabularDigits: false)
            case .metricValue:
                return Spec(font: DesignTokens.TypeScale.metricValue,
                            tracking: DesignTokens.Tracking.metricValue,
                            lineHeight: DesignTokens.LineHeight.metricValue,
                            uppercase: false, tabularDigits: true)
            case .metricLabel:
                return Spec(font: DesignTokens.TypeScale.metricLabel,
                            tracking: DesignTokens.Tracking.metricLabel,
                            lineHeight: DesignTokens.LineHeight.metricLabel,
                            uppercase: true, tabularDigits: false)
            case .rowValue:
                return Spec(font: DesignTokens.TypeScale.rowValue,
                            tracking: 0, lineHeight: DesignTokens.LineHeight.rowValue,
                            uppercase: false, tabularDigits: true)
            case .rowLabel:
                return Spec(font: DesignTokens.TypeScale.rowLabel,
                            tracking: DesignTokens.Tracking.rowLabel,
                            lineHeight: DesignTokens.LineHeight.rowLabel,
                            uppercase: true, tabularDigits: false)
            case .buttonPrimary:
                return Spec(font: DesignTokens.TypeScale.buttonPrimary,
                            tracking: DesignTokens.Tracking.buttonPrimary,
                            lineHeight: DesignTokens.LineHeight.buttonPrimary,
                            uppercase: true, tabularDigits: false)
            case .meta:
                return Spec(font: DesignTokens.TypeScale.meta,
                            tracking: DesignTokens.Tracking.meta,
                            lineHeight: DesignTokens.LineHeight.meta,
                            uppercase: true, tabularDigits: false)
            case .cliPrompt:
                return Spec(font: DesignTokens.TypeScale.cliPrompt,
                            tracking: 0, lineHeight: DesignTokens.LineHeight.cli,
                            uppercase: false, tabularDigits: false)
            case .moduleCmd:
                return Spec(font: DesignTokens.TypeScale.moduleCmd,
                            tracking: 0, lineHeight: DesignTokens.LineHeight.cli,
                            uppercase: false, tabularDigits: false)
            case .shellNav(let active), .shellDeal(let active), .shellAction(let active):
                let isOn = active
                return Spec(
                    font: isOn ? DesignTokens.TypeScale.buttonPrimary : DesignTokens.TypeScale.rowLabel,
                    tracking: isOn ? DesignTokens.Tracking.buttonPrimary : DesignTokens.Tracking.rowLabel,
                    lineHeight: DesignTokens.LineHeight.rowLabel,
                    uppercase: true,
                    tabularDigits: false
                )
            }
        }
    }
}

// MARK: - PorteosText
// Canonical text view — font + tracking + line-height applied atomically.

struct PorteosText: View {

    private let content: String
    private let style: PorteosTextStyle
    private let color: Color?

    init(_ content: String, style: PorteosTextStyle, color: Color? = nil) {
        self.content = content
        self.style = style
        self.color = color
    }

    var body: some View {
        let s = style.spec
        Group {
            if let color {
                styledText(s).foregroundStyle(color)
            } else {
                styledText(s)
            }
        }
    }

    private func styledText(_ s: PorteosTextStyle.Spec) -> some View {
        Text(s.uppercase ? content.uppercased() : content)
            .font(s.font)
            .tracking(s.tracking)
            .frame(height: s.lineHeight, alignment: .center)
            .modifier(TabularDigitsModifier(enabled: s.tabularDigits))
            .lineLimit(1)
    }
}

private struct TabularDigitsModifier: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled { content.monospacedDigit() } else { content }
    }
}

// MARK: - Text-specific API (TextField prompts, concatenation)

extension Text {
    /// Apply style while keeping `Text` type — for prompts and `Text + Text`.
    func porteosStyle(_ style: PorteosTextStyle) -> Text {
        let s = style.spec
        return font(s.font).tracking(s.tracking)
    }
}

// MARK: - View modifier (for Button labels / custom Text)

extension View {
    /// Apply a complete Figma text style. Prefer `PorteosText` for static strings.
    func porteosTextStyle(_ style: PorteosTextStyle) -> some View {
        let s = style.spec
        return font(s.font)
            .tracking(s.tracking)
            .frame(height: s.lineHeight, alignment: .center)
            .modifier(TabularDigitsModifier(enabled: s.tabularDigits))
    }
}

// MARK: - PorteosMetricStack
// Figma metric cell anatomy: value (16/20) → 4pt gap → label (11/14).

struct PorteosMetricStack: View {

    let label: String
    let value: String
    var valueColor: Color = DesignTokens.textPrimary
    var labelColor: Color = DesignTokens.textDim
    var scaleOnOverflow: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.metricStackGap) {
            PorteosText(value, style: .metricValue, color: valueColor)
                .minimumScaleFactor(scaleOnOverflow ? 0.85 : 1.0)

            PorteosText(label, style: .metricLabel, color: labelColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Legacy shorthand → porteosTextStyle (keep call-sites stable)

extension View {
    func porteosMetricValue() -> some View { porteosTextStyle(.metricValue) }
    func porteosMetricLabel() -> some View { porteosTextStyle(.metricLabel) }
    func porteosButtonPrimary() -> some View { porteosTextStyle(.buttonPrimary) }
    func porteosMeta() -> some View { porteosTextStyle(.meta) }
    func porteosCliPrompt() -> some View { porteosTextStyle(.cliPrompt) }
    func porteosModuleCmd() -> some View { porteosTextStyle(.moduleCmd) }
    func porteosRowLabel() -> some View { porteosTextStyle(.rowLabel) }
    func porteosRowValue() -> some View { porteosTextStyle(.rowValue) }
    func porteosScoreHero() -> some View { porteosTextStyle(.scoreHero) }
    func porteosScoreGrade() -> some View { porteosTextStyle(.scoreGrade) }
}
