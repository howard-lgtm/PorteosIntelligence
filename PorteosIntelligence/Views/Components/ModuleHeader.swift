import SwiftUI

// MARK: - ModuleHeader
// Numbered section header: `01 // MODULE_NAME`

struct ModuleHeader: View {

    let number: Int
    let title: String

    var body: some View {
        HStack(spacing: 0) {
            Text(String(format: "%02d", number))
                .font(DesignTokens.moduleCommandFont())
                .foregroundStyle(DesignTokens.textSecondary)

            Text(" // ")
                .font(DesignTokens.moduleCommandFont())
                .foregroundStyle(DesignTokens.textDim)

            Text(title.uppercased())
                .font(DesignTokens.sectionLabelFont())
                .tracking(0.08)
                .foregroundStyle(DesignTokens.textDim)

            Spacer()
        }
        .frame(height: DesignTokens.rowHeightHeader)
        .padding(.horizontal, DesignTokens.blockGutter)
    }
}

#Preview {
    VStack(spacing: 0) {
        ModuleHeader(number: 1, title: "Core Financials")
        ModuleHeader(number: 2, title: "Debt Service")
        ModuleHeader(number: 3, title: "Circular Economy")
    }
    .frame(width: 400)
    .background(DesignTokens.surfacePanel)
}
