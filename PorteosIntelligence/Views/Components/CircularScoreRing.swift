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

    private let shellBorder   = Color(hex: "#2E333F")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textTertiary  = Color(hex: "#64748B")

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
                    .font(.custom("JetBrains Mono", size: numberSize).weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(textPrimary)

                Text(label.uppercased())
                    .font(.custom("JetBrains Mono", size: 11))
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
        CircularScoreRing(score: 87, accentColor: Color(hex: "#C25E30"), size: 120, label: "PORTEOS")
        CircularScoreRing(score: 63, accentColor: Color(hex: "#14B8A6"), size: 120, label: "PORTEOS")
        CircularScoreRing(score: 42, accentColor: Color(hex: "#A855F7"), size: 120, label: "PORTEOS")
        CircularScoreRing(score: 91, accentColor: Color(hex: "#3B82F6"), size: 180, label: "PORTEOS")
    }
    .padding(32)
    .background(Color(hex: "#0F1115"))
}
