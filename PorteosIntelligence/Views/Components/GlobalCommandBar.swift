import SwiftUI

// MARK: - GlobalCommandBar
// Fixed 32pt bar pinned to the bottom of AppShell.
// Left: prompt prefix + text input field.
// Right: encoding / line-count indicator.

struct GlobalCommandBar: View {

    @State private var commandInput: String = ""
    var lineCount: Int = 120

    // MARK: Tokens

    private let shellBg      = Color(hex: "#0F1115")
    private let shellBorder  = Color(hex: "#2E333F")
    private let textPrimary  = Color(hex: "#F8F9FA")
    private let textTertiary = Color(hex: "#64748B")

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(shellBorder)
                .frame(height: 1)

            HStack(spacing: 0) {
                // Prompt prefix
                Text("porteos@system ~ %")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textTertiary)
                    .padding(.trailing, 8)

                // Command input
                TextField("", text: $commandInput)
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textPrimary)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)

                // Right-side status
                Text("UTF-8  LN: \(lineCount)")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textTertiary)
                    .padding(.leading, 16)
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(shellBg)
        }
    }
}

// MARK: - Preview

#Preview {
    GlobalCommandBar(lineCount: 120)
        .frame(width: 1200)
        .background(Color(hex: "#0F1115"))
}
