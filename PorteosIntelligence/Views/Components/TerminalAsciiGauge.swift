import SwiftUI

// MARK: - TerminalAsciiGauge
// V2.06 hybrid: ASCII block bar for static threshold metrics (LTV, DSCR, etc.)

struct TerminalAsciiGauge: View {

    /// Value in 0...1 range (clamped).
    let fillRatio: Double
    var totalBlocks: Int = 12
    var filledChar: Character = "█"
    var emptyChar: Character = "░"
    var state: MetricState = .neutral

    private var clampedRatio: Double { min(1, max(0, fillRatio)) }

    private var filledCount: Int {
        Int((clampedRatio * Double(totalBlocks)).rounded())
    }

    private var barString: String {
        let filled = String(repeating: String(filledChar), count: filledCount)
        let empty  = String(repeating: String(emptyChar),  count: totalBlocks - filledCount)
        return "[\(filled)\(empty)]"
    }

    var body: some View {
        Text(barString)
            .font(DesignTokens.mono(size: 11, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(state.semanticColor)
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        TerminalAsciiGauge(fillRatio: 0.72, state: .optimal)
        TerminalAsciiGauge(fillRatio: 0.45, state: .warning)
        TerminalAsciiGauge(fillRatio: 0.18, state: .danger)
    }
    .padding()
    .background(DesignTokens.canvasBase)
}
