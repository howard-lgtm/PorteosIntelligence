import SwiftUI

// MARK: - PorteosScoreBlock
// V2.06 hero score strip — Figma porteos-score-block with accent strip + bordered panel.

struct PorteosScoreBlock: View {

    let metrics: PorteosScoreCalculator.PorteosMetrics
    var accentColor: Color = DesignTokens.accentRust

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
        HStack(spacing: 0) {
            Rectangle()
                .fill(accentColor)
                .frame(width: DesignTokens.profileBarHeight)

            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(String(format: "%.0f", metrics.finalScore))
                    .porteosScoreHero()
                    .monospacedDigit()
                    .foregroundStyle(gradeColor)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("PORTEOS SCORE")
                        .porteosMetricLabel()
                        .foregroundStyle(DesignTokens.textDim)

                    Text(metrics.scoreGrade)
                        .porteosScoreGrade()
                        .foregroundStyle(gradeColor)
                }
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, DesignTokens.blockGutter)
            .frame(maxWidth: .infinity)
            .background(DesignTokens.surfacePanel)
        }
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.top, DesignTokens.blockGutter)
    }
}

#Preview {
    VStack(spacing: 0) {
        PorteosScoreBlock(metrics: .init(finalScore: 87, scoreGrade: "A"))
        PorteosScoreBlock(metrics: .init(finalScore: 41, scoreGrade: "F"))
    }
    .frame(width: 660)
    .background(DesignTokens.canvasBase)
}
