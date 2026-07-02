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

    private var accent: Color { ProfileType.circular.accentColor }

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
                          accentColor: accent,
                          contentPadding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    adjustmentSection
                    TerminalStructuralDivider()
                    resultsSection
                }
            }

            ScenarioManagerBlock(
                deal:               deal,
                profile:            "circular",
                accentColor:        accent,
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
            TerminalSensitivityStyles.sectionLabel("ADJUST INPUTS")

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
                        .font(DesignTokens.mono(size: 13))
                        .foregroundStyle(DesignTokens.textDim)
                }
                .buttonStyle(.plain)
                .disabled(recycledContentAdj == 0 && renewableContentAdj == 0 && wasteReductionAdj == 0)
                .padding(.trailing, DesignTokens.blockGutter)
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
                .font(DesignTokens.mono(size: 13, weight: .medium))
                .tracking(0.02)
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: TerminalSensitivityStyles.colLabel, alignment: .leading)
                .padding(.leading, DesignTokens.blockGutter)

            Spacer()

            Button { onDecrement() } label: {
                Text("[ − ]")
                    .font(DesignTokens.mono(size: 13))
                    .foregroundStyle(canDecrement ? DesignTokens.textSecondary : DesignTokens.textDim)
            }
            .buttonStyle(.plain)
            .disabled(!canDecrement)

            Text(display)
                .font(DesignTokens.primaryMetricFont())
                .monospacedDigit()
                .foregroundStyle(TerminalSensitivityStyles.adjColor(display))
                .frame(width: 76, alignment: .center)

            Button { onIncrement() } label: {
                Text("[ + ]")
                    .font(DesignTokens.mono(size: 13))
                    .foregroundStyle(canIncrement ? DesignTokens.textSecondary : DesignTokens.textDim)
            }
            .buttonStyle(.plain)
            .disabled(!canIncrement)
            .padding(.trailing, DesignTokens.blockGutter)
        }
        .frame(height: DesignTokens.rowHeightHeader)
    }

    // MARK: – Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TerminalSensitivityStyles.sectionLabel("SIMULATION RESULTS")

            HStack(spacing: 0) {
                Text("METRIC")
                    .font(DesignTokens.mono(size: 11, weight: .bold))
                    .tracking(0.06)
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(width: TerminalSensitivityStyles.colLabel, alignment: .leading)
                    .padding(.leading, DesignTokens.blockGutter)
                Text("BASE")
                    .font(DesignTokens.mono(size: 11, weight: .bold))
                    .tracking(0.06)
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(width: TerminalSensitivityStyles.colBase, alignment: .trailing)
                Text("SIMULATED")
                    .font(DesignTokens.mono(size: 11, weight: .bold))
                    .tracking(0.06)
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(width: TerminalSensitivityStyles.colSim, alignment: .trailing)
                Text("DELTA")
                    .font(DesignTokens.mono(size: 11, weight: .bold))
                    .tracking(0.06)
                    .foregroundStyle(DesignTokens.textDim)
                    .padding(.leading, DesignTokens.blockGutter)
                    .padding(.trailing, DesignTokens.blockGutter)
            }
            .frame(height: 28)

            TerminalStructuralDivider()

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
        let deltaColor: Color = neutral ? DesignTokens.textDim : (good ? DesignTokens.statusGo : DesignTokens.statusCritical)
        let indicator  = neutral ? "  " : (positive ? "▲" : "▼")

        return HStack(spacing: 0) {
            Text(label)
                .font(DesignTokens.mono(size: 13))
                .tracking(0.02)
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: TerminalSensitivityStyles.colLabel, alignment: .leading)
                .padding(.leading, DesignTokens.blockGutter)

            Text(base)
                .font(DesignTokens.mono(size: 13))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: TerminalSensitivityStyles.colBase, alignment: .trailing)

            Text(sim)
                .font(DesignTokens.primaryMetricFont())
                .monospacedDigit()
                .foregroundStyle(neutral ? DesignTokens.textPrimary : (good ? DesignTokens.statusGo : DesignTokens.statusCritical))
                .frame(width: TerminalSensitivityStyles.colSim, alignment: .trailing)

            HStack(spacing: 4) {
                Text(indicator)
                    .font(DesignTokens.mono(size: 11))
                    .foregroundStyle(deltaColor)
                Text(neutral ? "—" : format(delta))
                    .font(DesignTokens.mono(size: 13))
                    .monospacedDigit()
                    .foregroundStyle(deltaColor)
            }
            .padding(.leading, DesignTokens.blockGutter)
            .padding(.trailing, DesignTokens.blockGutter)

            Spacer()
        }
        .frame(height: DesignTokens.rowHeightHeader)
        .background(Color.clear)
        .overlay(alignment: .bottom) {
            TerminalStructuralDivider().opacity(0.4)
        }
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
    .background(DesignTokens.canvasBase)
}
