import SwiftUI

// MARK: - TerminalBlock

struct TerminalBlock<Content: View>: View {

    let command: String
    let accentColor: Color
    var contentPadding: CGFloat = 8
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            blockHeader
            Rectangle().fill(DesignTokens.dividerStructural).frame(height: 1)
            contentArea
        }
        .clipShape(Rectangle())
    }

    private var blockHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(DesignTokens.mono(size: 11))
                .foregroundStyle(DesignTokens.textDim)

            Text(command)
                .font(DesignTokens.mono(size: 11, weight: .medium))
                .foregroundStyle(accentColor)

            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: DesignTokens.rowHeightData)
    }

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
        TerminalBlock(command: "stats --quick-look", accentColor: DesignTokens.accentRust) {
            VStack(spacing: 0) {
                TerminalMetricRow(label: "Net Operating Income", value: "€125,000", state: .neutral)
                TerminalMetricRow(label: "Cap Rate",             value: "6.20%",    state: .optimal)
                TerminalMetricRow(label: "DSCR",                 value: "0.98",     state: .danger)
            }
        }
    }
    .padding(16)
    .frame(width: 520)
    .background(DesignTokens.canvasBase)
}
