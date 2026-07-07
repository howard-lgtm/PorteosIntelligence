import SwiftUI

// MARK: - TerminalTagChip
// V2.06 tag repository: border-only bracketed chip, no background fill.

struct TerminalTagChip: View {
    let name: String

    var body: some View {
        Text("[\(name)]")
            .porteosMeta()
            .foregroundStyle(DesignTokens.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .overlay(
                Rectangle()
                    .stroke(DesignTokens.dividerStructural, lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 6) {
        TerminalTagChip(name: "email_import")
        TerminalTagChip(name: "source:idealista")
    }
    .padding()
    .background(DesignTokens.surfacePanel)
}
