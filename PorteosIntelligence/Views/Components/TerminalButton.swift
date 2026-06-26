import SwiftUI

// MARK: - TerminalButton
// Two variants matching the design system button spec:
//   .primary  — Solid accent-color background, black label, `[ TITLE ]` format.
//   .secondary — Transparent background, green label, `./title` format.

struct TerminalButton: View {

    // MARK: Variant

    enum Variant {
        case primary
        case secondary
    }

    // MARK: Parameters

    let title: String
    let variant: Variant
    var accentColor: Color = Color(hex: "#C25E30")   // Rust default; caller overrides per profile
    let action: () -> Void

    // MARK: Tokens

    private let shellBg      = Color(hex: "#0F1115")
    private let textOnAccent = Color(hex: "#0F1115")   // black text on colored bg
    private let accentGreen  = Color(hex: "#10B981")
    private let textSecondary = Color(hex: "#94A3B8")

    // MARK: Body

    var body: some View {
        Button(action: action) {
            switch variant {
            case .primary:
                Text("[ \(title.uppercased()) ]")
                    .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                    .foregroundStyle(textOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .background(accentColor)
                    .clipShape(Rectangle())

            case .secondary:
                Text("./\(title.lowercased())")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(accentGreen)
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .clipShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        TerminalButton(title: "Generate Report",  variant: .primary,    accentColor: Color(hex: "#C25E30")) {}
        TerminalButton(title: "Generate Report",  variant: .primary,    accentColor: Color(hex: "#14B8A6")) {}
        TerminalButton(title: "Generate Report",  variant: .primary,    accentColor: Color(hex: "#A855F7")) {}
        TerminalButton(title: "Generate Report",  variant: .primary,    accentColor: Color(hex: "#3B82F6")) {}
        TerminalButton(title: "new_deal",          variant: .secondary) {}
        TerminalButton(title: "import_deals",      variant: .secondary) {}
    }
    .padding(16)
    .frame(width: 400)
    .background(Color(hex: "#0F1115"))
}
