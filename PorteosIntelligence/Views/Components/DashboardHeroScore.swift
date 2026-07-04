import SwiftUI

// MARK: - DashboardHeroScore
// Figma img_00_1 — score row + deal name stacked; grade box right.

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
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.0f", score))
                            .porteosScoreHero()
                            .monospacedDigit()
                            .foregroundStyle(DesignTokens.textPrimary)

                        Text("/ 100")
                            .porteosMetricValue()
                            .foregroundStyle(DesignTokens.textSecondary)
                    }

                    Text(dealName.uppercased())
                        .porteosMetricLabel()
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 8)

                Text(grade)
                    .porteosScoreGrade()
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
