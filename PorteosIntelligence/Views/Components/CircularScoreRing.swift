import SwiftUI

// MARK: - CircularScoreRing
// Circular progress ring for aggregate scores (0–100).
// Track: shell-border 4pt stroke.
// Fill:  accentColor 4pt stroke, trimmed clockwise from top.
// Center: score number + label.

struct CircularScoreRing: View {

    let score: Double          // 0–100
    let accentColor: Color
    var size: CGFloat = 120
    var label: String = "SCORE"

    // MARK: Tokens

    private let shellBorder   = DesignTokens.dividerStructural
    private let textPrimary   = DesignTokens.textPrimary
    private let textTertiary  = DesignTokens.textDim

    // MARK: Derived

    private var clampedFraction: Double { max(0, min(1, score / 100)) }
    private var numberSize: CGFloat { size >= 180 ? 48 : 24 }
    private let strokeWidth: CGFloat = 4

    // MARK: Body

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(shellBorder, lineWidth: strokeWidth)

            // Fill arc — starts at top (−90°), goes clockwise
            Circle()
                .trim(from: 0, to: clampedFraction)
                .stroke(
                    accentColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: score)

            // Center content
            VStack(spacing: 2) {
                Text(String(format: "%.0f", score))
                    .font(DesignTokens.mono(size: numberSize, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(textPrimary)

                Text(label.uppercased())
                    .font(DesignTokens.rowLabelFont())
                    .tracking(0.08)
                    .foregroundStyle(textTertiary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 32) {
        CircularScoreRing(score: 87, accentColor: DesignTokens.accentRust, size: 120, label: "PORTEOS")
        CircularScoreRing(score: 63, accentColor: DesignTokens.accentHospitality, size: 120, label: "PORTEOS")
        CircularScoreRing(score: 42, accentColor: DesignTokens.accentDesign, size: 120, label: "PORTEOS")
        CircularScoreRing(score: 91, accentColor: DesignTokens.accentCircular, size: 180, label: "PORTEOS")
    }
    .padding(32)
    .background(DesignTokens.canvasBase)
}
