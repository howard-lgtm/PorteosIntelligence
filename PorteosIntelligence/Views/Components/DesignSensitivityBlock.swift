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

    // ── Design tokens ─────────────────────────────────────────────────────────

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentPurple  = Color(hex: "#A855F7")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")
    private let colorGreen    = Color(hex: "#10B981")
    private let colorRed      = Color(hex: "#EF4444")

    // ── Column widths ─────────────────────────────────────────────────────────

    private let colLabel: CGFloat = 168
    private let colBase:  CGFloat = 110
    private let colSim:   CGFloat = 110

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
                          accentColor: accentPurple,
                          contentPadding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    adjustmentSection
                    Rectangle().fill(shellBorder).frame(height: 1)
                    resultsSection
                }
            }

            ScenarioManagerBlock(
                deal:               deal,
                profile:            "design",
                accentColor:        accentPurple,
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
            sectionLabel("ADJUST INPUTS")

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
                        .font(.custom("JetBrains Mono", size: 13))
                        .foregroundStyle(textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(daylightingAdj == 0 && biophilicAdj == 0 && spaceUtilizationAdj == 0)
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

    private func adjColor(_ display: String) -> Color {
        if display.hasPrefix("+") { return colorGreen }
        if display.hasPrefix("−") { return colorRed   }
        return textPrimary
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
    .background(Color(hex: "#0F1115"))
}
