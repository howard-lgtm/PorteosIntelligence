import SwiftUI

// MARK: - TopHeaderBar
// V2.06: wordmark + `[ PROFILE // MODULE ]` (profile accent) + status strip.

struct TopHeaderBar: View {

    let activeProfile: ProfileType
    var onServerTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                wordmark
                Spacer()
                workspaceHeader
                Spacer()
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

    private var wordmark: some View {
        Text("INSTITUTIONAL_V2.06_STABLE")
            .font(DesignTokens.mono(size: 11, weight: .bold))
            .foregroundStyle(DesignTokens.accentRust)
    }

    private var workspaceHeader: some View {
        Text(activeProfile.workspaceHeaderTitle)
            .font(DesignTokens.mono(size: 11, weight: .bold))
            .foregroundStyle(activeProfile.accentColor)
    }

    private var statusIndicators: some View {
        HStack(spacing: 12) {
            ServerStatusIndicator(onTap: onServerTap)

            Rectangle()
                .fill(DesignTokens.dividerStructural)
                .frame(width: 1, height: 16)

            Text("[ ↗ ]")
                .font(DesignTokens.mono(size: 10))
                .foregroundStyle(DesignTokens.textDim)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TopHeaderBar(activeProfile: .realEstate)
        TopHeaderBar(activeProfile: .hospitality)
    }
    .frame(width: 1200)
    .background(DesignTokens.canvasBase)
}
