import SwiftUI

// MARK: - SystemLogBlock
//
// Renders a terminal-style validation log.
// Returns EmptyView when there are no messages — zero layout impact.

struct SystemLogBlock: View {

    let messages: [ValidationMessage]

    private var borderColor: Color {
        messages.contains(where: { $0.severity == .critical })
            ? DesignTokens.statusCritical
            : DesignTokens.statusWarn
    }

    var body: some View {
        if messages.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(borderColor)
                    .frame(width: DesignTokens.profileBarHeight)

                VStack(alignment: .leading, spacing: 0) {
                    header
                    Rectangle().fill(borderColor.opacity(0.5)).frame(height: DesignTokens.dividerWidth)
                    logLines
                }
                .background(DesignTokens.surfacePanel)
            }
            .overlay {
                Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
            }
            .clipShape(Rectangle())
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .porteosCliPrompt()
                .foregroundStyle(DesignTokens.textDim)
            Text("./validate --strict")
                .porteosButtonPrimary()
                .foregroundStyle(DesignTokens.accentRust)

            Spacer()

            Text("\(messages.count) issue\(messages.count == 1 ? "" : "s")")
                .porteosButtonPrimary()
                .foregroundStyle(borderColor)
                .padding(.trailing, DesignTokens.blockGutter)
        }
        .padding(.leading, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader)
        .background(DesignTokens.surfaceElevated)
    }

    private var logLines: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(messages) { msg in
                logRow(msg)
                if msg.id != messages.last?.id {
                    Rectangle()
                        .fill(DesignTokens.dividerStructural)
                        .frame(height: DesignTokens.dividerWidth)
                        .padding(.leading, DesignTokens.blockGutter)
                }
            }
        }
        .padding(.bottom, 4)
        .background(DesignTokens.canvasBase)
    }

    private func logRow(_ msg: ValidationMessage) -> some View {
        let tagColor: Color = msg.severity == .critical ? DesignTokens.statusCritical : DesignTokens.statusWarn

        return HStack(alignment: .top, spacing: 8) {
            Text(msg.prefix)
                .porteosButtonPrimary()
                .foregroundStyle(tagColor)
                .frame(width: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(msg.field.uppercased())
                    .porteosButtonPrimary()
                    .foregroundStyle(tagColor.opacity(0.8))

                Text(msg.message)
                    .porteosRowValue()
                    .foregroundStyle(DesignTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, DesignTokens.metricCellPadding)
    }
}

#Preview("With Errors") {
    let messages: [ValidationMessage] = [
        .init(severity: .critical, field: "LTV",
              message: "Loan (€1,600,000) exceeds Purchase Price (€1,200,000). LTV 133.3%."),
        .init(severity: .warning,  field: "Cap Rate / NOI",
              message: "Operating expenses ≥ effective income. NOI is non-positive (−€12,000)."),
        .init(severity: .critical, field: "Booking Channels",
              message: "Direct booking (70%) + OTA (45%) = 115% — exceeds 100%."),
    ]
    SystemLogBlock(messages: messages)
        .padding(DesignTokens.blockGutter)
        .frame(width: 700)
        .background(DesignTokens.canvasBase)
}

#Preview("Empty — no render") {
    SystemLogBlock(messages: [])
        .frame(width: 700, height: 100)
        .background(DesignTokens.canvasBase)
}
