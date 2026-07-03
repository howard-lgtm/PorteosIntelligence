import SwiftUI

// MARK: - ValidationLogModule
// Figma: 07 // VALIDATION_LOG — ERR/WARN rows inside TerminalBlock

struct ValidationLogModule: View {

    let messages: [ValidationMessage]
    var accentColor: Color = DesignTokens.accentRust

    var body: some View {
        if messages.isEmpty {
            EmptyView()
        } else {
            TerminalBlock(command: "07 // VALIDATION_LOG", accentColor: accentColor, contentPadding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { idx, msg in
                        validationRow(msg)
                        if idx < messages.count - 1 {
                            Rectangle()
                                .fill(DesignTokens.dividerStructural)
                                .frame(height: DesignTokens.dividerWidth)
                                .padding(.leading, DesignTokens.blockGutter)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func validationRow(_ msg: ValidationMessage) -> some View {
        let color: Color = msg.severity == .critical ? DesignTokens.statusCritical : DesignTokens.statusWarn
        let tag = msg.severity == .critical ? "ERR" : "WARN"

        return Text("\(tag) [\(msg.field.uppercased())] - \(msg.message)")
            .font(DesignTokens.rowValueFont())
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, DesignTokens.metricCellPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
