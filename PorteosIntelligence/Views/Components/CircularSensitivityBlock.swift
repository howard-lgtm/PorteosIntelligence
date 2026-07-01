import SwiftUI

// MARK: - CircularSensitivityBlock
//
// A read-only simulation block. It NEVER mutates the PropertyDeal.
// Adjustments flow into CircularEconomyCalculator.calculateFull() so MCI and
// carbon intensity are derived by the same logic used in the live dashboard.

struct CircularSensitivityBlock: View {

    let deal: PropertyDeal

    // ── Adjustment State (simulation-only, never saved) ───────────────────────
    @State private var recycledContentAdj:  Double = 0   // pp   (−20…+50)
    @State private var renewableContentAdj: Double = 0   // pp   (−10…+30)
    @State private var wasteReductionAdj:   Double = 0   // kg   (−1000…+1000)
    // Positive wasteReductionAdj = less waste disposed (better MCI & carbon)

    // ── Design tokens ─────────────────────────────────────────────────────────

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentBlue    = Color(hex: "#3B82F6")
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

    private var baseMetrics: CircularEconomyCalculator.FullMetrics {
        CircularEconomyCalculator.calculateFull(inputs: buildInputs(
            recycled: 0, renewable: 0, wasteReduction: 0
        ))
    }

    private var simMetrics: CircularEconomyCalculator.FullMetrics {
        CircularEconomyCalculator.calculateFull(inputs: buildInputs(
            recycled:      recycledContentAdj,
            renewable:     renewableContentAdj,
            wasteReduction: wasteReductionAdj
        ))
    }

    private func buildInputs(recycled: Double, renewable: Double, wasteReduction: Double) -> CircularEconomyCalculator.FullInputs {
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

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TerminalBlock(command: "04 // SENSITIVITY_SIMULATION",
                          accentColor: accentBlue,
                          contentPadding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    adjustmentSection
                    Rectangle().fill(shellBorder).frame(height: 1)
                    resultsSection
                }
            }

            ScenarioManagerBlock(
                deal:               deal,
                profile:            "circular",
                accentColor:        accentBlue,
                moduleLabel:        "05 // SAVED_SCENARIOS",
                currentAdjustments: [
                    "recycledContentAdj":  recycledContentAdj,
                    "renewableContentAdj": renewableContentAdj,
                    "wasteReductionAdj":   wasteReductionAdj,
                ],
                onLoad: { dict in
                    recycledContentAdj  = dict["recycledContentAdj"]  ?? 0
                    renewableContentAdj = dict["renewableContentAdj"] ?? 0
                    wasteReductionAdj   = dict["wasteReductionAdj"]   ?? 0
                }
            )
        }
    }

    // MARK: – Adjustment Section

    private var adjustmentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("ADJUST INPUTS")

            stepperRow(
                label:        "RECYCLED CONTENT",
                display:      signedPct(recycledContentAdj, dp: 1),
                canDecrement: recycledContentAdj > -20,
                canIncrement: recycledContentAdj <  50
            ) {
                recycledContentAdj = max(-20, recycledContentAdj - 5)
            } onIncrement: {
                recycledContentAdj = min(50, recycledContentAdj + 5)
            }

            stepperRow(
                label:        "RENEWABLE CONTENT",
                display:      signedPct(renewableContentAdj, dp: 1),
                canDecrement: renewableContentAdj > -10,
                canIncrement: renewableContentAdj <  30
            ) {
                renewableContentAdj = max(-10, renewableContentAdj - 5)
            } onIncrement: {
                renewableContentAdj = min(30, renewableContentAdj + 5)
            }

            stepperRow(
                label:        "WASTE REDUCTION",
                display:      signedKg(wasteReductionAdj),
                canDecrement: wasteReductionAdj > -1000,
                canIncrement: wasteReductionAdj <  1000
            ) {
                wasteReductionAdj = max(-1000, wasteReductionAdj - 100)
            } onIncrement: {
                wasteReductionAdj = min(1000, wasteReductionAdj + 100)
            }

            HStack {
                Spacer()
                Button {
                    recycledContentAdj  = 0
                    renewableContentAdj = 0
                    wasteReductionAdj   = 0
                } label: {
                    Text("[ RESET ]")
                        .font(.custom("JetBrains Mono", size: 13))
                        .foregroundStyle(textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(recycledContentAdj == 0 && renewableContentAdj == 0 && wasteReductionAdj == 0)
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

            // MCI: higher is better (more circular)
            resultRow(
                label:        "MCI SCORE",
                base:         mci(baseMetrics.mciScore),
                sim:          mci(simMetrics.mciScore),
                delta:        simMetrics.mciScore - baseMetrics.mciScore,
                format:       { signedMci($0) },
                higherBetter: true
            )

            // Carbon intensity: lower is better
            resultRow(
                label:        "CARBON INTENSITY",
                base:         ci(baseMetrics.carbonIntensity),
                sim:          ci(simMetrics.carbonIntensity),
                delta:        simMetrics.carbonIntensity - baseMetrics.carbonIntensity,
                format:       { signedCi($0) },
                higherBetter: false
            )

            // Overall CE score: higher is better
            resultRow(
                label:        "CE SCORE",
                base:         pct(baseMetrics.overallCEScore, dp: 1),
                sim:          pct(simMetrics.overallCEScore, dp: 1),
                delta:        simMetrics.overallCEScore - baseMetrics.overallCEScore,
                format:       { signedPct($0, dp: 1) },
                higherBetter: true
            )

            // Recovery rate: higher is better
            resultRow(
                label:        "RECOVERY RATE",
                base:         pct(baseMetrics.recoveryRate, dp: 1),
                sim:          pct(simMetrics.recoveryRate, dp: 1),
                delta:        simMetrics.recoveryRate - baseMetrics.recoveryRate,
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
        let neutral    = abs(delta) < 0.0001
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

    private func pct(_ v: Double, dp: Int = 1) -> String {
        "\(v.formatted(.number.precision(.fractionLength(dp))))%"
    }

    private func signedPct(_ v: Double, dp: Int = 1) -> String {
        let s = abs(v).formatted(.number.precision(.fractionLength(dp)))
        if v > 0 { return "+\(s)%" }
        if v < 0 { return "−\(s)%" }
        return "0\(dp > 0 ? ".\(String(repeating: "0", count: dp))" : "")%"
    }

    private func mci(_ v: Double) -> String { String(format: "%.3f", v) }

    private func signedMci(_ v: Double) -> String {
        let s = String(format: "%.3f", abs(v))
        if v > 0 { return "+\(s)" }
        if v < 0 { return "−\(s)" }
        return "0.000"
    }

    private func ci(_ v: Double) -> String { String(format: "%.3f t/m²", v) }

    private func signedCi(_ v: Double) -> String {
        let s = String(format: "%.3f", abs(v))
        if v > 0 { return "+\(s)" }
        if v < 0 { return "−\(s)" }
        return "0.000"
    }

    private func signedKg(_ v: Double) -> String {
        let abs = Int(Swift.abs(v))
        if v > 0 { return "+\(abs)kg" }
        if v < 0 { return "−\(abs)kg" }
        return "0kg"
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
        propertyName:                  "Lisbon Campus",
        circularCO2Embodied:           85_000,
        circularKgMaterialsUsed:       50_000,
        circularKgMaterialsReturned:   20_000,
        circularKgMaterialsDisposed:   8_000,
        circularRecycledContentPct:    35,
        circularRenewableContentPct:   20,
        circularWasteGenerated:        12_000,
        circularOperationalCarbon:     4.5,
        circularBuildingAreaM2:        1_800
    )
    ScrollView {
        CircularSensitivityBlock(deal: deal)
            .padding(16)
    }
    .frame(width: 700, height: 600)
    .background(Color(hex: "#0F1115"))
}
