import SwiftUI

// MARK: - TerminalButtonStyle
//
// Reusable ButtonStyle that enforces the terminal aesthetic across the app:
// - Zero border radius
// - JetBrains Mono label
// - Solid background using the provided accent color
// - #0F1115 foreground text (always dark on the colored background)
// - Slight opacity press feedback

struct TerminalButtonStyle: ButtonStyle {

    enum Palette {
        case green, red, amber, rust, teal, blue, purple, muted

        var color: Color {
            switch self {
            case .green:  return Color(hex: "#10B981")
            case .red:    return Color(hex: "#EF4444")
            case .amber:  return Color(hex: "#F59E0B")
            case .rust:   return Color(hex: "#C25E30")
            case .teal:   return Color(hex: "#14B8A6")
            case .blue:   return Color(hex: "#3B82F6")
            case .purple: return Color(hex: "#A855F7")
            case .muted:  return Color(hex: "#2E333F")
            }
        }

        var foreground: Color {
            // muted uses a lighter text; all others use shell-bg for contrast
            self == .muted ? Color(hex: "#94A3B8") : Color(hex: "#0F1115")
        }
    }

    let color:    Palette
    var fontSize: CGFloat = 11
    var height:   CGFloat = 32

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("JetBrains Mono", size: fontSize).weight(.bold))
            .foregroundStyle(color.foreground)
            .padding(.horizontal, 10)
            .frame(height: height)
            .background(color.color.opacity(configuration.isPressed ? 0.7 : 1.0))
            .clipShape(Rectangle())
            .contentShape(Rectangle())
    }
}
