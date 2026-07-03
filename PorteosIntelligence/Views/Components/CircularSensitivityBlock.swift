import SwiftUI

// MARK: - CircularSensitivityBlock
// Figma 06 // SENSITIVITY_ANALYSIS — read-only stress bars.

struct CircularSensitivityBlock: View {

    let deal: PropertyDeal

    private var accent: Color { ProfileType.circular.accentColor }

    private func inputs(recycled: Double = 0, renewable: Double = 0, wasteReduction: Double = 0) -> CircularEconomyCalculator.FullInputs {
        CircularEconomyCalculator.FullInputs(
            totalConstructionCost:  deal.circularTotalConstructionCost,
            repurposedMaterialCost: deal.circularRepurposedMaterialCost,
            co2Embodied:            deal.circularCO2Embodied,
            kgMaterialsUsed:        deal.circularKgMaterialsUsed,
            kgMaterialsReturned:    deal.circularKgMaterialsReturned,
            kgMaterialsDisposed:    max(0, deal.circularKgMaterialsDisposed - wasteReduction),
            recycledContentPct:     min(100, max(0, deal.circularRecycledContentPct + recycled)),
            renewableContentPct:    min(100, max(0, deal.circularRenewableContentPct + renewable)),
            wasteGenerated:         max(0, deal.circularWasteGenerated - wasteReduction),
            operationalCarbon:      deal.circularOperationalCarbon,
            buildingAreaM2:         deal.circularBuildingAreaM2,
            waterRecyclingRate:     deal.circularWaterRecyclingRate
        )
    }

    private var base: CircularEconomyCalculator.FullMetrics {
        CircularEconomyCalculator.calculateFull(inputs: inputs())
    }

    private struct Row { let label: String; let delta: Double; let suffix: String }

    private var rows: [Row] {
        let b = base
        let rec = CircularEconomyCalculator.calculateFull(inputs: inputs(recycled: -10))
        let ren = CircularEconomyCalculator.calculateFull(inputs: inputs(renewable: -10))
        let wst = CircularEconomyCalculator.calculateFull(inputs: inputs(wasteReduction: -500))
        return [
            Row(label: "Recycled −10pp", delta: rec.mciScore - b.mciScore, suffix: "MCI"),
            Row(label: "Renewable −10pp", delta: ren.carbonIntensity - b.carbonIntensity, suffix: "CO₂/m²"),
            Row(label: "Waste +500kg", delta: wst.mciScore - b.mciScore, suffix: "MCI"),
        ]
    }

    var body: some View {
        let maxMag = max(rows.map { abs($0.delta) }.max() ?? 1, 0.001)
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
        if suffix == "CO₂/m²" {
            return "\(sign)\(String(format: "%.3f", abs(delta))) \(suffix)"
        }
        return "\(sign)\(String(format: "%.2f", abs(delta))) \(suffix)"
    }
}
