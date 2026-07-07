import SwiftUI

// MARK: - TopHeaderBar
// V2.06 shell header — CLI prompt + profile command | deal breadcrumb | server LED.

struct TopHeaderBar: View {

    let activeProfile: ProfileType
    var selectedDealName: String? = nil
    var onServerTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                cliPrompt
                Spacer(minLength: 16)
                dealBreadcrumb
                Spacer(minLength: 16)
                statusIndicators
            }
            .padding(.horizontal, 16)
            .frame(height: DesignTokens.rowHeightPaneBar)
            .background(DesignTokens.canvasBase)

            Rectangle()
                .fill(DesignTokens.dividerStructural)
                .frame(height: DesignTokens.dividerWidth)
        }
    }

    private var cliPrompt: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .porteosCliPrompt()
                .foregroundStyle(DesignTokens.textDim)
            Text(activeProfile.commandLine)
                .porteosModuleCmd()
                .foregroundStyle(activeProfile.accentColor)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var dealBreadcrumb: some View {
        if let name = selectedDealName, !name.isEmpty {
            Text("--asset=\"\(name)\"")
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textSecondary)
                .lineLimit(1)
        }
    }

    private var statusIndicators: some View {
        HStack(spacing: 12) {
            ServerStatusIndicator(onTap: onServerTap)

            Rectangle()
                .fill(DesignTokens.dividerStructural)
                .frame(width: 1, height: 16)

            Text("[ ↗ ]")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TopHeaderBar(
            activeProfile: .realEstate,
            selectedDealName: "Lisbon Office Block A"
        )
        TopHeaderBar(activeProfile: .cmdCenter)
    }
    .frame(width: 1200)
    .background(DesignTokens.canvasBase)
}
