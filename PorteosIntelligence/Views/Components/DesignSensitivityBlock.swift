import SwiftUI

// MARK: - DesignSensitivityBlock
//
// A read-only simulation block. It NEVER mutates the PropertyDeal.
// Composite "Design Score" and "Wellness Score" are computed inline from a
// weighted subset of design metrics; they serve as directional estimates only.

struct DesignSensitivityBlock: View {

    let deal: PropertyDeal

    // ── Adjustment State (simulation-only, never saved) ───────────────────────
    @State private var daylightingAdj:     Double = 0   // pp   (−30…+30)
    @State private var biophilicAdj:       Int    = 0   // count (−5…+10)
    @State private var spaceUtilizationAdj: Double = 0  // pp   (−20…+20)

    private var accent: Color { ProfileType.design.accentColor }

    // MARK: Computed Scores

    /// Weighted composite design quality score (0–100), directional estimate.
    /// Weights: daylighting 30%, biophilic 25%, space utilisation 25%, adaptability 20%.
    private func designScore(daylighting: Double, biophilic: Int, spaceUtil: Double) -> Double {
        let biophilicNorm = min(100.0, Double(max(0, biophilic)) * 10.0) // 10 elements → 100
        let adaptability  = deal.designAdaptabilityScore
        return clamp(daylighting)      * 0.30
             + clamp(biophilicNorm)   * 0.25
             + clamp(spaceUtil)       * 0.25
             + clamp(adaptability)    * 0.20
    }

    /// Weighted wellness/indoor environment score (0–100), directional estimate.
    /// Weights: daylighting 40%, thermal comfort 35%, acoustic comfort 25%.
    private func wellnessScore(daylighting: Double) -> Double {
        clamp(daylighting)                 * 0.40
        + clamp(deal.designThermalComfort) * 0.35
        + clamp(deal.designAcousticComfort) * 0.25
    }

    private var baseDesign:    Double { designScore(daylighting: deal.designDaylighting,
                                                   biophilic:   deal.designBiophilicCount,
                                                   spaceUtil:   deal.designSpaceUtilization) }
    private var simDesign:     Double { designScore(daylighting: deal.designDaylighting + daylightingAdj,
                                                   biophilic:   deal.designBiophilicCount + biophilicAdj,
                                                   spaceUtil:   deal.designSpaceUtilization + spaceUtilizationAdj) }
    private var baseWellness:  Double { wellnessScore(daylighting: deal.designDaylighting) }
    private var simWellness:   Double { wellnessScore(daylighting: deal.designDaylighting + daylightingAdj) }

    private func clamp(_ v: Double) -> Double { min(100, max(0, v)) }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TerminalBlock(command: "05 // SENSITIVITY_SIMULATION",
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
                profile:            "design",
                accentColor:        accent,
                moduleLabel:        "06 // SAVED_SCENARIOS",
                currentAdjustments: [
                    "daylightingAdj":      daylightingAdj,
                    "biophilicAdj":        Double(biophilicAdj),
                    "spaceUtilizationAdj": spaceUtilizationAdj,
                ],
                onLoad: { dict in
                    daylightingAdj      = dict["daylightingAdj"]      ?? 0
                    biophilicAdj        = Int((dict["biophilicAdj"]   ?? 0).rounded())
                    spaceUtilizationAdj = dict["spaceUtilizationAdj"] ?? 0
                }
            )
        }
    }

    // MARK: – Adjustment Section

    private var adjustmentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TerminalSensitivityStyles.sectionLabel("ADJUST INPUTS")

            stepperRow(
                label:        "DAYLIGHTING",
                display:      signedPct(daylightingAdj, dp: 1),
                canDecrement: daylightingAdj > -30,
                canIncrement: daylightingAdj <  30
            ) {
                daylightingAdj = max(-30, daylightingAdj - 5)
            } onIncrement: {
                daylightingAdj = min(30, daylightingAdj + 5)
            }

            stepperRow(
                label:        "BIOPHILIC ELEMENTS",
                display:      signedCount(biophilicAdj),
                canDecrement: biophilicAdj > -5,
                canIncrement: biophilicAdj < 10
            ) {
                biophilicAdj = max(-5, biophilicAdj - 1)
            } onIncrement: {
                biophilicAdj = min(10, biophilicAdj + 1)
            }

            stepperRow(
                label:        "SPACE UTILIZATION",
                display:      signedPct(spaceUtilizationAdj, dp: 1),
                canDecrement: spaceUtilizationAdj > -20,
                canIncrement: spaceUtilizationAdj <  20
            ) {
                spaceUtilizationAdj = max(-20, spaceUtilizationAdj - 5)
            } onIncrement: {
                spaceUtilizationAdj = min(20, spaceUtilizationAdj + 5)
            }

            HStack {
                Spacer()
                Button {
                    daylightingAdj      = 0
                    biophilicAdj        = 0
                    spaceUtilizationAdj = 0
                } label: {
                    Text("[ RESET ]")
                        .font(DesignTokens.mono(size: 13))
                        .foregroundStyle(DesignTokens.textDim)
                }
                .buttonStyle(.plain)
                .disabled(daylightingAdj == 0 && biophilicAdj == 0 && spaceUtilizationAdj == 0)
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

            resultRow(
                label:        "DESIGN SCORE",
                base:         score(baseDesign),
                sim:          score(simDesign),
                delta:        simDesign - baseDesign,
                format:       { signedScore($0) },
                higherBetter: true
            )

            resultRow(
                label:        "WELLNESS SCORE",
                base:         score(baseWellness),
                sim:          score(simWellness),
                delta:        simWellness - baseWellness,
                format:       { signedScore($0) },
                higherBetter: true
            )

            resultRow(
                label:        "DAYLIGHTING",
                base:         pct(deal.designDaylighting, dp: 1),
                sim:          pct(deal.designDaylighting + daylightingAdj, dp: 1),
                delta:        daylightingAdj,
                format:       { signedPct($0, dp: 1) },
                higherBetter: true
            )

            resultRow(
                label:        "BIOPHILIC COUNT",
                base:         "\(deal.designBiophilicCount)",
                sim:          "\(deal.designBiophilicCount + biophilicAdj)",
                delta:        Double(biophilicAdj),
                format:       { ($0 >= 0 ? "+" : "−") + "\(Int(abs($0)))" },
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
        let deltaColor = TerminalSensitivityStyles.deltaColor(delta: delta, higherBetter: higherBetter)
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
        "\(min(100, max(0, v)).formatted(.number.precision(.fractionLength(dp))))%"
    }

    private func signedPct(_ v: Double, dp: Int = 1) -> String {
        let s = abs(v).formatted(.number.precision(.fractionLength(dp)))
        if v > 0 { return "+\(s)%" }
        if v < 0 { return "−\(s)%" }
        return "0\(dp > 0 ? ".\(String(repeating: "0", count: dp))" : "")%"
    }

    private func signedCount(_ v: Int) -> String {
        if v > 0 { return "+\(v)" }
        if v < 0 { return "−\(abs(v))" }
        return "0"
    }

    private func score(_ v: Double) -> String {
        String(format: "%.1f", min(100, max(0, v)))
    }

    private func signedScore(_ v: Double) -> String {
        let s = String(format: "%.1f", abs(v))
        if v > 0 { return "+\(s)" }
        if v < 0 { return "−\(s)" }
        return "0.0"
    }
}

// MARK: - Preview

#Preview {
    let deal = PropertyDeal(
        propertyName:           "Lisbon HQ",
        designGFA:              2_000,
        designNIA:              1_600,
        designSpaceUtilization: 82,
        designDaylighting:      65,
        designThermalComfort:   78,
        designAcousticComfort:  72,
        designBiophilicCount:   6,
        designAdaptabilityScore: 70
    )
    ScrollView {
        DesignSensitivityBlock(deal: deal)
            .padding(16)
    }
    .frame(width: 700, height: 600)
    .background(DesignTokens.canvasBase)
}
