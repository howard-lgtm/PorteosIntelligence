import SwiftUI

// MARK: - TopHeaderBar
// Fixed 40pt bar pinned to the top of AppShell.
// Left:   PORTEOS_TERMINAL_v1.0.4 (bold wordmark)
// Center: dynamic profile command path (accent-colored)
// Right:  system status indicators

struct TopHeaderBar: View {

    let activeProfile: ProfileType
    var onServerTap: () -> Void = {}

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellBorder   = Color(hex: "#2E333F")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                wordmark
                Spacer()
                commandPath
                Spacer()
                statusIndicators
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(shellBg)

            Rectangle()
                .fill(shellBorder)
                .frame(height: 1)
        }
    }

    // MARK: Wordmark

    private var wordmark: some View {
        Text("PORTEOS_TERMINAL_v1.0.4")
            .font(.custom("JetBrains Mono", size: 12).weight(.bold))
            .foregroundStyle(textPrimary)
    }

    // MARK: Dynamic Command Path

    private var commandPath: some View {
        HStack(spacing: 6) {
            Text("porteos@system ~ %")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textTertiary)

            Text(activeProfile.commandLine)
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(activeProfile.accentColor)
        }
    }

    // MARK: Status Indicators

    private var statusIndicators: some View {
        HStack(spacing: 12) {
            // Ingestion server status — click opens config sheet
            ServerStatusIndicator(onTap: onServerTap)

            // Divider pip
            Rectangle()
                .fill(Color(hex: "#2E333F"))
                .frame(width: 1, height: 16)

            // Notification indicator
            Image(systemName: "bell")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(textTertiary)

            // Settings indicator
            Image(systemName: "gearshape")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(textTertiary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TopHeaderBar(activeProfile: .realEstate)
        TopHeaderBar(activeProfile: .circular)
        TopHeaderBar(activeProfile: .hospitality)
    }
    .frame(width: 1200)
    .background(Color(hex: "#0F1115"))
}
