import SwiftUI

// MARK: - DashboardHeroScore
// Figma handoff: 87 / 100 · DEAL NAME · PROFILE | grade box

struct DashboardHeroScore: View {

    let score: Double
    let grade: String
    let dealName: String
    let profile: ProfileType

    private var accent: Color { profile.accentColor }

    private var gradeColor: Color {
        switch grade {
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
                .fill(accent)
                .frame(width: DesignTokens.profileBarHeight)

            HStack(alignment: .center, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.0f", score))
                        .font(DesignTokens.heroScoreFont())
                        .monospacedDigit()
                        .foregroundStyle(DesignTokens.textPrimary)

                    Text("/ 100")
                        .font(DesignTokens.metricValueFont())
                        .foregroundStyle(DesignTokens.textSecondary)
                }

                Text("\(dealName.uppercased()) · \(profile.heroProfileTag)")
                    .font(DesignTokens.metricLabelFont())
                    .tracking(0.04)
                    .foregroundStyle(DesignTokens.textDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 8)

                Text(grade)
                    .font(DesignTokens.heroGradeFont())
                    .foregroundStyle(gradeColor)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Rectangle().strokeBorder(DesignTokens.dividerStructural,
                                                 lineWidth: DesignTokens.dividerWidth)
                    }
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, DesignTokens.blockGutter)
            .frame(maxWidth: .infinity)
            .background(DesignTokens.surfacePanel)
        }
        .frame(minHeight: DesignTokens.heroCellMinHeight)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
    }
}

#Preview {
    DashboardHeroScore(score: 87, grade: "A", dealName: "Lisbon Office Block A", profile: .realEstate)
        .padding(DesignTokens.blockGutter)
        .frame(width: 660)
        .background(DesignTokens.canvasBase)
}
