import SwiftUI

// MARK: - GlobalCommandBar
// V2.06 footer: prompt + blinking cursor | MAN_PAGES SYS_STAT KERNEL_LOG

struct GlobalCommandBar: View {

    @State private var commandInput: String = ""
    var lineCount: Int = 120

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DesignTokens.dividerStructural)
                .frame(height: DesignTokens.dividerWidth)

            HStack(spacing: 0) {
                Text("porteos@system ~ % ")
                    .font(DesignTokens.mono(size: 11))
                    .foregroundStyle(DesignTokens.textDim)

                TextField("", text: $commandInput)
                    .font(DesignTokens.mono(size: 11))
                    .foregroundStyle(DesignTokens.textPrimary)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)

                BlinkingCursorView()
                    .padding(.trailing, 16)

                footerMonitors
            }
            .padding(.horizontal, 12)
            .frame(height: DesignTokens.rowHeightButton)
            .background(DesignTokens.canvasBase)
        }
    }

    private var footerMonitors: some View {
        HStack(spacing: 12) {
            footerTag("MAN_PAGES")
            footerTag("SYS_STAT")
            footerTag("KERNEL_LOG")
            Text("LN:\(lineCount)")
                .font(DesignTokens.mono(size: 10))
                .foregroundStyle(DesignTokens.textDim)
                .monospacedDigit()
        }
    }

    private func footerTag(_ label: String) -> some View {
        Text(label)
            .font(DesignTokens.mono(size: 10, weight: .bold))
            .foregroundStyle(DesignTokens.textDim)
    }
}

// MARK: - Preview

#Preview {
    GlobalCommandBar(lineCount: 120)
        .frame(width: 1200)
        .background(DesignTokens.canvasBase)
}
