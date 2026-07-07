import SwiftUI

// MARK: - TerminalButton
// Primary filled and secondary ./action variants using DesignTokens.

struct TerminalButton: View {

    enum Variant { case primary, secondary }

    let title: String
    let variant: Variant
    var accentColor: Color = DesignTokens.accentRust
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            switch variant {
            case .primary:
                Text("[ \(title.uppercased()) ]")
                    .porteosButtonPrimary()
                    .foregroundStyle(DesignTokens.canvasBase)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.rowHeightData)
                    .background(accentColor)
                    .clipShape(Rectangle())

            case .secondary:
                Text("./\(title.lowercased())")
                    .porteosRowLabel()
                    .foregroundStyle(DesignTokens.statusGo)
                    .padding(.horizontal, 12)
                    .frame(height: DesignTokens.rowHeightData)
                    .clipShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        TerminalButton(title: "Generate Report", variant: .primary, accentColor: ProfileType.realEstate.accentColor) {}
        TerminalButton(title: "Generate Report", variant: .primary, accentColor: ProfileType.hospitality.accentColor) {}
        TerminalButton(title: "new_deal", variant: .secondary) {}
    }
    .padding(DesignTokens.blockGutter)
    .frame(width: 400)
    .background(DesignTokens.canvasBase)
}
