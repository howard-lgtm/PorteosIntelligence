import SwiftUI

// MARK: - TerminalSensitivityStyles
// Shared tokens and helpers for profile sensitivity simulation blocks.

enum TerminalSensitivityStyles {

    static let colLabel: CGFloat = 168
    static let colBase:  CGFloat = 110
    static let colSim:   CGFloat = 110

    static func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DesignTokens.sectionLabelFont())
            .tracking(0.04)
            .foregroundStyle(DesignTokens.textDim)
            .padding(.leading, DesignTokens.blockGutter)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    static func deltaColor(delta: Double, higherBetter: Bool) -> Color {
        let positive = delta > 0
        let neutral  = abs(delta) < 0.001
        let good     = higherBetter ? positive : !positive
        if neutral { return DesignTokens.textDim }
        return good ? DesignTokens.statusGo : DesignTokens.statusCritical
    }

    static func adjColor(_ display: String) -> Color {
        if display.hasPrefix("+") { return DesignTokens.statusGo }
        if display.hasPrefix("−") { return DesignTokens.statusCritical }
        return DesignTokens.textPrimary
    }
}
