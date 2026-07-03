import SwiftUI

// MARK: - TerminalMetricCell
// V2.06 Figma handoff — value above label, inset cell, no sparklines in grids.

struct TerminalMetricCell: View {

    let label: String
    let value: String
    var state: MetricState = .neutral
    var trend: [Double] = []
    var trendColor: Color? = nil

    private var resolvedTrendColor: Color {
        if let trendColor { return trendColor }
        guard trend.count >= 2 else { return DesignTokens.textDim }
        let delta = (trend.last ?? 0) - (trend.first ?? 0)
        return TerminalSparkline.color(forDelta: delta)
    }

    var body: some View {
        HStack(spacing: 0) {
            if let accent = state.highlightBorderColor {
                accent.frame(width: DesignTokens.navSelectionBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(DesignTokens.metricValueFont())
                    .monospacedDigit()
                    .foregroundStyle(state.semanticColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(label.uppercased())
                    .font(DesignTokens.metricLabelFont())
                    .tracking(0.02)
                    .foregroundStyle(DesignTokens.textDim)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if trend.count >= 2 {
                    TerminalSparkline(data: trend, color: resolvedTrendColor,
                                      height: DesignTokens.sparklineHeight)
                        .frame(width: DesignTokens.sparklineWidth,
                               height: DesignTokens.sparklineHeight)
                }
            }
            .padding(DesignTokens.metricCellPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: DesignTokens.metricCellMinHeight, alignment: .leading)
        .background(DesignTokens.surfaceElevated)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
    }
}

#Preview {
    let trend: [Double] = [88, 90, 87, 93, 96, 91, 98, 100, 97, 103, 108, 112]

    return TerminalMetricGrid {
        TerminalMetricCell(label: "ADR (Avg Daily Rate)", value: "€185", trend: trend)
        TerminalMetricCell(label: "Occupancy Rate", value: "95.0%", state: .optimal, trend: trend)
        TerminalMetricCell(label: "GOP Margin", value: "0.0%", state: .danger)
        TerminalMetricCell(label: "RevPAR", value: "€144")
        TerminalMetricCell(label: "TRevPAR", value: "€168")
        TerminalMetricCell(label: "Distribution Cost", value: "€180,000")
    }
    .padding(DesignTokens.blockGutter)
    .frame(width: 720)
    .background(DesignTokens.canvasBase)
}
