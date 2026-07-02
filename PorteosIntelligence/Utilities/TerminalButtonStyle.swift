import SwiftUI

// MARK: - TerminalButtonStyle
//
// V2.06: zero radius, JetBrains Mono, bracket triggers.
// Supports solid palette fills and semantic ribbon variants (approve/watchlist/reject).

struct TerminalButtonStyle: ButtonStyle {

    enum Palette {
        case green, red, amber, rust, teal, blue, purple, muted

        var color: Color {
            switch self {
            case .green:  return DesignTokens.statusGo
            case .red:    return DesignTokens.statusCritical
            case .amber:  return DesignTokens.statusWarn
            case .rust:   return DesignTokens.accentRust
            case .teal:   return ProfileType.hospitality.accentColor
            case .blue:   return ProfileType.circular.accentColor
            case .purple: return ProfileType.design.accentColor
            case .muted:  return DesignTokens.dividerStructural
            }
        }

        var foreground: Color {
            self == .muted ? DesignTokens.textSecondary : DesignTokens.canvasBase
        }
    }

    enum Variant {
        case filled(Palette)
        case outlined(Palette)
        case semantic(TerminalSemanticAction)
    }

    let variant: Variant
    var fontSize: CGFloat = 11
    var height:   CGFloat = DesignTokens.rowHeightButton

    init(color: Palette, fontSize: CGFloat = 11, height: CGFloat = DesignTokens.rowHeightButton) {
        self.variant = .filled(color)
        self.fontSize = fontSize
        self.height = height
    }

    init(outlined color: Palette, fontSize: CGFloat = 11, height: CGFloat = DesignTokens.rowHeightButton) {
        self.variant = .outlined(color)
        self.fontSize = fontSize
        self.height = height
    }

    init(semantic: TerminalSemanticAction, fontSize: CGFloat = 11, height: CGFloat = DesignTokens.rowHeightButton) {
        self.variant = .semantic(semantic)
        self.fontSize = fontSize
        self.height = height
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.mono(size: fontSize, weight: .bold))
            .padding(.horizontal, 10)
            .frame(height: height)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.7 : 1.0))
            .overlay(borderOverlay)
            .clipShape(Rectangle())
            .contentShape(Rectangle())
    }

    private var foregroundColor: Color {
        switch variant {
        case .filled(let palette):   return palette.foreground
        case .outlined(let palette): return palette.color
        case .semantic(let action):  return action.accentColor
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .filled(let palette):   return palette.color
        case .outlined:              return Color.clear
        case .semantic(let action):  return action.accentColor.opacity(action.fillOpacity)
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch variant {
        case .filled:
            EmptyView()
        case .outlined(let palette):
            Rectangle().stroke(palette.color, lineWidth: 1)
        case .semantic(let action):
            Rectangle().stroke(action.accentColor, lineWidth: 1)
        }
    }
}
