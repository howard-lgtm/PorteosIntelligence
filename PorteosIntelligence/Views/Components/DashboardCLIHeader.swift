import SwiftUI

// MARK: - DashboardCLIHeader
// Figma handoff: porteos@{profile} ~ % ./dashboard --asset="{deal}"

struct DashboardCLIHeader: View {

    let profile: ProfileType
    let dealName: String

    private var accent: Color { profile.accentColor }
    private var asset: String { dealName.isEmpty ? "Untitled Deal" : dealName }

    var body: some View {
        HStack(spacing: 0) {
            Text("porteos@\(profile.cliHost) ~ % ")
                .font(DesignTokens.cliPromptFont())
                .foregroundStyle(DesignTokens.textDim)
            Text(profile.dashboardCLI(assetName: asset))
                .font(DesignTokens.moduleCommandFont())
                .foregroundStyle(accent)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader)
        .background(DesignTokens.surfacePanel)
    }
}
