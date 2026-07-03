import SwiftUI

// MARK: - ModuleHeader
// Numbered section header following the terminal convention:
//   `01 // MODULE_NAME`
// Used above each data block to give it an index and a clear identity.

struct ModuleHeader: View {

    let number: Int
    let title: String

    // MARK: Tokens

    private let shellBorder  = DesignTokens.dividerStructural
    private let textTertiary = DesignTokens.textDim
    private let textSecondary = DesignTokens.textSecondary

    // MARK: Body

    var body: some View {
        HStack(spacing: 0) {
            // Zero-padded index
            Text(String(format: "%02d", number))
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(textSecondary)

            // Separator
            Text(" // ")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textTertiary)

            // Module name
            Text(title.uppercased())
                .font(.custom("JetBrains Mono", size: 11))
                .tracking(0.08)
                .foregroundStyle(textTertiary)

            Spacer()
        }
        .frame(height: 24)
        .padding(.horizontal, 12)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        ModuleHeader(number: 1, title: "Core Financials")
        ModuleHeader(number: 2, title: "Debt Service")
        ModuleHeader(number: 3, title: "Circular Economy")
        ModuleHeader(number: 12, title: "Porteos Score")
    }
    .frame(width: 400)
    .background(DesignTokens.surfacePanel)
}
