import SwiftUI

// MARK: - GlobalCommandBar
// V2.06 footer: porteos@system prompt + input + UTF-8 LN:n

struct GlobalCommandBar: View {

    @State private var commandInput: String = ""
    var lineCount: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DesignTokens.dividerStructural)
                .frame(height: DesignTokens.dividerWidth)

            HStack(spacing: 0) {
                Text("porteos@system ~ % ")
                    .font(DesignTokens.cliPromptFont())
                    .foregroundStyle(DesignTokens.textDim)

                TextField("", text: $commandInput)
                    .font(DesignTokens.cliPromptFont())
                    .foregroundStyle(DesignTokens.textPrimary)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)

                BlinkingCursorView()
                    .padding(.trailing, 8)

                Text("UTF-8")
                    .font(DesignTokens.metaFont())
                    .foregroundStyle(DesignTokens.textDim)

                Text("LN:\(lineCount)")
                    .font(DesignTokens.metaFont())
                    .foregroundStyle(DesignTokens.textDim)
                    .monospacedDigit()
                    .padding(.leading, 8)
            }
            .padding(.horizontal, 12)
            .frame(height: DesignTokens.rowHeightCommandBar)
            .background(DesignTokens.surfacePanel)
        }
    }
}

// MARK: - Preview

#Preview {
    GlobalCommandBar(lineCount: 0)
        .frame(width: 1200)
        .background(DesignTokens.canvasBase)
}
