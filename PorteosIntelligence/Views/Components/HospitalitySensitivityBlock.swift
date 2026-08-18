import SwiftUI

// MARK: - HospitalitySensitivityBlock
// Figma 06 // SENSITIVITY_ANALYSIS — stress testing with scaled deltas.
// P14-07: Shows upside + downside + combined stress, deltas scale to deal values,
// results expressed as % of base GOP.

struct HospitalitySensitivityBlock: View {

    let deal: PropertyDeal

    private var accent: Color { ProfileType.hospitality.accentColor }

    private func inputs(adrPct: Double = 0, occPct: Double = 0, opexPct: Double = 0) -> HospitalityCalculator.FullInputs {
        let scaledADR = deal.hospitalityADR * (1 + adrPct / 100)
        let scaledOcc = deal.hospitalityOccupancyRate * (1 + occPct / 100)
        let scaledOpEx = deal.hospitalityOpExRatio * (1 + opexPct / 100)
        
        return HospitalityCalculator.FullInputs(
            roomCount:           deal.hospitalityRoomCount,
            adr:                 max(0, scaledADR),
            occupancyRate:       min(100, max(0, scaledOcc)),
            fbRevenue:           deal.hospitalityFBRevenue,
            spaRevenue:          deal.hospitalitySpaRevenue,
            meetingRevenue:      deal.hospitalityMeetingRevenue,
            otherRevenue:        deal.hospitalityOtherRevenue,
            opExRatio:           min(100, max(0, scaledOpEx)),
            directBookingPct:    deal.hospitalityDirectBookingPct,
            otaBookingPct:       deal.hospitalityOTABookingPct,
            distributionCost:    deal.hospitalityDistributionCost
        )
    }

    private var base: HospitalityCalculator.FullMetrics {
        HospitalityCalculator.calculateFull(inputs: inputs())
    }

    private struct Row {
        let label: String
        let deltaPct: Double  // % of base GOP
        let suffix: String
    }

    private var rows: [Row] {
        let b = base
        guard b.gop > 0 else {
            return [
                Row(label: "Insufficient data", deltaPct: 0, suffix: "")
            ]
        }
        
        // Upside scenarios
        let adrUp  = HospitalityCalculator.calculateFull(inputs: inputs(adrPct: +10))
        let occUp  = HospitalityCalculator.calculateFull(inputs: inputs(occPct: +10))
        let opexDown = HospitalityCalculator.calculateFull(inputs: inputs(opexPct: -10))
        
        // Downside scenarios
        let adrDown = HospitalityCalculator.calculateFull(inputs: inputs(adrPct: -10))
        let occDown = HospitalityCalculator.calculateFull(inputs: inputs(occPct: -10))
        let opexUp  = HospitalityCalculator.calculateFull(inputs: inputs(opexPct: +10))
        
        // Combined stress (all three factors adverse)
        let stress  = HospitalityCalculator.calculateFull(inputs: inputs(adrPct: -10, occPct: -10, opexPct: +10))
        
        return [
            // Upside (favorable)
            Row(label: "ADR +10%",           deltaPct: ((adrUp.gop - b.gop) / b.gop) * 100,  suffix: "GOP"),
            Row(label: "Occupancy +10%",     deltaPct: ((occUp.gop - b.gop) / b.gop) * 100,  suffix: "GOP"),
            Row(label: "OpEx Ratio −10%",    deltaPct: ((opexDown.gop - b.gop) / b.gop) * 100, suffix: "GOP"),
            
            // Downside (adverse)
            Row(label: "ADR −10%",           deltaPct: ((adrDown.gop - b.gop) / b.gop) * 100, suffix: "GOP"),
            Row(label: "Occupancy −10%",     deltaPct: ((occDown.gop - b.gop) / b.gop) * 100, suffix: "GOP"),
            Row(label: "OpEx Ratio +10%",    deltaPct: ((opexUp.gop - b.gop) / b.gop) * 100,  suffix: "GOP"),
            
            // Combined stress
            Row(label: "Combined Stress",    deltaPct: ((stress.gop - b.gop) / b.gop) * 100,  suffix: "GOP"),
        ]
    }

    var body: some View {
        sensitivityBlock(rows: rows)
    }

    private func sensitivityBlock(rows: [Row]) -> some View {
        let maxMag = max(rows.map { abs($0.deltaPct) }.max() ?? 1, 1)
        return TerminalBlock(command: "06 // SENSITIVITY_ANALYSIS", accentColor: accent, contentPadding: 0) {
            VStack(spacing: DesignTokens.gridRowSpacing) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    SensitivityImpactRow(
                        label: row.label,
                        fillRatio: abs(row.deltaPct) / maxMag,
                        impactText: fmt(row.deltaPct, suffix: row.suffix),
                        accent: accent,
                        impactColor: row.deltaPct < 0 ? DesignTokens.statusWarn : DesignTokens.statusGo
                    )
                }
            }
            .padding(DesignTokens.blockGutter)
        }
    }

    private func fmt(_ deltaPct: Double, suffix: String) -> String {
        let sign = deltaPct >= 0 ? "+" : "−"
        let absV = abs(deltaPct)
        return "\(sign)\(String(format: "%.1f", absV))% \(suffix)"
    }
}
