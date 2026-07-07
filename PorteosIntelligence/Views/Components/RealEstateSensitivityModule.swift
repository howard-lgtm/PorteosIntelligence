import SwiftUI

// MARK: - RealEstateSensitivityModule
// Figma 06 // SENSITIVITY_ANALYSIS — read-only stress bars (calculator-backed).

struct RealEstateSensitivityModule: View {

    let deal: PropertyDeal

    private var accent: Color { ProfileType.realEstate.accentColor }

    private var baseInputs: RealEstateCalculator.FullInputs {
        RealEstateCalculator.FullInputs(
            grossPotentialIncome:   deal.grossPotentialIncome,
            vacancyRate:            deal.vacancyRate,
            otherIncome:            deal.otherIncome,
            operatingExpenses:      deal.operatingExpenses,
            opexPropertyManagement: deal.opexPropertyManagement,
            opexPropertyTax:        deal.opexPropertyTax,
            opexInsurance:          deal.opexInsurance,
            opexUtilities:          deal.opexUtilities,
            opexMaintenance:        deal.opexMaintenance,
            opexCapitalReserves:    deal.opexCapitalReserves,
            purchasePrice:          deal.purchasePrice,
            closingCosts:           deal.closingCosts,
            renovationBudget:       deal.renovationBudget,
            loanAmount:             deal.loanAmount,
            interestRate:           deal.interestRate,
            amortizationMonths:     deal.amortizationMonths,
            exitCapRate:            deal.exitCapRate
        )
    }

    private var baseMetrics: RealEstateCalculator.FullMetrics {
        RealEstateCalculator.calculateFull(inputs: baseInputs)
    }

    private struct Scenario {
        let label: String
        let delta: Double
        let suffix: String
    }

    private var scenarios: [Scenario] {
        let baseNOI = baseMetrics.netOperatingIncome
        let baseCF  = baseMetrics.cashFlowBeforeTax

        let vacMetrics = RealEstateCalculator.calculateFull(inputs: adjusted(vacancyOffset: 5))
        let rateMetrics = RealEstateCalculator.calculateFull(inputs: adjusted(rateOffset: 1))

        let capDelta: Double
        if deal.purchasePrice > 0 {
            capDelta = -(deal.purchasePrice * 0.005)
        } else {
            capDelta = vacMetrics.netOperatingIncome - baseNOI
        }

        return [
            Scenario(label: "Cap Rate ±0.5%", delta: capDelta, suffix: "NOI"),
            Scenario(label: "Vacancy +5%", delta: vacMetrics.netOperatingIncome - baseNOI, suffix: "NOI"),
            Scenario(label: "Int Rate +100BPS", delta: rateMetrics.cashFlowBeforeTax - baseCF, suffix: "CF"),
        ]
    }

    var body: some View {
        TerminalBlock(command: "06 // SENSITIVITY_ANALYSIS", accentColor: accent, contentPadding: 0) {
            let rows = scenarios
            let maxMag = max(rows.map { abs($0.delta) }.max() ?? 1, 1)

            VStack(spacing: DesignTokens.gridRowSpacing) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, scenario in
                    SensitivityImpactRow(
                        label: scenario.label,
                        fillRatio: abs(scenario.delta) / maxMag,
                        impactText: impactFmt(scenario.delta, suffix: scenario.suffix),
                        accent: accent,
                        impactColor: scenario.delta < 0 ? DesignTokens.statusWarn : DesignTokens.statusGo
                    )
                }
            }
            .padding(DesignTokens.blockGutter)
        }
    }

    private func adjusted(vacancyOffset: Double = 0, rateOffset: Double = 0) -> RealEstateCalculator.FullInputs {
        RealEstateCalculator.FullInputs(
            grossPotentialIncome:   deal.grossPotentialIncome,
            vacancyRate:            max(0, deal.vacancyRate + vacancyOffset),
            otherIncome:            deal.otherIncome,
            operatingExpenses:      deal.operatingExpenses,
            opexPropertyManagement: deal.opexPropertyManagement,
            opexPropertyTax:        deal.opexPropertyTax,
            opexInsurance:          deal.opexInsurance,
            opexUtilities:          deal.opexUtilities,
            opexMaintenance:        deal.opexMaintenance,
            opexCapitalReserves:    deal.opexCapitalReserves,
            purchasePrice:          deal.purchasePrice,
            closingCosts:           deal.closingCosts,
            renovationBudget:       deal.renovationBudget,
            loanAmount:             deal.loanAmount,
            interestRate:           max(0.1, deal.interestRate + rateOffset),
            amortizationMonths:     deal.amortizationMonths,
            exitCapRate:            deal.exitCapRate
        )
    }

    private func impactFmt(_ delta: Double, suffix: String) -> String {
        let sign = delta >= 0 ? "+" : "−"
        return "\(sign)\(compactEur(abs(delta))) \(suffix)"
    }

    private func compactEur(_ v: Double) -> String {
        let absV = abs(v)
        if absV >= 1_000_000 { return "€\(String(format: "%.1fM", absV / 1_000_000))" }
        if absV >= 1_000     { return "€\(String(format: "%.0fK", absV / 1_000))" }
        return v.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }
}
