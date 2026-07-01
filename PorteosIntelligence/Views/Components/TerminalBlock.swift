import SwiftUI

// MARK: - TerminalBlock
// Reusable container that wraps any content in a CLI-styled terminal block.
// Header mimics a shell command execution line; body is the "output".

struct TerminalBlock<Content: View>: View {

    let command: String
    let accentColor: Color
    /// Padding applied around the content area. Pass `0` for full-bleed lists of TerminalMetricRows.
    var contentPadding: CGFloat = 12
    @ViewBuilder let content: () -> Content

    // MARK: Tokens

    private let shellBorder  = Color(hex: "#2E333F")
    private let textTertiary = Color(hex: "#64748B")

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            blockHeader
            Rectangle().fill(shellBorder).frame(height: 1)
            contentArea
        }
        .clipShape(Rectangle())
    }

    // MARK: Header

    private var blockHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textTertiary)

            Text(command)
                .font(.custom("JetBrains Mono", size: 11).weight(.medium))
                .foregroundStyle(textTertiary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 24)
    }

    // MARK: Content Area (16pt padding)

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(contentPadding)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        TerminalBlock(command: "stats --quick-look", accentColor: Color(hex: "#C25E30")) {
            VStack(spacing: 0) {
                TerminalMetricRow(label: "Net Operating Income", value: "€125,000", state: .neutral)
                TerminalMetricRow(label: "Cap Rate",             value: "6.20%",    state: .optimal)
                TerminalMetricRow(label: "DSCR",                 value: "0.98",     state: .danger)
            }
        }

        TerminalBlock(command: "hospitality --dashboard", accentColor: Color(hex: "#14B8A6")) {
            TerminalMetricRow(label: "Occupancy Rate", value: "78.5%", state: .warning)
        }
    }
    .padding(16)
    .frame(width: 520)
    .background(Color(hex: "#0F1115"))
}
