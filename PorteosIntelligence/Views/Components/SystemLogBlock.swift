import SwiftUI

// MARK: - SystemLogBlock
//
// Renders a terminal-style validation log.
// Returns EmptyView when there are no messages — zero layout impact.

struct SystemLogBlock: View {

    let messages: [ValidationMessage]

    // MARK: Tokens

    private let shellSurface = Color(hex: "#1A1D24")
    private let shellBorder  = Color(hex: "#2E333F")
    private let accentRust   = Color(hex: "#C25E30")
    private let textPrimary  = Color(hex: "#F8F9FA")
    private let textTertiary = Color(hex: "#64748B")
    private let colorCrit    = Color(hex: "#EF4444")
    private let colorWarn    = Color(hex: "#F59E0B")

    // MARK: Computed

    /// Highest severity present; determines border color.
    private var borderColor: Color {
        messages.contains(where: { $0.severity == .critical })
            ? colorCrit
            : colorWarn
    }

    // MARK: Body

    var body: some View {
        if messages.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                header
                Rectangle().fill(borderColor.opacity(0.5)).frame(height: 1)
                logLines
            }
            .background(shellSurface)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(borderColor)
                    .frame(width: 2)
            }
            .clipShape(Rectangle())
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(textTertiary)
            Text("./validate --strict")
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .foregroundStyle(accentRust)

            Spacer()

            // Summary badge
            Text("\(messages.count) issue\(messages.count == 1 ? "" : "s")")
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(borderColor)
                .padding(.trailing, 16)
        }
        .padding(.leading, 16)
        .frame(height: 36)
    }

    // MARK: Log Lines

    private var logLines: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(messages) { msg in
                logRow(msg)
                if msg.id != messages.last?.id {
                    Rectangle()
                        .fill(shellBorder)
                        .frame(height: 1)
                        .padding(.leading, 16)
                }
            }
        }
        .padding(.bottom, 4)
    }

    private func logRow(_ msg: ValidationMessage) -> some View {
        let tagColor: Color = msg.severity == .critical ? colorCrit : colorWarn

        return HStack(alignment: .top, spacing: 8) {
            Text(msg.prefix)
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .foregroundStyle(tagColor)
                .frame(width: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(msg.field.uppercased())
                    .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                    .tracking(0.04)
                    .foregroundStyle(tagColor.opacity(0.8))

                Text(msg.message)
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

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
        .padding(16)
        .frame(width: 700)
        .background(Color(hex: "#0F1115"))
}

#Preview("Empty — no render") {
    SystemLogBlock(messages: [])
        .frame(width: 700, height: 100)
        .background(Color(hex: "#0F1115"))
}
