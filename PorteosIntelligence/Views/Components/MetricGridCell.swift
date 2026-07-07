import SwiftUI

// MARK: - MetricGridCell
// Legacy wrapper — delegates to TerminalMetricCell for V2.06 grid consistency.
// Used in dashboards not yet migrated to TerminalMetricGrid.

struct MetricGridCell: View {

    let label: String
    let value: String
    var state: MetricState = .neutral

    var body: some View {
        TerminalMetricCell(label: label, value: value, state: state)
    }
}

// MARK: - Preview

#Preview {
    TerminalMetricGrid {
        MetricGridCell(label: "Net Operating Income", value: "€125,000")
        MetricGridCell(label: "Cap Rate", value: "6.20%", state: .optimal)
        MetricGridCell(label: "Vacancy Rate", value: "9.50%", state: .warning)
        MetricGridCell(label: "DSCR", value: "0.98x", state: .danger)
    }
    .padding(DesignTokens.blockGutter)
    .frame(width: 720)
    .background(DesignTokens.canvasBase)
}
