import SwiftUI

// MARK: - TerminalBlock
// V2.06 Figma module chrome: 4px profile accent strip + panel + divider border.

struct TerminalBlock<Content: View>: View {

    let command: String
    let accentColor: Color
    var contentPadding: CGFloat = DesignTokens.blockGutter
    var headerActionLabel: String? = nil
    var onHeaderAction: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(accentColor)
                .frame(width: DesignTokens.profileBarHeight)

            VStack(alignment: .leading, spacing: 0) {
                blockHeader
                TerminalStructuralDivider()
                contentArea
            }
        }
        .background(DesignTokens.surfacePanel)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
    }

    private var blockHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .porteosCliPrompt()
                .foregroundStyle(DesignTokens.textDim)

            Text(command)
                .porteosModuleCmd()
                .foregroundStyle(accentColor)

            Spacer()

            if let headerActionLabel, let onHeaderAction {
                Button(action: onHeaderAction) {
                    Text(headerActionLabel)
                        .porteosMeta()
                        .foregroundStyle(accentColor)
                }
                .buttonStyle(.plain)
                .disabled(headerActionLabel.contains("…"))
            }
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightData)
        .background(DesignTokens.surfaceElevated)
    }

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(contentPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.canvasBase)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignTokens.blockSpacing) {
        TerminalBlock(command: "01 // CORE_FINANCIALS_REVENUE", accentColor: DesignTokens.accentRust) {
            TerminalMetricGrid(fixedColumnCount: 2) {
                TerminalMetricCell(label: "NOI", value: "€125,000")
                TerminalMetricCell(label: "Cap Rate", value: "6.20%", state: .optimal)
            }
        }
    }
    .padding(DesignTokens.blockGutter)
    .frame(width: 520)
    .background(DesignTokens.canvasBase)
}
