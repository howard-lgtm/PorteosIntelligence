import SwiftUI

// MARK: - HospitalitySensitivityBlock
// Figma 06 // SENSITIVITY_ANALYSIS — read-only stress bars.

struct HospitalitySensitivityBlock: View {

    let deal: PropertyDeal

    private var accent: Color { ProfileType.hospitality.accentColor }

    private func inputs(adr: Double = 0, occ: Double = 0, opex: Double = 0) -> HospitalityCalculator.FullInputs {
        HospitalityCalculator.FullInputs(
            roomCount:           deal.hospitalityRoomCount,
            adr:                 max(0, deal.hospitalityADR + adr),
            occupancyRate:       min(100, max(0, deal.hospitalityOccupancyRate + occ)),
            fbRevenue:           deal.hospitalityFBRevenue,
            spaRevenue:          deal.hospitalitySpaRevenue,
            meetingRevenue:      deal.hospitalityMeetingRevenue,
            otherRevenue:        deal.hospitalityOtherRevenue,
            opExRatio:           min(100, max(0, deal.hospitalityOpExRatio + opex)),
            directBookingPct:    deal.hospitalityDirectBookingPct,
            otaBookingPct:       deal.hospitalityOTABookingPct,
            distributionCost:    deal.hospitalityDistributionCost
        )
    }

    private var base: HospitalityCalculator.FullMetrics {
        HospitalityCalculator.calculateFull(inputs: inputs())
    }

    private struct Row { let label: String; let delta: Double; let suffix: String }

    private var rows: [Row] {
        let b = base
        let adr  = HospitalityCalculator.calculateFull(inputs: inputs(adr: -10))
        let occ  = HospitalityCalculator.calculateFull(inputs: inputs(occ: -5))
        let opex = HospitalityCalculator.calculateFull(inputs: inputs(opex: 5))
        return [
            Row(label: "ADR ±€10", delta: adr.revPAR - b.revPAR, suffix: "RevPAR"),
            Row(label: "Occupancy −5%", delta: occ.gop - b.gop, suffix: "GOP"),
            Row(label: "OpEx Ratio +5pp", delta: opex.gop - b.gop, suffix: "GOP"),
        ]
    }

    var body: some View {
        sensitivityBlock(rows: rows)
    }

    private func sensitivityBlock(rows: [Row]) -> some View {
        let maxMag = max(rows.map { abs($0.delta) }.max() ?? 1, 1)
        return TerminalBlock(command: "06 // SENSITIVITY_ANALYSIS", accentColor: accent, contentPadding: 0) {
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
        let absV = abs(delta)
        let val: String
        if absV >= 1_000 { val = "€\(String(format: "%.0fK", absV / 1_000))" }
        else { val = absV.formatted(.currency(code: "EUR").precision(.fractionLength(0))) }
        return "\(sign)\(val) \(suffix)"
    }
}
