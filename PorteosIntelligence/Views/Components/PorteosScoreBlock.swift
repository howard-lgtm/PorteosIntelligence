import SwiftUI

struct PorteosScoreBlock: View {

    let metrics: PorteosScoreCalculator.PorteosMetrics

    // MARK: Tokens

    private let shellSurface = Color(hex: "#1A1D24")
    private let shellBorder  = Color(hex: "#2E333F")
    private let textTertiary = Color(hex: "#64748B")

    // MARK: Grade Color

    private var gradeColor: Color {
        switch metrics.scoreGrade {
        case "A": return Color(hex: "#10B981")  // Green
        case "B": return Color(hex: "#D4AF37")  // Gold
        case "C": return Color(hex: "#F8F9FA")  // White
        case "D": return Color(hex: "#F59E0B")  // Amber
        default:  return Color(hex: "#EF4444")  // Red  ("F")
        }
    }

    // MARK: Body

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            scoreDisplay
            Spacer()
            gradeDisplay
        }
        .padding(16)
        .background(shellSurface)
        .overlay(
            Rectangle()
                .strokeBorder(shellBorder, lineWidth: 1)
        )
        .cornerRadius(0)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: Score (left)

    private var scoreDisplay: some View {
        Text(String(format: "%.0f", metrics.finalScore))
            .font(.custom("JetBrains Mono", size: 48).weight(.bold))
            .monospacedDigit()
            .foregroundStyle(gradeColor)
    }

    // MARK: Grade + Label (right)

    private var gradeDisplay: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("PORTEOS SCORE")
                .font(.custom("Inter", size: 11).weight(.bold))
                .tracking(0.05)
                .foregroundStyle(textTertiary)

            Text(metrics.scoreGrade)
                .font(.custom("JetBrains Mono", size: 24).weight(.bold))
                .foregroundStyle(gradeColor)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        PorteosScoreBlock(metrics: .init(finalScore: 87, scoreGrade: "A"))
        PorteosScoreBlock(metrics: .init(finalScore: 63, scoreGrade: "B"))
        PorteosScoreBlock(metrics: .init(finalScore: 44, scoreGrade: "C"))
        PorteosScoreBlock(metrics: .init(finalScore: 22, scoreGrade: "D"))
        PorteosScoreBlock(metrics: .init(finalScore:  8, scoreGrade: "F"))
    }
    .frame(width: 480)
    .background(Color(hex: "#0F1115"))
}
