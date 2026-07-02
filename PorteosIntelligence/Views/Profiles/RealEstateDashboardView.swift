import SwiftUI
import SwiftData

// MARK: - RealEstateDashboardView

struct RealEstateDashboardView: View {

    var deal: PropertyDeal
    @State private var localDeal: PropertyDeal

    init(deal: PropertyDeal) {
        self.deal        = deal
        self._localDeal  = State(initialValue: deal)
    }

    // MARK: Profile

    private var accent: Color { ProfileType.realEstate.accentColor }

    // MARK: Computed

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

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TerminalCLIHeader(
                command: "profile --real-estate --asset=\"\(localDeal.propertyName.isEmpty ? "Untitled Deal" : localDeal.propertyName)\"",
                accentColor: accent
            )
            TerminalStructuralDivider()

            if hasData {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.blockSpacing) {
                        let logs = DataValidator.validate(deal: localDeal)
                        SystemLogBlock(messages: logs)
                        module01Revenue
                        module02OpEx
                        module03Profitability
                        module04Leverage
                        module05Returns
                        SensitivityAnalysisBlock(deal: localDeal)
                        MarketTrendModule(city: localDeal.locationCity, profile: "realEstate", accent: accent)
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

    // MARK: Module 01 // CORE_FINANCIALS_REVENUE

    private var module01Revenue: some View {
        TerminalBlock(command: "01 // CORE_FINANCIALS_REVENUE", accentColor: accent) {
            TerminalMetricGrid {
                MetricGridCell(label: "Gross Potential Income", value: eur(metrics.grossPotentialIncome))
                MetricGridCell(label: "Vacancy Loss",           value: "(\(eur(metrics.vacancyLoss)))", state: localDeal.vacancyRate > 10 ? .warning : .neutral)
                MetricGridCell(label: "Effective Gross Income", value: eur(metrics.effectiveGrossIncome))
                MetricGridCell(label: "Other Income",           value: eur(metrics.otherIncome))
                MetricGridCell(label: "Total Revenue",          value: eur(metrics.totalRevenue))
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 02 // EXPENSE_AUDIT_OPEX
    // ─────────────────────────────────────────────────────────────────────────

    private var module02OpEx: some View {
        TerminalBlock(command: "02 // EXPENSE_AUDIT_OPEX", accentColor: accent) {
            TerminalMetricGrid {
                MetricGridCell(label: "Property Management",   value: localDeal.opexPropertyManagement > 0 ? eur(metrics.opexPropertyManagement) : "—")
                MetricGridCell(label: "Property Tax",          value: localDeal.opexPropertyTax > 0 ? eur(metrics.opexPropertyTax) : "—")
                MetricGridCell(label: "Insurance",             value: localDeal.opexInsurance > 0 ? eur(metrics.opexInsurance) : "—")
                MetricGridCell(label: "Utilities",             value: localDeal.opexUtilities > 0 ? eur(metrics.opexUtilities) : "—")
                MetricGridCell(label: "Maintenance & Repairs", value: localDeal.opexMaintenance > 0 ? eur(metrics.opexMaintenance) : "—")
                MetricGridCell(label: "Capital Reserves",      value: localDeal.opexCapitalReserves > 0 ? eur(metrics.opexCapitalReserves) : "—")
                MetricGridCell(label: "Total Operating Expenses", value: eur(metrics.totalOpEx))
                MetricGridCell(label: "Operating Expense Ratio",  value: pct(metrics.opExRatio), state: opExRatioState(metrics.opExRatio))
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 03 // PROFITABILITY_TELEMETRY
    // ─────────────────────────────────────────────────────────────────────────

    private var module03Profitability: some View {
        TerminalBlock(command: "03 // PROFITABILITY_TELEMETRY", accentColor: accent) {
            TerminalMetricGrid {
                let noiTrend  = mockTrend(from: metrics.netOperatingIncome)
                let capTrend  = mockTrend(from: metrics.capRate)
                let cfbtTrend = mockTrend(from: metrics.cashFlowBeforeTax)
                let cfatTrend = mockTrend(from: metrics.cashFlowAfterTax)

                TerminalMetricCell(label: "NOI", value: eur(metrics.netOperatingIncome),
                                   trend: noiTrend, trendColor: sparkColor(noiTrend))
                TerminalMetricCell(label: "EBITDA (est.)", value: eur(metrics.ebitda))
                TerminalMetricCell(label: "Cap Rate", value: pct(metrics.capRate, dp: 2),
                                   state: capRateState(metrics.capRate),
                                   trend: capTrend, trendColor: sparkColor(capTrend))
                TerminalMetricCell(label: "Cash Flow Before Tax", value: eur(metrics.cashFlowBeforeTax),
                                   state: metrics.cashFlowBeforeTax < 0 ? .danger : .neutral,
                                   trend: cfbtTrend, trendColor: sparkColor(cfbtTrend))
                TerminalMetricCell(label: "Cash Flow After Tax", value: eur(metrics.cashFlowAfterTax),
                                   state: metrics.cashFlowAfterTax < 0 ? .danger : .neutral,
                                   trend: cfatTrend, trendColor: sparkColor(cfatTrend))
            }
        }
    }

    // MARK: Module 04 // LEVERAGE_ENGINE

    private var module04Leverage: some View {
        TerminalBlock(command: "04 // LEVERAGE_ENGINE", accentColor: accent) {
            TerminalMetricGrid {
                MetricGridCell(label: "Loan Amount",         value: eur(metrics.loanAmount))
                MetricGridCell(label: "Loan-to-Value (LTV)", value: pct(metrics.loanToValue, dp: 1),  state: ltvState(metrics.loanToValue))
                MetricGridCell(label: "Loan-to-Cost (LTC)",  value: pct(metrics.loanToCost, dp: 1),   state: ltvState(metrics.loanToCost))
                MetricGridCell(label: "Interest Rate",       value: pct(metrics.annualInterestRate, dp: 2))
                MetricGridCell(label: "Amortization",        value: "\(metrics.amortizationMonths) months")
                MetricGridCell(label: "Annual Debt Service", value: eur(metrics.annualDebtService))
                MetricGridCell(label: "DSCR",                value: "\(metrics.debtServiceCoverageRatio.formatted(.number.precision(.fractionLength(2))))x", state: dscrState(metrics.debtServiceCoverageRatio))
                MetricGridCell(label: "Debt Yield",          value: pct(metrics.debtYield, dp: 2))
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 05 // RETURN_METRICS
    // ─────────────────────────────────────────────────────────────────────────

    private var module05Returns: some View {
        TerminalBlock(command: "05 // RETURN_METRICS  [5yr hold]", accentColor: accent) {
            TerminalMetricGrid {
                let cocTrend = mockTrend(from: metrics.cashOnCashReturn)
                let irrTrend = mockTrend(from: metrics.leveredIRR)

                TerminalMetricCell(label: "Total Equity Invested", value: eur(metrics.totalEquityInvested))
                TerminalMetricCell(label: "Cash-on-Cash Return", value: pct(metrics.cashOnCashReturn, dp: 2),
                                   state: cocState(metrics.cashOnCashReturn),
                                   trend: cocTrend, trendColor: sparkColor(cocTrend))
                TerminalMetricCell(label: "Equity Multiple (5Y)",
                                   value: "\(metrics.equityMultiple5Y.formatted(.number.precision(.fractionLength(2))))x",
                                   state: emState(metrics.equityMultiple5Y))
                TerminalMetricCell(label: "Unlevered IRR (est.)", value: pct(metrics.unleveredIRR, dp: 1),
                                   state: irrState(metrics.unleveredIRR))
                TerminalMetricCell(label: "Levered IRR (est.)", value: pct(metrics.leveredIRR, dp: 1),
                                   state: irrState(metrics.leveredIRR),
                                   trend: irrTrend, trendColor: sparkColor(irrTrend))
            }
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 8) {
                Text("porteos@system ~ % ls ./deals")
                    .font(DesignTokens.mono(size: 11))
                    .foregroundStyle(DesignTokens.textDim)
                Text("No real estate data")
                    .font(DesignTokens.mono(size: 12))
                    .foregroundStyle(DesignTokens.textSecondary)
                Text("Click [ ./EDIT_DEAL ] to add financials")
                    .font(DesignTokens.mono(size: 11))
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

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Threshold Logic
    // ─────────────────────────────────────────────────────────────────────────

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

    /// Green ≥7 %, Amber 5–7 %, Red <5 %
    private func capRateState(_ v: Double) -> MetricState {
        if v >= 7.0 { return .optimal }
        if v >= 5.0 { return .warning }
        return .danger
    }

    /// Red >40 %, Amber 30–40 %, Neutral ≤30 %
    private func opExRatioState(_ v: Double) -> MetricState {
        if v > 40 { return .danger }
        if v > 30 { return .warning }
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
        if v >=  8.0 { return .warning }
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
    let deal = PropertyDeal()
    return RealEstateDashboardView(deal: deal)
        .frame(width: 720, height: 400)
        .background(DesignTokens.canvasBase)
}
