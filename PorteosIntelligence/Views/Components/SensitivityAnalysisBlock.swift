import SwiftUI

// MARK: - SensitivityAnalysisBlock
//
// A read-only simulation block. It NEVER mutates the PropertyDeal.
// All adjustments are stored in local @State and fed to a local copy
// of RealEstateCalculator.FullInputs.

struct SensitivityAnalysisBlock: View {

    let deal: PropertyDeal

    // ── Adjustment State (simulation-only, never saved) ───────────────────────
    @State private var vacancyAdj:  Double = 0    // percentage points  (-10…+10)
    @State private var opexAdj:     Double = 0    // % change to opex   (-20…+20)
    @State private var rateAdj:     Double = 0    // percentage points  (-2…+2)

    private var accent: Color { ProfileType.realEstate.accentColor }

    // ── Column widths ─────────────────────────────────────────────────────────

    private let colLabel: CGFloat = 168
    private let colBase:  CGFloat = 110
    private let colSim:   CGFloat = 110

    // MARK: Computed Metrics

    /// Base: current deal metrics, unmodified.
    private var baseMetrics: RealEstateCalculator.FullMetrics {
        RealEstateCalculator.calculateFull(inputs: buildInputs(
            vacancyOffset:  0,
            opexMultiplier: 1.0,
            rateOffset:     0
        ))
    }

    /// Simulated: same calculator run with adjusted inputs.
    private var simMetrics: RealEstateCalculator.FullMetrics {
        RealEstateCalculator.calculateFull(inputs: buildInputs(
            vacancyOffset:  vacancyAdj,
            opexMultiplier: 1.0 + opexAdj / 100.0,
            rateOffset:     rateAdj
        ))
    }

    private func buildInputs(
        vacancyOffset:  Double,
        opexMultiplier: Double,
        rateOffset:     Double
    ) -> RealEstateCalculator.FullInputs {
        RealEstateCalculator.FullInputs(
            grossPotentialIncome:   deal.grossPotentialIncome,
            vacancyRate:            max(0, deal.vacancyRate + vacancyOffset),
            otherIncome:            deal.otherIncome,
            operatingExpenses:      deal.operatingExpenses * opexMultiplier,
            opexPropertyManagement: deal.opexPropertyManagement * opexMultiplier,
            opexPropertyTax:        deal.opexPropertyTax       * opexMultiplier,
            opexInsurance:          deal.opexInsurance          * opexMultiplier,
            opexUtilities:          deal.opexUtilities          * opexMultiplier,
            opexMaintenance:        deal.opexMaintenance        * opexMultiplier,
            opexCapitalReserves:    deal.opexCapitalReserves    * opexMultiplier,
            purchasePrice:          deal.purchasePrice,
            closingCosts:           deal.closingCosts,
            renovationBudget:       deal.renovationBudget,
            loanAmount:             deal.loanAmount,
            interestRate:           max(0.1, deal.interestRate + rateOffset),
            amortizationMonths:     deal.amortizationMonths,
            exitCapRate:            deal.exitCapRate
        )
    }

    // Simulated Porteos Score: start from stored score and apply RE cap-rate delta.
    // The other profile components (hospitality, design, circular) are unchanged.
    private var baseScore: Double {
        deal.porteosScore ?? estimateScore(metrics: baseMetrics)
    }

    private var simScore: Double {
        let baseCap = min(max(baseMetrics.capRate / 10.0 * 100, 0), 100)
        let simCap  = min(max(simMetrics.capRate  / 10.0 * 100, 0), 100)
        let reDelta = (simCap - baseCap) * (deal.weightRealEstate / 100)
        return min(100, max(0, baseScore + reDelta))
    }

    private func estimateScore(metrics: RealEstateCalculator.FullMetrics) -> Double {
        let normCap = min(max(metrics.capRate / 10.0 * 100, 0), 100)
        return normCap * (deal.weightRealEstate / 100)
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TerminalBlock(command: "06 // SENSITIVITY_SIMULATION",
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
                profile:            "realEstate",
                accentColor:        accent,
                moduleLabel:        "07 // SAVED_SCENARIOS",
                currentAdjustments: [
                    "vacancyAdj": vacancyAdj,
                    "opexAdj":    opexAdj,
                    "rateAdj":    rateAdj,
                ],
                onLoad: { dict in
                    vacancyAdj = dict["vacancyAdj"] ?? 0
                    opexAdj    = dict["opexAdj"]    ?? 0
                    rateAdj    = dict["rateAdj"]    ?? 0
                }
            )
        }
    }

    // MARK: – Adjustment Section

    private var adjustmentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TerminalSensitivityStyles.sectionLabel("ADJUST INPUTS")

            stepperRow(
                label:       "VACANCY RATE",
                display:     signedPct(vacancyAdj, dp: 1),
                canDecrement: vacancyAdj > -10,
                canIncrement: vacancyAdj <  10
            ) {
                vacancyAdj = max(-10, vacancyAdj - 0.5)
            } onIncrement: {
                vacancyAdj = min(10, vacancyAdj + 0.5)
            }

            stepperRow(
                label:       "OPERATING EXPENSES",
                display:     signedPct(opexAdj, dp: 1),
                canDecrement: opexAdj > -20,
                canIncrement: opexAdj <  20
            ) {
                opexAdj = max(-20, opexAdj - 2.5)
            } onIncrement: {
                opexAdj = min(20, opexAdj + 2.5)
            }

            stepperRow(
                label:       "INTEREST RATE",
                display:     signedPct(rateAdj, dp: 2),
                canDecrement: rateAdj > -2,
                canIncrement: rateAdj <  2
            ) {
                rateAdj = max(-2, rateAdj - 0.25)
            } onIncrement: {
                rateAdj = min(2, rateAdj + 0.25)
            }

            // Reset button
            HStack {
                Spacer()
                Button {
                    vacancyAdj = 0
                    opexAdj    = 0
                    rateAdj    = 0
                } label: {
                    Text("[ RESET ]")
                        .porteosRowValue()
                        .foregroundStyle(DesignTokens.textDim)
                }
                .buttonStyle(.plain)
                .disabled(vacancyAdj == 0 && opexAdj == 0 && rateAdj == 0)
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
        onIncrement: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: colLabel, alignment: .leading)
                .padding(.leading, 16)

            Spacer()

            Button { onDecrement() } label: {
                Text("[ − ]")
                .porteosRowValue()
                    .foregroundStyle(canDecrement ? DesignTokens.textSecondary : DesignTokens.textDim)
            }
            .buttonStyle(.plain)
            .disabled(!canDecrement)

            Text(display)
                .porteosMetricValue()
                .monospacedDigit()
                .foregroundStyle(TerminalSensitivityStyles.adjColor(display))
                .frame(width: 76, alignment: .center)

            Button { onIncrement() } label: {
                Text("[ + ]")
                .porteosRowValue()
                    .foregroundStyle(canIncrement ? DesignTokens.textSecondary : DesignTokens.textDim)
            }
            .buttonStyle(.plain)
            .disabled(!canIncrement)
            .padding(.trailing, 16)
        }
        .frame(height: DesignTokens.rowHeightHeader)
    }

    // MARK: – Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TerminalSensitivityStyles.sectionLabel("SIMULATION RESULTS")

            // Column headers
            HStack(spacing: 0) {
                Text("METRIC")
                    .porteosButtonPrimary()
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(width: colLabel, alignment: .leading)
                    .padding(.leading, 16)

                Text("BASE")
                    .porteosButtonPrimary()
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(width: colBase, alignment: .trailing)

                Text("SIMULATED")
                    .porteosButtonPrimary()
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(width: colSim, alignment: .trailing)

                Text("DELTA")
                    .porteosButtonPrimary()
                    .foregroundStyle(DesignTokens.textDim)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
            }
            .frame(height: 28)

            TerminalStructuralDivider()

            resultRow(
                label:    "NOI",
                base:     eur(baseMetrics.netOperatingIncome),
                sim:      eur(simMetrics.netOperatingIncome),
                delta:    simMetrics.netOperatingIncome - baseMetrics.netOperatingIncome,
                format:   { eur($0) },
                higherBetter: true
            )

            resultRow(
                label:    "CASH FLOW BEFORE TAX",
                base:     eur(baseMetrics.cashFlowBeforeTax),
                sim:      eur(simMetrics.cashFlowBeforeTax),
                delta:    simMetrics.cashFlowBeforeTax - baseMetrics.cashFlowBeforeTax,
                format:   { eur($0) },
                higherBetter: true
            )

            resultRow(
                label:    "CAP RATE",
                base:     pct(baseMetrics.capRate, dp: 2),
                sim:      pct(simMetrics.capRate, dp: 2),
                delta:    simMetrics.capRate - baseMetrics.capRate,
                format:   { signedPct($0, dp: 2) },
                higherBetter: true
            )

            resultRow(
                label:    "DSCR",
                base:     dscr(baseMetrics.debtServiceCoverageRatio),
                sim:      dscr(simMetrics.debtServiceCoverageRatio),
                delta:    simMetrics.debtServiceCoverageRatio - baseMetrics.debtServiceCoverageRatio,
                format:   { ($0 >= 0 ? "+" : "−") + dscrDelta($0) },
                higherBetter: true
            )

            resultRow(
                label:    "PORTEOS SCORE",
                base:     scoreFmt(baseScore),
                sim:      scoreFmt(simScore),
                delta:    simScore - baseScore,
                format:   { ($0 >= 0 ? "+" : "−") + scoreFmt(abs($0)) },
                higherBetter: true
            )

            // Padding at bottom
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
        let positive = delta > 0
        let neutral  = abs(delta) < 0.001
        let good     = higherBetter ? positive : !positive
        let deltaColor = TerminalSensitivityStyles.deltaColor(delta: delta, higherBetter: higherBetter)
        let indicator = neutral ? "  " : (positive ? "▲" : "▼")

        return HStack(spacing: 0) {
            Text(label)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: colLabel, alignment: .leading)
                .padding(.leading, 16)

            Text(base)
                .porteosRowValue()
                .monospacedDigit()
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: colBase, alignment: .trailing)

            Text(sim)
                .porteosMetricValue()
                .monospacedDigit()
                .foregroundStyle(neutral ? DesignTokens.textPrimary : (good ? DesignTokens.statusGo : DesignTokens.statusCritical))
                .frame(width: colSim, alignment: .trailing)

            HStack(spacing: 4) {
                Text(indicator)
                    .porteosRowLabel()
                    .foregroundStyle(deltaColor)
                Text(neutral ? "—" : format(delta))
                .porteosRowValue()
                    .monospacedDigit()
                    .foregroundStyle(deltaColor)
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)

            Spacer()
        }
        .frame(height: DesignTokens.rowHeightHeader)
        .background(Color.clear)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DesignTokens.dividerStructural.opacity(0.4)).frame(height: 1)
        }
    }

    // MARK: – Formatters

    private func eur(_ v: Double) -> String {
        v.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
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

    private func dscr(_ v: Double) -> String {
        "\(v.formatted(.number.precision(.fractionLength(2))))x"
    }

    private func dscrDelta(_ v: Double) -> String {
        "\(abs(v).formatted(.number.precision(.fractionLength(2))))x"
    }

    private func scoreFmt(_ v: Double) -> String {
        "\(Int(v.rounded()))"
    }
}

// MARK: - Preview

#Preview {
    let deal = PropertyDeal(
        propertyName:           "Lisbon Office Block A",
        purchasePrice:          2_000_000,
        closingCosts:           60_000,
        grossPotentialIncome:   180_000,
        vacancyRate:            5,
        operatingExpenses:      55_000,
        loanAmount:             1_500_000,
        interestRate:           4.5,
        amortizationMonths:     360,
        exitCapRate:            5.5,
        opexPropertyManagement: 14_400,
        opexPropertyTax:        12_000,
        opexInsurance:          4_800,
        opexUtilities:          9_600,
        opexMaintenance:        8_400,
        opexCapitalReserves:    5_800
    )
    ScrollView {
        SensitivityAnalysisBlock(deal: deal)
            .padding(16)
    }
    .frame(width: 700, height: 600)
    .background(DesignTokens.canvasBase)
}
