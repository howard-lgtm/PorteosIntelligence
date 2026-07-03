import SwiftUI
import SwiftData

// MARK: - RealEstateDashboardView
// V2.06 Phase 2A — layout matches Figma "Real Estate Dashboard" (660×1014).

struct RealEstateDashboardView: View {

    var deal: PropertyDeal
    @State private var localDeal: PropertyDeal

    init(deal: PropertyDeal) {
        self.deal        = deal
        self._localDeal  = State(initialValue: deal)
    }

    private var accent: Color { ProfileType.realEstate.accentColor }

    private var porteosScore: PorteosScoreCalculator.PorteosMetrics {
        PropertyDealViewModel(deal: localDeal).porteosScore
    }

    private var dealDisplayName: String {
        localDeal.propertyName.isEmpty ? "Untitled Deal" : localDeal.propertyName
    }

    private var hasData: Bool { localDeal.grossPotentialIncome > 0 || localDeal.operatingExpenses > 0 }

    private var metrics: RealEstateCalculator.FullMetrics {
        RealEstateCalculator.calculateFull(inputs: RealEstateCalculator.FullInputs(
            grossPotentialIncome:   localDeal.grossPotentialIncome,
            vacancyRate:            localDeal.vacancyRate,
            otherIncome:            localDeal.otherIncome,
            operatingExpenses:      localDeal.operatingExpenses,
            opexPropertyManagement: localDeal.opexPropertyManagement,
            opexPropertyTax:        localDeal.opexPropertyTax,
            opexInsurance:          localDeal.opexInsurance,
            opexUtilities:          localDeal.opexUtilities,
            opexMaintenance:        localDeal.opexMaintenance,
            opexCapitalReserves:    localDeal.opexCapitalReserves,
            purchasePrice:          localDeal.purchasePrice,
            closingCosts:           localDeal.closingCosts,
            renovationBudget:       localDeal.renovationBudget,
            loanAmount:             localDeal.loanAmount,
            interestRate:           localDeal.interestRate,
            amortizationMonths:     localDeal.amortizationMonths,
            exitCapRate:            localDeal.exitCapRate
        ))
    }

    /// OpEx lines rolled into Figma "Other OpEx" cell.
    private var otherOpEx: Double {
        metrics.opexPropertyTax + metrics.opexUtilities + metrics.opexCapitalReserves
            + max(0, metrics.totalOpEx
                  - metrics.opexPropertyManagement
                  - metrics.opexMaintenance
                  - metrics.opexInsurance)
    }

    private var noiMargin: Double {
        guard metrics.totalRevenue > 0 else { return 0 }
        return metrics.netOperatingIncome / metrics.totalRevenue * 100
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DashboardCLIHeader(profile: .realEstate, dealName: dealDisplayName)
            TerminalStructuralDivider()

            if hasData {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.blockSpacing) {
                        DashboardHeroScore(
                            score: porteosScore.finalScore,
                            grade: porteosScore.scoreGrade,
                            dealName: dealDisplayName,
                            profile: .realEstate
                        )
                        ValidationLogModule(
                            messages: DataValidator.validate(deal: localDeal),
                            accentColor: accent
                        )
                        MarketTrendGrid(deal: localDeal, profileKey: "realEstate", accent: accent)
                        module01Revenue
                        module02OpEx
                        module03Profitability
                        module04Leverage
                        module05Returns
                        sensitivityModule
                    }
                    .padding(DesignTokens.blockGutter)
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.canvasBase)
        .onChange(of: deal) { localDeal = deal }
    }

    private var sensitivityModule: some View {
        RealEstateSensitivityModule(deal: localDeal)
    }

    // MARK: 01 // CORE_FINANCIALS_REVENUE — 2×2

    private var module01Revenue: some View {
        TerminalBlock(command: "01 // CORE_FINANCIALS_REVENUE", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 2) {
                TerminalMetricCell(label: "GPI", value: eur(metrics.grossPotentialIncome))
                TerminalMetricCell(label: "NOI", value: eur(metrics.netOperatingIncome))
                TerminalMetricCell(
                    label: "VACANCY",
                    value: pct(localDeal.vacancyRate, dp: 1),
                    state: localDeal.vacancyRate > 10 ? .warning : .neutral
                )
                TerminalMetricCell(label: "OTHER INCOME", value: eur(metrics.otherIncome))
            }
        }
    }

    // MARK: 02 // EXPENSE_AUDIT_OPEX — 1×4

    private var module02OpEx: some View {
        TerminalBlock(command: "02 // EXPENSE_AUDIT_OPEX", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 4) {
                TerminalMetricCell(
                    label: "MGMT",
                    value: localDeal.opexPropertyManagement > 0 ? eur(metrics.opexPropertyManagement) : "—"
                )
                TerminalMetricCell(
                    label: "MAINTENANCE",
                    value: localDeal.opexMaintenance > 0 ? eur(metrics.opexMaintenance) : "—"
                )
                TerminalMetricCell(
                    label: "INSURANCE",
                    value: localDeal.opexInsurance > 0 ? eur(metrics.opexInsurance) : "—"
                )
                TerminalMetricCell(
                    label: "OTHER OPEX",
                    value: otherOpEx > 0 ? eur(otherOpEx) : "—"
                )
            }
        }
    }

    // MARK: 03 // PROFITABILITY_TELEMETRY — 2×2

    private var module03Profitability: some View {
        TerminalBlock(command: "03 // PROFITABILITY_TELEMETRY", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 2) {
                TerminalMetricCell(
                    label: "CAP RATE",
                    value: pct(metrics.capRate, dp: 2),
                    state: capRateState(metrics.capRate)
                )
                TerminalMetricCell(
                    label: "DSCR",
                    value: "\(metrics.debtServiceCoverageRatio.formatted(.number.precision(.fractionLength(2)))) x",
                    state: dscrState(metrics.debtServiceCoverageRatio)
                )
                TerminalMetricCell(
                    label: "CASH-ON-CASH",
                    value: pct(metrics.cashOnCashReturn, dp: 2),
                    state: cocState(metrics.cashOnCashReturn)
                )
                TerminalMetricCell(
                    label: "NOI MARGIN",
                    value: metrics.totalRevenue > 0 ? pct(noiMargin, dp: 1) : "—",
                    state: noiMarginState(noiMargin)
                )
            }
        }
    }

    // MARK: 04 // LEVERAGE_ENGINE — segment bars (Figma)

    private var module04Leverage: some View {
        TerminalBlock(command: "04 // LEVERAGE_ENGINE", accentColor: accent) {
            VStack(spacing: DesignTokens.gridRowSpacing) {
                leverageGaugeRow(
                    label: "LTV",
                    value: pct(metrics.loanToValue, dp: 1),
                    state: ltvState(metrics.loanToValue),
                    fillRatio: min(metrics.loanToValue / 100, 1),
                    barColor: accent
                )
                leverageGaugeRow(
                    label: "DSCR",
                    value: "\(metrics.debtServiceCoverageRatio.formatted(.number.precision(.fractionLength(2)))) x",
                    state: dscrState(metrics.debtServiceCoverageRatio),
                    fillRatio: min(metrics.debtServiceCoverageRatio / 2.0, 1),
                    barColor: DesignTokens.statusWarn
                )
            }
            .padding(DesignTokens.blockGutter)
        }
    }

    private func leverageGaugeRow(
        label: String,
        value: String,
        state: MetricState,
        fillRatio: Double,
        barColor: Color
    ) -> some View {
        HStack(spacing: 10) {
            Text(label.uppercased())
                .font(DesignTokens.metricLabelFont())
                .tracking(0.02)
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: 48, alignment: .leading)

            TerminalSegmentBar(fillRatio: fillRatio, barColor: barColor)

            Text(value)
                .font(DesignTokens.metricValueFont())
                .monospacedDigit()
                .foregroundStyle(state.semanticColor)
                .frame(minWidth: 56, alignment: .trailing)
        }
        .padding(DesignTokens.metricCellPadding)
        .frame(minHeight: DesignTokens.metricCellMinHeight)
        .background(DesignTokens.surfaceElevated)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
    }

    // MARK: 05 // RETURN_METRICS — 1×4

    private var module05Returns: some View {
        TerminalBlock(command: "05 // RETURN_METRICS  [5yr hold]", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 4) {
                TerminalMetricCell(
                    label: "IRR",
                    value: metrics.leveredIRR != 0 ? pct(metrics.leveredIRR, dp: 1) : "—",
                    state: irrState(metrics.leveredIRR)
                )
                TerminalMetricCell(
                    label: "EQUITY MULT.",
                    value: metrics.equityMultiple5Y > 0
                        ? "\(metrics.equityMultiple5Y.formatted(.number.precision(.fractionLength(1)))) x"
                        : "—",
                    state: emState(metrics.equityMultiple5Y)
                )
                TerminalMetricCell(label: "NPV", value: "—")
                TerminalMetricCell(label: "HOLD PERIOD", value: "5 yr")
            }
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 8) {
                Text("porteos@system ~ % ls ./deals")
                    .font(DesignTokens.cliPromptFont())
                    .foregroundStyle(DesignTokens.textDim)
                Text("No real estate data")
                    .font(DesignTokens.rowValueFont())
                    .foregroundStyle(DesignTokens.textSecondary)
                Text("Click [ ./EDIT_DEAL ] to add financials")
                    .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowLabel))
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Formatters

    private func eur(_ v: Double) -> String {
        v.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }

    private func pct(_ v: Double, dp: Int = 1) -> String {
        "\(v.formatted(.number.precision(.fractionLength(dp))))%"
    }

    // MARK: Threshold Logic

    private func dscrState(_ v: Double) -> MetricState {
        if v >= 1.25 { return .optimal }
        if v >= 1.10 { return .warning }
        return .danger
    }

    private func ltvState(_ v: Double) -> MetricState {
        if v <= 75 { return .optimal }
        if v <= 90 { return .warning }
        return .danger
    }

    private func capRateState(_ v: Double) -> MetricState {
        if v >= 7.0 { return .optimal }
        if v >= 5.0 { return .warning }
        return .danger
    }

    private func noiMarginState(_ v: Double) -> MetricState {
        if v >= 60 { return .optimal }
        if v >= 45 { return .warning }
        return .neutral
    }

    private func cocState(_ v: Double) -> MetricState {
        if v >= 8.0 { return .optimal }
        if v >= 5.0 { return .warning }
        return v < 0 ? .danger : .neutral
    }

    private func emState(_ v: Double) -> MetricState {
        if v >= 2.0 { return .optimal }
        if v >= 1.5 { return .warning }
        return v < 1.0 ? .danger : .neutral
    }

    private func irrState(_ v: Double) -> MetricState {
        if v >= 12.0 { return .optimal }
        if v >= 8.0  { return .warning }
        return v < 0 ? .danger : .neutral
    }
}

// MARK: - Preview

#Preview("Full Data") {
    let deal = PropertyDeal(
        propertyName:           "Lisbon Office Block A",
        purchasePrice:          2_000_000,
        closingCosts:           60_000,
        renovationBudget:       80_000,
        grossPotentialIncome:   180_000,
        vacancyRate:            5,
        otherIncome:            12_000,
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
    return ScrollView {
        RealEstateDashboardView(deal: deal)
    }
    .frame(width: 660, height: 900)
    .background(DesignTokens.canvasBase)
}

#Preview("Empty State") {
    RealEstateDashboardView(deal: PropertyDeal())
        .frame(width: 660, height: 400)
        .background(DesignTokens.canvasBase)
}
