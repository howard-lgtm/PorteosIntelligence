import SwiftUI

// MARK: - MetricWithTrend
// Drop-in replacement for MetricGridCell that adds a TerminalSparkline.
// Maintains identical external dimensions (vertical padding, maxWidth) so it
// slots cleanly into existing LazyVGrid layouts.

struct MetricWithTrend: View {

    let label:      String
    let value:      String
    let trend:      [Double]
    let trendColor: Color
    var state:      MetricState = .neutral

    // MARK: Colors – mirrors MetricGridCell exactly

    private let colorOptimal = Color(hex: "#10B981")
    private let colorWarning = Color(hex: "#F59E0B")
    private let colorDanger  = Color(hex: "#EF4444")
    private let valueBright  = Color(hex: "#F8FAFC")
    private let labelDim     = Color(hex: "#64748B")

    private var valueColor: Color {
        switch state {
        case .neutral:           return valueBright
        case .optimal:           return colorOptimal
        case .warning:           return colorWarning
        case .danger, .critical: return colorDanger
        }
    }

    // MARK: Body

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            // Label + Value (left side)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.custom("JetBrains Mono", size: 11).weight(.medium))
                    .tracking(0.02)
                    .foregroundStyle(labelDim)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(value)
                    .font(.custom("JetBrains Mono", size: 14).weight(.bold))
                    .monospacedDigit()
                    .tracking(-0.02)
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
            }

            // Sparkline (right side) – only rendered when there is data
            if trend.count >= 2 {
                Spacer(minLength: 4)
                TerminalSparkline(data: trend, color: trendColor, height: 24)
                    .frame(width: 60, height: 24)
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    let upTrend:   [Double] = [88, 90, 87, 93, 96, 91, 98, 100, 97, 103, 108, 112]
    let downTrend: [Double] = [115, 110, 112, 106, 102, 99, 96, 98, 93, 89, 85, 82]

    return LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 140, maximum: 220), spacing: 8, alignment: .leading)],
        alignment: .leading,
        spacing: 4
    ) {
        MetricWithTrend(label: "NOI",              value: "€125,000", trend: upTrend,   trendColor: Color(hex: "#10B981"))
        MetricWithTrend(label: "Cap Rate",         value: "6.20%",    trend: upTrend,   trendColor: Color(hex: "#10B981"), state: .optimal)
        MetricWithTrend(label: "Cash Flow",        value: "€18,400",  trend: downTrend, trendColor: Color(hex: "#EF4444"), state: .warning)
        MetricWithTrend(label: "Levered IRR",      value: "11.4%",    trend: upTrend,   trendColor: Color(hex: "#10B981"), state: .warning)
        MetricWithTrend(label: "Cash-on-Cash",     value: "7.2%",     trend: downTrend, trendColor: Color(hex: "#EF4444"))
        MetricWithTrend(label: "Occupancy",        value: "78.5%",    trend: upTrend,   trendColor: Color(hex: "#14B8A6"), state: .optimal)
    }
    .padding(12)
    .frame(width: 480)
    .background(Color(hex: "#0F1115"))
}
