import SwiftUI

// MARK: - TerminalCLIHeader
// Shared CLI breadcrumb for dashboards, sheets, and detached panes.

struct TerminalCLIHeader: View {

    let command: String
    var accentColor: Color = DesignTokens.accentRust
    var height: CGFloat = DesignTokens.rowHeightHeader
    var horizontalPadding: CGFloat = DesignTokens.blockGutter
    var fontSize: CGFloat = 11

    var body: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(DesignTokens.mono(size: fontSize))
                .foregroundStyle(DesignTokens.textDim)
            Text(command)
                .font(DesignTokens.mono(size: fontSize, weight: .bold))
                .foregroundStyle(accentColor)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .frame(height: height)
        .background(DesignTokens.surfacePanel)
    }
}

// MARK: - TerminalSectionLabel

struct TerminalSectionLabel: View {

    let text: String

    var body: some View {
        Text(text)
            .font(DesignTokens.sectionLabelFont())
            .tracking(0.08)
            .foregroundStyle(DesignTokens.textDim)
    }
}

// MARK: - TerminalStructuralDivider

struct TerminalStructuralDivider: View {
    var body: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(height: DesignTokens.dividerWidth)
    }
}
