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

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellElevated = Color(hex: "#23262E")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentRust    = Color(hex: "#C25E30")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")

    // MARK: Computed

    private var hasData: Bool { localDeal.grossPotentialIncome > 0 || localDeal.operatingExpenses > 0 }

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 250), spacing: 16, alignment: .leading)]

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
            cliHeader
            Rectangle().fill(shellBorder).frame(height: 1)

            if hasData {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        module01Revenue
                        module02OpEx
                        module03Profitability
                        module04Leverage
                        module05Returns
                    }
                    .padding(16)
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shellBg)
        .onChange(of: deal) { localDeal = deal }
    }

    // MARK: CLI Header

    private var cliHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(textTertiary)
            Text("profile --real-estate --asset=\"\(localDeal.propertyName.isEmpty ? "Untitled Deal" : localDeal.propertyName)\"")
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .foregroundStyle(accentRust)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(shellSurface)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 01 // CORE_FINANCIALS_REVENUE
    // ─────────────────────────────────────────────────────────────────────────

    private var module01Revenue: some View {
        TerminalBlock(command: "01 // CORE_FINANCIALS_REVENUE",
                      accentColor: accentRust,
                      contentPadding: 16) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
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
        TerminalBlock(command: "02 // EXPENSE_AUDIT_OPEX",
                      accentColor: accentRust,
                      contentPadding: 16) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
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
        TerminalBlock(command: "03 // PROFITABILITY_TELEMETRY",
                      accentColor: accentRust,
                      contentPadding: 16) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                MetricGridCell(label: "NOI",                      value: eur(metrics.netOperatingIncome))
                MetricGridCell(label: "EBITDA (est.)",            value: eur(metrics.ebitda))
                MetricGridCell(label: "Cap Rate",                 value: pct(metrics.capRate, dp: 2),         state: capRateState(metrics.capRate))
                MetricGridCell(label: "Cash Flow Before Tax",     value: eur(metrics.cashFlowBeforeTax),      state: metrics.cashFlowBeforeTax < 0 ? .danger : .neutral)
                MetricGridCell(label: "Cash Flow After Tax",      value: eur(metrics.cashFlowAfterTax),       state: metrics.cashFlowAfterTax < 0 ? .danger : .neutral)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 04 // LEVERAGE_ENGINE
    // ─────────────────────────────────────────────────────────────────────────

    private var module04Leverage: some View {
        TerminalBlock(command: "04 // LEVERAGE_ENGINE",
                      accentColor: accentRust,
                      contentPadding: 16) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
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
        TerminalBlock(command: "05 // RETURN_METRICS  [5yr hold]",
                      accentColor: accentRust,
                      contentPadding: 16) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                MetricGridCell(label: "Total Equity Invested",  value: eur(metrics.totalEquityInvested))
                MetricGridCell(label: "Cash-on-Cash Return",    value: pct(metrics.cashOnCashReturn, dp: 2),                                             state: cocState(metrics.cashOnCashReturn))
                MetricGridCell(label: "Equity Multiple (5Y)",  value: "\(metrics.equityMultiple5Y.formatted(.number.precision(.fractionLength(2))))x",  state: emState(metrics.equityMultiple5Y))
                MetricGridCell(label: "Unlevered IRR (est.)",  value: pct(metrics.unleveredIRR, dp: 1),                                                 state: irrState(metrics.unleveredIRR))
                MetricGridCell(label: "Levered IRR (est.)",    value: pct(metrics.leveredIRR, dp: 1),                                                   state: irrState(metrics.leveredIRR))
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Empty State
    // ─────────────────────────────────────────────────────────────────────────

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 8) {
                Text("porteos@system ~ % ls ./deals")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textTertiary)

                Text("No real estate data")
                    .font(.custom("JetBrains Mono", size: 14))
                    .foregroundStyle(textSecondary)

                Text("Click [ ./EDIT_DEAL ] to add financials")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textSecondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Shared Components
    // ─────────────────────────────────────────────────────────────────────────

    /// Elevated summary row for key totals (NOI, Total Revenue, Total OpEx, Levered IRR).
    /// Pass `state:` to apply semantic color to the value; defaults to text-primary.
    private func summaryRow(label: String, value: String, state: MetricState = .neutral) -> some View {
        let valueColor: Color = {
            switch state {
            case .optimal:          return Color(hex: "#10B981")
            case .warning:          return Color(hex: "#F59E0B")
            case .danger, .critical: return Color(hex: "#EF4444")
            default:                return textPrimary
            }
        }()

        return HStack(spacing: 0) {
            Text(label.uppercased())
                .font(.custom("JetBrains Mono", size: 9).weight(.light))
                .tracking(0.05)
                .foregroundStyle(Color(hex: "#475569"))

            Spacer()

            Text(value)
                .font(.custom("JetBrains Mono", size: 14).weight(.bold))
                .monospacedDigit()
                .tracking(-0.02)
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
    }


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Formatters
    // ─────────────────────────────────────────────────────────────────────────

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
    .background(Color(hex: "#0F1115"))
}

#Preview("Empty State") {
    let deal = PropertyDeal()
    return RealEstateDashboardView(deal: deal)
        .frame(width: 660, height: 400)
        .background(Color(hex: "#0F1115"))
}
