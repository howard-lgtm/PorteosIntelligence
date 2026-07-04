import SwiftUI

// MARK: - MetricState

enum MetricState {
    case neutral
    case optimal
    case warning
    case danger
    case critical   // alias for .danger
}

// MARK: - TerminalMetricRow
// V2.06: 28pt data row, tabular numbers, semantic terminal palette.

struct TerminalMetricRow: View {

    let label: String
    let value: String
    let state: MetricState
    /// Optional ASCII gauge appended after the value (LTV, DSCR, occupancy).
    var gaugeFillRatio: Double? = nil

    var body: some View {
        HStack(spacing: 0) {
            if let border = state.highlightBorderColor {
                Rectangle()
                    .fill(border)
                    .frame(width: DesignTokens.navSelectionBorder)
            }

            HStack(spacing: 8) {
                Text(label.uppercased())
                    .porteosRowLabel()
                    .foregroundStyle(DesignTokens.textDim)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                if let ratio = gaugeFillRatio {
                    TerminalAsciiGauge(fillRatio: ratio, state: state)
                }

                Text(value)
                    .porteosRowValue()
                    .monospacedDigit()
                    .foregroundStyle(state.semanticColor)
            }
            .padding(.horizontal, 8)
        }
        .frame(height: DesignTokens.rowHeightData)
        .background(state.highlightBackgroundOpacity > 0
                    ? state.semanticColor.opacity(state.highlightBackgroundOpacity)
                    : Color.clear)
        .clipShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TerminalMetricRow(label: "Net Operating Income", value: "€125,000",  state: .neutral)
        TerminalMetricRow(label: "Cap Rate",             value: "6.20%",     state: .optimal, gaugeFillRatio: 0.62)
        TerminalMetricRow(label: "Vacancy Rate",         value: "9.50%",     state: .warning, gaugeFillRatio: 0.38)
        TerminalMetricRow(label: "DSCR",                 value: "0.98x",     state: .danger,  gaugeFillRatio: 0.22)
    }
    .frame(width: 420)
    .padding(16)
    .background(DesignTokens.canvasBase)
}
