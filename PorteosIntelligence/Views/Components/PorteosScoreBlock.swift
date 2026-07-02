import SwiftUI

struct PorteosScoreBlock: View {

    let metrics: PorteosScoreCalculator.PorteosMetrics

    private var gradeColor: Color {
        switch metrics.scoreGrade {
        case "A": return DesignTokens.statusGo
        case "B": return DesignTokens.statusWarn
        case "C": return DesignTokens.textPrimary
        case "D": return DesignTokens.statusWarn
        default:  return DesignTokens.statusCritical
        }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(String(format: "%.0f", metrics.finalScore))
                .font(DesignTokens.heroScoreFont())
                .monospacedDigit()
                .foregroundStyle(gradeColor)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("PORTEOS SCORE")
                    .font(DesignTokens.metricLabelFont())
                    .tracking(0.02)
                    .foregroundStyle(DesignTokens.textDim)

                Text(metrics.scoreGrade)
                    .font(DesignTokens.heroGradeFont())
                    .foregroundStyle(gradeColor)
            }
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, DesignTokens.blockGutter)
        .background(DesignTokens.surfacePanel)
        .overlay(alignment: .bottom) {
            TerminalStructuralDivider()
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.top, DesignTokens.blockGutter)
    }
}

#Preview {
    VStack(spacing: 0) {
        PorteosScoreBlock(metrics: .init(finalScore: 87, scoreGrade: "A"))
        PorteosScoreBlock(metrics: .init(finalScore: 41, scoreGrade: "F"))
    }
    .frame(width: 720)
    .background(DesignTokens.canvasBase)
}
