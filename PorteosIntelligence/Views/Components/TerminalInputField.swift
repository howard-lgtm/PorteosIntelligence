import SwiftUI

// MARK: - TerminalInputField
// Shared by NewDealSheet and EditDealSheet.

struct TerminalInputField: View {

    let label: String
    let placeholder: String
    let prefix: String?
    let suffix: String?
    @Binding var text: String

    private let shellBg      = Color(hex: "#0F1115")
    private let shellBorder  = Color(hex: "#2E333F")
    private let textPrimary  = Color(hex: "#F8F9FA")
    private let textTertiary = Color(hex: "#64748B")

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.custom("Inter", size: 11).weight(.bold))
                .tracking(0.05)
                .foregroundStyle(textTertiary)

            HStack(spacing: 0) {
                if let prefix {
                    Text(prefix)
                        .font(.custom("JetBrains Mono", size: 14))
                        .foregroundStyle(textTertiary)
                        .frame(width: 24)
                        .frame(height: 28)
                        .background(shellBg)
                        .overlay(alignment: .trailing) {
                            Rectangle().fill(shellBorder).frame(width: 1)
                        }
                }

                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.custom("JetBrains Mono", size: 14))
                    .foregroundStyle(textPrimary)
                    .monospacedDigit()
                    .padding(.horizontal, 8)
                    .frame(height: 28)

                if let suffix {
                    Text(suffix)
                        .font(.custom("JetBrains Mono", size: 14))
                        .foregroundStyle(textTertiary)
                        .frame(width: 24)
                        .frame(height: 28)
                        .background(shellBg)
                        .overlay(alignment: .leading) {
                            Rectangle().fill(shellBorder).frame(width: 1)
                        }
                }
            }
            .background(shellBg)
            .overlay(
                Rectangle().strokeBorder(shellBorder, lineWidth: 1)
            )
            .cornerRadius(0)
        }
    }
}
