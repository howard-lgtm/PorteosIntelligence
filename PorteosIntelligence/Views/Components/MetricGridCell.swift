import SwiftUI

// MARK: - MetricGridCell
// Grid-friendly metric tile: label (top) + value (bottom).
// Used inside LazyVGrid in all dashboard views.
// DO NOT use TerminalMetricRow inside grids — it is list-only.

struct MetricGridCell: View {

    let label: String
    let value: String
    var state: MetricState = .neutral

    private let colorOptimal  = Color(hex: "#10B981")
    private let colorWarning  = Color(hex: "#F59E0B")
    private let colorDanger   = Color(hex: "#EF4444")
    private let valueBright   = Color(hex: "#F8FAFC")
    private let labelDim      = Color(hex: "#64748B")

    private var valueColor: Color {
        switch state {
        case .neutral:           return valueBright
        case .optimal:           return colorOptimal
        case .warning:           return colorWarning
        case .danger, .critical: return colorDanger
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.custom("JetBrains Mono", size: 13).weight(.medium))
                .tracking(0.02)
                .foregroundStyle(labelDim)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .font(.custom("JetBrains Mono", size: 17).weight(.bold))
                .monospacedDigit()
                .tracking(-0.02)
                .foregroundStyle(valueColor)
                .lineLimit(1)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 160, maximum: 250), spacing: 16, alignment: .leading)],
        alignment: .leading,
        spacing: 12
    ) {
        MetricGridCell(label: "Net Operating Income", value: "€125,000")
        MetricGridCell(label: "Cap Rate",             value: "6.20%",  state: .optimal)
        MetricGridCell(label: "Vacancy Rate",         value: "9.50%",  state: .warning)
        MetricGridCell(label: "DSCR",                 value: "0.98x",  state: .danger)
        MetricGridCell(label: "Loan-to-Value",        value: "75.0%",  state: .neutral)
        MetricGridCell(label: "Cash-on-Cash Return",  value: "8.40%",  state: .optimal)
    }
    .padding(16)
    .frame(width: 660)
    .background(Color(hex: "#0F1115"))
}
