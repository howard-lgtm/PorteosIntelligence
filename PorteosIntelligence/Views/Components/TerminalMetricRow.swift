import SwiftUI

// MARK: - MetricState
// .critical is a legacy alias for .danger kept for backward compat.

enum MetricState {
    case neutral
    case optimal    // green value text
    case warning    // amber value text
    case danger     // red value text + red 2px left border
    case critical   // alias for .danger
}

// MARK: - TerminalMetricRow

struct TerminalMetricRow: View {

    let label: String
    let value: String
    let state: MetricState

    // MARK: Colors

    private let colorOptimal  = Color(hex: "#10B981")
    private let colorWarning  = Color(hex: "#F59E0B")
    private let colorDanger   = Color(hex: "#EF4444")
    private let valueBright   = Color(hex: "#FFFFFF")
    private let labelDim      = Color(hex: "#475569")   // Slate-600

    // MARK: Derived

    private var valueColor: Color {
        switch state {
        case .neutral:           return valueBright
        case .optimal:           return colorOptimal
        case .warning:           return colorWarning
        case .danger, .critical: return colorDanger
        }
    }

    // Left border: danger/critical only
    private var dangerBorder: Color? {
        switch state {
        case .danger, .critical: return colorDanger
        default:                 return nil
        }
    }

    // MARK: Body

    var body: some View {
        HStack(spacing: 0) {
            if let border = dangerBorder {
                Rectangle()
                    .fill(border)
                    .frame(width: 2)
            }

            HStack(spacing: 0) {
                Text(label.uppercased())
                    .font(.custom("JetBrains Mono", size: 13).weight(.regular))
                    .tracking(0.02)
                    .foregroundStyle(labelDim)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                Text(value)
                    .font(.custom("JetBrains Mono", size: 17).weight(.bold))
                    .monospacedDigit()
                    .tracking(-0.02)
                    .foregroundStyle(valueColor)
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 40)
        .clipShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        TerminalMetricRow(label: "Net Operating Income", value: "€125,000",  state: .neutral)
        TerminalMetricRow(label: "Cap Rate",             value: "6.20%",     state: .optimal)
        TerminalMetricRow(label: "Vacancy Rate",         value: "9.50%",     state: .warning)
        TerminalMetricRow(label: "DSCR",                 value: "0.98x",     state: .danger)
        TerminalMetricRow(label: "LTV Ratio",            value: "94.10%",    state: .critical)
    }
    .frame(width: 420)
    .padding(16)
    .background(Color(hex: "#0F1115"))
}
