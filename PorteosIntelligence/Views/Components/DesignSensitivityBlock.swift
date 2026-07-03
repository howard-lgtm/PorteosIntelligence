import SwiftUI

// MARK: - DesignSensitivityBlock
// Figma 06 // SENSITIVITY_ANALYSIS — read-only stress bars.

struct DesignSensitivityBlock: View {

    let deal: PropertyDeal

    private var accent: Color { ProfileType.design.accentColor }

    private func designScore(daylighting: Double, biophilic: Int, spaceUtil: Double) -> Double {
        let biophilicNorm = min(100.0, Double(max(0, biophilic)) * 10.0)
        return clamp(daylighting) * 0.30
             + clamp(biophilicNorm) * 0.25
             + clamp(spaceUtil) * 0.25
             + clamp(deal.designAdaptabilityScore) * 0.20
    }

    private func clamp(_ v: Double) -> Double { min(100, max(0, v)) }

    private struct Row { let label: String; let delta: Double; let suffix: String }

    private var rows: [Row] {
        let baseD = designScore(daylighting: deal.designDaylighting,
                                biophilic: deal.designBiophilicCount,
                                spaceUtil: deal.designSpaceUtilization)
        let dayD  = designScore(daylighting: deal.designDaylighting - 10,
                                biophilic: deal.designBiophilicCount,
                                spaceUtil: deal.designSpaceUtilization)
        let bioD  = designScore(daylighting: deal.designDaylighting,
                                biophilic: max(0, deal.designBiophilicCount - 2),
                                spaceUtil: deal.designSpaceUtilization)
        let spcD  = designScore(daylighting: deal.designDaylighting,
                                biophilic: deal.designBiophilicCount,
                                spaceUtil: deal.designSpaceUtilization - 10)
        return [
            Row(label: "Daylighting −10pp", delta: dayD - baseD, suffix: "Design"),
            Row(label: "Biophilic −2", delta: bioD - baseD, suffix: "Design"),
            Row(label: "Space Util −10pp", delta: spcD - baseD, suffix: "Design"),
        ]
    }

    var body: some View {
        let maxMag = max(rows.map { abs($0.delta) }.max() ?? 1, 1)
        TerminalBlock(command: "06 // SENSITIVITY_ANALYSIS", accentColor: accent, contentPadding: 0) {
            VStack(spacing: DesignTokens.gridRowSpacing) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    SensitivityImpactRow(
                        label: row.label,
                        fillRatio: abs(row.delta) / maxMag,
                        impactText: fmt(row.delta, suffix: row.suffix),
                        accent: accent,
                        impactColor: row.delta < 0 ? DesignTokens.statusWarn : DesignTokens.statusGo
                    )
                }
            }
            .padding(DesignTokens.blockGutter)
        }
    }

    private func fmt(_ delta: Double, suffix: String) -> String {
        let sign = delta >= 0 ? "+" : "−"
        return "\(sign)\(String(format: "%.1f", abs(delta))) \(suffix)"
    }
}
