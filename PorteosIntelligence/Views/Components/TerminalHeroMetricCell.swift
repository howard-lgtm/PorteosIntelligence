import SwiftUI

// MARK: - TerminalHeroMetricCell
// Command-center hero KPI — 36pt value in inset bordered plate.

struct TerminalHeroMetricCell: View {

    let label: String
    let value: String
    var subtitle: String? = nil
    var state: MetricState = .neutral
    var identityAccent: Color? = nil

    var body: some View {
        HStack(spacing: 0) {
            if let accent = identityAccent {
                accent.frame(width: DesignTokens.navSelectionBorder)
            } else if let border = state.highlightBorderColor {
                border.frame(width: DesignTokens.navSelectionBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(label.uppercased())
                    .font(DesignTokens.metricLabelFont())
                    .tracking(0.02)
                    .foregroundStyle(DesignTokens.textDim)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(value)
                    .font(DesignTokens.heroScoreFont())
                    .monospacedDigit()
                    .foregroundStyle(state.semanticColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let subtitle {
                    Text(subtitle.uppercased())
                        .font(DesignTokens.metaFont())
                        .tracking(0.04)
                        .foregroundStyle(DesignTokens.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(DesignTokens.heroCellPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: DesignTokens.heroCellMinHeight, alignment: .leading)
        .background(DesignTokens.surfaceElevated)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
    }
}

// MARK: - TerminalProfileHealthCell
// Profile score with thick accent bar — Cmd Center module 02.

struct TerminalProfileHealthCell: View {

    let label: String
    let score: Double
    let dealCount: Int
    let accent: Color

    private var scoreState: MetricState {
        guard dealCount > 0 else { return .neutral }
        if score >= 80 { return .optimal }
        if score >= 60 { return .warning }
        return .danger
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(label.uppercased())
                    .font(DesignTokens.metricLabelFont())
                    .tracking(0.02)
                    .foregroundStyle(DesignTokens.textDim)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(dealCount > 0 ? String(format: "%.1f", score) : "—")
                    .font(DesignTokens.heroGradeFont())
                    .monospacedDigit()
                    .foregroundStyle(dealCount > 0 ? scoreState.semanticColor : DesignTokens.textDim)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(DesignTokens.dividerStructural)
                    Rectangle()
                        .fill(dealCount > 0 ? accent : DesignTokens.dividerStructural)
                        .frame(width: dealCount > 0 ? max(0, geo.size.width * (score / 100)) : 0)
                }
                .clipShape(Rectangle())
            }
            .frame(height: DesignTokens.profileBarHeight)

            if dealCount > 0 {
                Text("\(dealCount) DEAL\(dealCount == 1 ? "" : "S")  ·  /100")
                    .font(DesignTokens.metaFont())
                    .foregroundStyle(DesignTokens.textDim)
            }
        }
        .padding(DesignTokens.metricCellPadding)
        .frame(maxWidth: .infinity, minHeight: DesignTokens.profileCellMinHeight, alignment: .leading)
        .background(DesignTokens.surfaceElevated)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
    }
}

// MARK: - TerminalDistributionCell
// Weight bar cell — Cmd Center module 03.

struct TerminalDistributionCell: View {

    let label: String
    let pct: Double
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(label.uppercased())
                    .font(DesignTokens.metricLabelFont())
                    .tracking(0.02)
                    .foregroundStyle(DesignTokens.textDim)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text("\(pct.formatted(.number.precision(.fractionLength(1))))%")
                    .font(DesignTokens.heroGradeFont())
                    .monospacedDigit()
                    .foregroundStyle(accent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(DesignTokens.dividerStructural)
                    Rectangle()
                        .fill(accent)
                        .frame(width: max(0, geo.size.width * (pct / 100)))
                }
                .clipShape(Rectangle())
            }
            .frame(height: DesignTokens.profileBarHeight)
        }
        .padding(DesignTokens.metricCellPadding)
        .frame(maxWidth: .infinity, minHeight: DesignTokens.profileCellMinHeight, alignment: .leading)
        .background(DesignTokens.surfaceElevated)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 6) {
        TerminalMetricGrid {
            TerminalHeroMetricCell(label: "Total Portfolio Value", value: "€6,945,000")
            TerminalHeroMetricCell(label: "Total Deals", value: "12", subtitle: "ACTIVE PORTFOLIO")
            TerminalHeroMetricCell(label: "Avg Porteos Score", value: "73", subtitle: "GRADE B", state: .warning)
        }
        TerminalMetricGrid {
            TerminalProfileHealthCell(label: "Real Estate", score: 99.4, dealCount: 8, accent: Color(hex: "#C25E30"))
            TerminalProfileHealthCell(label: "Hospitality", score: 72.1, dealCount: 4, accent: Color(hex: "#14B8A6"))
        }
    }
    .padding(DesignTokens.blockGutter)
    .frame(width: 720)
    .background(DesignTokens.canvasBase)
}
