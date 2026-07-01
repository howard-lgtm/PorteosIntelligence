import SwiftUI

// MARK: - HospitalitySensitivityBlock
//
// A read-only simulation block. It NEVER mutates the PropertyDeal.
// All adjustments live in local @State and are fed to a local copy of
// HospitalityCalculator.FullInputs. Ancillary revenues (F&B, Spa, etc.)
// are held constant — only room-level ADR, occupancy, and opex ratio move.

struct HospitalitySensitivityBlock: View {

    let deal: PropertyDeal

    // ── Adjustment State (simulation-only, never saved) ───────────────────────
    @State private var adrAdj:        Double = 0   // € absolute  (−50…+50)
    @State private var occupancyAdj:  Double = 0   // pp          (−15…+15)
    @State private var opexRatioAdj:  Double = 0   // pp          (−10…+10)

    // ── Design tokens ─────────────────────────────────────────────────────────

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentTeal    = Color(hex: "#14B8A6")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")
    private let colorGreen    = Color(hex: "#10B981")
    private let colorRed      = Color(hex: "#EF4444")

    // ── Column widths ─────────────────────────────────────────────────────────

    private let colLabel: CGFloat = 168
    private let colBase:  CGFloat = 110
    private let colSim:   CGFloat = 110

    // MARK: Computed Metrics

    private var baseMetrics: HospitalityCalculator.FullMetrics {
        HospitalityCalculator.calculateFull(inputs: buildInputs(adr: 0, occ: 0, opex: 0))
    }

    private var simMetrics: HospitalityCalculator.FullMetrics {
        HospitalityCalculator.calculateFull(inputs: buildInputs(
            adr:  adrAdj,
            occ:  occupancyAdj,
            opex: opexRatioAdj
        ))
    }

    private func buildInputs(adr: Double, occ: Double, opex: Double) -> HospitalityCalculator.FullInputs {
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

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TerminalBlock(command: "04 // SENSITIVITY_SIMULATION",
                          accentColor: accentTeal,
                          contentPadding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    adjustmentSection
                    Rectangle().fill(shellBorder).frame(height: 1)
                    resultsSection
                }
            }

            ScenarioManagerBlock(
                deal:               deal,
                profile:            "hospitality",
                accentColor:        accentTeal,
                moduleLabel:        "05 // SAVED_SCENARIOS",
                currentAdjustments: [
                    "adrAdj":       adrAdj,
                    "occupancyAdj": occupancyAdj,
                    "opexRatioAdj": opexRatioAdj,
                ],
                onLoad: { dict in
                    adrAdj       = dict["adrAdj"]       ?? 0
                    occupancyAdj = dict["occupancyAdj"] ?? 0
                    opexRatioAdj = dict["opexRatioAdj"] ?? 0
                }
            )
        }
    }

    // MARK: – Adjustment Section

    private var adjustmentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("ADJUST INPUTS")

            stepperRow(
                label:        "ADR ADJUSTMENT",
                display:      signedEur(adrAdj),
                canDecrement: adrAdj > -50,
                canIncrement: adrAdj <  50
            ) {
                adrAdj = max(-50, adrAdj - 5)
            } onIncrement: {
                adrAdj = min(50, adrAdj + 5)
            }

            stepperRow(
                label:        "OCCUPANCY RATE",
                display:      signedPct(occupancyAdj, dp: 1),
                canDecrement: occupancyAdj > -15,
                canIncrement: occupancyAdj <  15
            ) {
                occupancyAdj = max(-15, occupancyAdj - 1.0)
            } onIncrement: {
                occupancyAdj = min(15, occupancyAdj + 1.0)
            }

            stepperRow(
                label:        "OPEX RATIO",
                display:      signedPct(opexRatioAdj, dp: 1),
                canDecrement: opexRatioAdj > -10,
                canIncrement: opexRatioAdj <  10
            ) {
                opexRatioAdj = max(-10, opexRatioAdj - 1.0)
            } onIncrement: {
                opexRatioAdj = min(10, opexRatioAdj + 1.0)
            }

            HStack {
                Spacer()
                Button {
                    adrAdj       = 0
                    occupancyAdj = 0
                    opexRatioAdj = 0
                } label: {
                    Text("[ RESET ]")
                        .font(.custom("JetBrains Mono", size: 13))
                        .foregroundStyle(textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(adrAdj == 0 && occupancyAdj == 0 && opexRatioAdj == 0)
                .padding(.trailing, 16)
                .padding(.bottom, 10)
            }
        }
    }

    private func stepperRow(
        label: String,
        display: String,
        canDecrement: Bool,
        canIncrement: Bool,
        onDecrement: @escaping () -> Void,
        onIncrement:  @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.custom("JetBrains Mono", size: 13).weight(.medium))
                .tracking(0.02)
                .foregroundStyle(textTertiary)
                .frame(width: colLabel, alignment: .leading)
                .padding(.leading, 16)

            Spacer()

            Button { onDecrement() } label: {
                Text("[ − ]")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(canDecrement ? textSecondary : textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(!canDecrement)

            Text(display)
                .font(.custom("JetBrains Mono", size: 17).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(adjColor(display))
                .frame(width: 76, alignment: .center)

            Button { onIncrement() } label: {
                Text("[ + ]")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(canIncrement ? textSecondary : textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(!canIncrement)
            .padding(.trailing, 16)
        }
        .frame(height: 40)
    }

    // MARK: – Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("SIMULATION RESULTS")

            // Column headers
            HStack(spacing: 0) {
                Text("METRIC")
                    .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                    .tracking(0.06)
                    .foregroundStyle(textTertiary)
                    .frame(width: colLabel, alignment: .leading)
                    .padding(.leading, 16)

                Text("BASE")
                    .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                    .tracking(0.06)
                    .foregroundStyle(textTertiary)
                    .frame(width: colBase, alignment: .trailing)

                Text("SIMULATED")
                    .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                    .tracking(0.06)
                    .foregroundStyle(textTertiary)
                    .frame(width: colSim, alignment: .trailing)

                Text("DELTA")
                    .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                    .tracking(0.06)
                    .foregroundStyle(textTertiary)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
            }
            .frame(height: 28)

            Rectangle().fill(shellBorder).frame(height: 1)

            resultRow(
                label:        "RevPAR",
                base:         eur(baseMetrics.revPAR),
                sim:          eur(simMetrics.revPAR),
                delta:        simMetrics.revPAR - baseMetrics.revPAR,
                format:       { signedEur($0) },
                higherBetter: true
            )

            resultRow(
                label:        "TOTAL REVENUE",
                base:         eur(baseMetrics.totalRevenue),
                sim:          eur(simMetrics.totalRevenue),
                delta:        simMetrics.totalRevenue - baseMetrics.totalRevenue,
                format:       { signedEur($0) },
                higherBetter: true
            )

            resultRow(
                label:        "GOP",
                base:         eur(baseMetrics.gop),
                sim:          eur(simMetrics.gop),
                delta:        simMetrics.gop - baseMetrics.gop,
                format:       { signedEur($0) },
                higherBetter: true
            )

            resultRow(
                label:        "EBITDA MARGIN",
                base:         pct(baseMetrics.ebitdaMargin, dp: 1),
                sim:          pct(simMetrics.ebitdaMargin, dp: 1),
                delta:        simMetrics.ebitdaMargin - baseMetrics.ebitdaMargin,
                format:       { signedPct($0, dp: 1) },
                higherBetter: true
            )

            Rectangle().fill(Color.clear).frame(height: 10)
        }
    }

    private func resultRow(
        label: String,
        base: String,
        sim: String,
        delta: Double,
        format: (Double) -> String,
        higherBetter: Bool
    ) -> some View {
        let positive   = delta > 0
        let neutral    = abs(delta) < 0.001
        let good       = higherBetter ? positive : !positive
        let deltaColor: Color = neutral ? textTertiary : (good ? colorGreen : colorRed)
        let indicator  = neutral ? "  " : (positive ? "▲" : "▼")

        return HStack(spacing: 0) {
            Text(label)
                .font(.custom("JetBrains Mono", size: 13))
                .tracking(0.02)
                .foregroundStyle(textSecondary)
                .frame(width: colLabel, alignment: .leading)
                .padding(.leading, 16)

            Text(base)
                .font(.custom("JetBrains Mono", size: 13))
                .monospacedDigit()
                .foregroundStyle(textSecondary)
                .frame(width: colBase, alignment: .trailing)

            Text(sim)
                .font(.custom("JetBrains Mono", size: 17).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(neutral ? textPrimary : (good ? colorGreen : colorRed))
                .frame(width: colSim, alignment: .trailing)

            HStack(spacing: 4) {
                Text(indicator)
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(deltaColor)
                Text(neutral ? "—" : format(delta))
                    .font(.custom("JetBrains Mono", size: 13))
                    .monospacedDigit()
                    .foregroundStyle(deltaColor)
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)

            Spacer()
        }
        .frame(height: 40)
        .background(Color.clear)
        .overlay(alignment: .bottom) {
            Rectangle().fill(shellBorder.opacity(0.4)).frame(height: 1)
        }
    }

    // MARK: – Section Label

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("JetBrains Mono", size: 11).weight(.bold))
            .tracking(0.08)
            .foregroundStyle(textTertiary)
            .padding(.leading, 16)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    // MARK: – Formatters

    private func eur(_ v: Double) -> String {
        v.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }

    private func signedEur(_ v: Double) -> String {
        let absVal = abs(v)
        let s = absVal.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
        if v > 0 { return "+" + s }
        if v < 0 { return "−" + s }
        return s
    }

    private func pct(_ v: Double, dp: Int = 1) -> String {
        "\(v.formatted(.number.precision(.fractionLength(dp))))%"
    }

    private func signedPct(_ v: Double, dp: Int = 1) -> String {
        let s = abs(v).formatted(.number.precision(.fractionLength(dp)))
        if v > 0 { return "+\(s)%" }
        if v < 0 { return "−\(s)%" }
        return "0\(dp > 0 ? ".\(String(repeating: "0", count: dp))" : "")%"
    }

    private func adjColor(_ display: String) -> Color {
        if display.hasPrefix("+") { return colorGreen }
        if display.hasPrefix("−") { return colorRed   }
        return textPrimary
    }
}

// MARK: - Preview

#Preview {
    let deal = PropertyDeal(
        propertyName:                "Lisbon Boutique Hotel",
        hospitalityRoomCount:        80,
        hospitalityADR:              185,
        hospitalityOccupancyRate:    78,
        hospitalityFBRevenue:        620_000,
        hospitalitySpaRevenue:       140_000,
        hospitalityMeetingRevenue:   95_000,
        hospitalityOtherRevenue:     30_000,
        hospitalityOpExRatio:        58,
        hospitalityDirectBookingPct: 52,
        hospitalityOTABookingPct:    36,
        hospitalityDistributionCost: 180_000
    )
    ScrollView {
        HospitalitySensitivityBlock(deal: deal)
            .padding(16)
    }
    .frame(width: 700, height: 620)
    .background(Color(hex: "#0F1115"))
}
