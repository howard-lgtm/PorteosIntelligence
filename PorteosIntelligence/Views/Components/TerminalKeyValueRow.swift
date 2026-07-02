import SwiftUI

// MARK: - TerminalKeyValueRow
// Sheet / inspector label-value row @ 28pt — 40% label, 60% value.

struct TerminalKeyValueRow: View {

    let label: String
    let value: String
    var state: MetricState = .neutral
    var labelWidthFraction: CGFloat = 0.4

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                if let border = state.highlightBorderColor {
                    border
                        .frame(width: DesignTokens.navSelectionBorder)
                }

                Text(label.uppercased())
                    .font(DesignTokens.sectionLabelFont())
                    .tracking(0.08)
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(width: labelColumnWidth(in: geo.size.width), alignment: .leading)
                    .lineLimit(1)

                Text(value)
                    .font(DesignTokens.primaryMetricFont())
                    .monospacedDigit()
                    .foregroundStyle(state.semanticColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)
            }
            .padding(.horizontal, DesignTokens.cellInternalPadding)
            .frame(width: geo.size.width, height: DesignTokens.rowHeightData, alignment: .leading)
            .background(state.highlightBackgroundOpacity > 0
                        ? state.semanticColor.opacity(state.highlightBackgroundOpacity)
                        : Color.clear)
        }
        .frame(height: DesignTokens.rowHeightData)
    }

    private func labelColumnWidth(in totalWidth: CGFloat) -> CGFloat {
        let border: CGFloat = state.highlightBorderColor == nil ? 0 : DesignTokens.navSelectionBorder
        let inner = totalWidth - border - DesignTokens.cellInternalPadding * 2
        return inner * labelWidthFraction
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TerminalKeyValueRow(label: "Purchase Price", value: "€2,450,000")
        Rectangle().fill(DesignTokens.dividerStructural).frame(height: 1)
        TerminalKeyValueRow(label: "Cap Rate", value: "6.20%", state: .optimal)
        Rectangle().fill(DesignTokens.dividerStructural).frame(height: 1)
        TerminalKeyValueRow(label: "DSCR", value: "0.98x", state: .danger)
    }
    .padding(DesignTokens.blockGutter)
    .background(DesignTokens.surfacePanel)
}
