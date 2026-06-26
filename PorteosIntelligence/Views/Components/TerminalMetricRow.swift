import SwiftUI

// MARK: - MetricState
// .critical is a legacy alias for .danger kept for backward compat.

enum MetricState {
    case neutral
    case optimal    // green text + green 2px left border + 5% green tint
    case warning    // amber text + amber 2px left border + 5% amber tint
    case danger     // red text   + red   2px left border + 5% red   tint
    case critical   // alias for .danger
}

// MARK: - TerminalMetricRow

struct TerminalMetricRow: View {

    let label: String
    let value: String
    let state: MetricState

    // MARK: Semantic Colors

    private let colorOptimal  = Color(hex: "#10B981")
    private let colorWarning  = Color(hex: "#F59E0B")
    private let colorDanger   = Color(hex: "#EF4444")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textTertiary  = Color(hex: "#64748B")

    // MARK: Derived

    private var valueColor: Color {
        switch state {
        case .neutral:              return textPrimary
        case .optimal:              return colorOptimal
        case .warning:              return colorWarning
        case .danger, .critical:    return colorDanger
        }
    }

    private var borderColor: Color? {
        switch state {
        case .optimal:              return colorOptimal
        case .warning:              return colorWarning
        case .danger, .critical:    return colorDanger
        default:                    return nil
        }
    }

    private var backgroundTint: Color? {
        switch state {
        case .optimal:              return colorOptimal
        case .warning:              return colorWarning
        case .danger, .critical:    return colorDanger
        default:                    return nil
        }
    }

    // MARK: Body

    var body: some View {
        HStack(spacing: 0) {
            // 2px left border for all non-neutral states
            if let border = borderColor {
                Rectangle()
                    .fill(border)
                    .frame(width: 2)
            }

            HStack(spacing: 0) {
                Text(label.uppercased())
                    .font(.custom("Inter", size: 11).weight(.bold))
                    .tracking(0.08)
                    .foregroundStyle(textTertiary)

                Spacer()

                Text(value)
                    .font(.custom("JetBrains Mono", size: 14).weight(.bold))
                    .monospacedDigit()
                    .tracking(-0.02)
                    .foregroundStyle(valueColor)
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 28)
        .background {
            if let tint = backgroundTint {
                tint.opacity(0.05)
            }
        }
        .clipShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TerminalMetricRow(label: "Net Operating Income", value: "€125,000.00", state: .neutral)
        TerminalMetricRow(label: "Cap Rate",             value: "6.20%",        state: .optimal)
        TerminalMetricRow(label: "Vacancy Rate",         value: "9.50%",        state: .warning)
        TerminalMetricRow(label: "DSCR",                 value: "0.98",         state: .danger)
        TerminalMetricRow(label: "LTV Ratio",            value: "94.10%",       state: .critical)
    }
    .frame(width: 400)
    .background(Color(hex: "#1A1D24"))
}
