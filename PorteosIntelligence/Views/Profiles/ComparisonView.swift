import SwiftUI

// MARK: - ComparisonMetric

private struct ComparisonMetric {
    let label: String
    let getValue: (PropertyDeal) -> Double?
    let format: (Double) -> String
    enum Direction { case higherBetter, lowerBetter, neutral }
    let direction: Direction
}

// MARK: - ComparisonView

struct ComparisonView: View {

    let deals: [PropertyDeal]
    /// Called when the user taps [ CLOSE ].
    var onDismiss: () -> Void = {}

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellElevated = Color(hex: "#23262E")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentRust    = Color(hex: "#C25E30")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")
    private let colorBest     = Color(hex: "#10B981")
    private let colorWorst    = Color(hex: "#EF4444")

    // MARK: Layout

    private let labelWidth:  CGFloat = 172
    private let dealWidth:   CGFloat = 160
    private let rowHeight:   CGFloat = 40

    // MARK: Metrics Definition

    private var metrics: [ComparisonMetric] { [
        .init(label: "PURCHASE PRICE",
              getValue: { $0.purchasePrice > 0 ? $0.purchasePrice : nil },
              format:   { eur($0) },
              direction: .neutral),

        .init(label: "GROSS POTENTIAL INCOME",
              getValue: { $0.grossPotentialIncome > 0 ? $0.grossPotentialIncome : nil },
              format:   { eur($0) },
              direction: .higherBetter),

        .init(label: "NOI",
              getValue: { reMetrics($0).netOperatingIncome.nonZero },
              format:   { eur($0) },
              direction: .higherBetter),

        .init(label: "CAP RATE",
              getValue: { reMetrics($0).capRate.nonZero },
              format:   { pct($0, dp: 2) },
              direction: .higherBetter),

        .init(label: "CASH FLOW BEFORE TAX",
              getValue: { deal in
                  let v = reMetrics(deal).cashFlowBeforeTax
                  return deal.grossPotentialIncome > 0 ? v : nil
              },
              format:   { eur($0) },
              direction: .higherBetter),

        .init(label: "LTV",
              getValue: { reMetrics($0).loanToValue.nonZero },
              format:   { pct($0, dp: 1) },
              direction: .lowerBetter),

        .init(label: "DSCR",
              getValue: { reMetrics($0).debtServiceCoverageRatio.nonZero },
              format:   { String(format: "%.2fx", $0) },
              direction: .higherBetter),

        .init(label: "PORTEOS SCORE",
              getValue: { $0.porteosScore },
              format:   { "\(Int($0.rounded())) / 100" },
              direction: .higherBetter),
    ] }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cliHeader
            Rectangle().fill(shellBorder).frame(height: 1)

            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    dealHeaders
                    Rectangle().fill(shellBorder).frame(height: 1)

                    ForEach(metrics.indices, id: \.self) { i in
                        metricRow(metrics[i])
                        Rectangle().fill(shellBorder).frame(height: 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shellBg)
    }

    // MARK: CLI Header

    private var cliHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(textTertiary)
            Text("deal --compare --assets=\(deals.count)")
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .foregroundStyle(accentRust)
            Spacer()
            Button { onDismiss() } label: {
                Text("[ CLOSE ]")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textTertiary)
                    .padding(.trailing, 16)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 16)
        .frame(height: 36)
        .background(shellSurface)
    }

    // MARK: Deal Header Row

    private var dealHeaders: some View {
        HStack(spacing: 0) {
            // Label column header
            Text("METRIC")
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .tracking(0.08)
                .foregroundStyle(textTertiary)
                .frame(width: labelWidth, alignment: .leading)
                .padding(.leading, 16)

            columnDivider

            ForEach(deals.indices, id: \.self) { i in
                let deal = deals[i]
                VStack(alignment: .leading, spacing: 3) {
                    Text(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)
                        .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                        .foregroundStyle(textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(deal.status.rawValue.uppercased())
                            .font(.custom("JetBrains Mono", size: 11))
                            .foregroundStyle(statusColor(deal.status))
                        if !deal.locationCity.isEmpty {
                            Text("· \(deal.locationCity)")
                                .font(.custom("JetBrains Mono", size: 11))
                                .foregroundStyle(textTertiary)
                        }
                    }
                }
                .frame(width: dealWidth, alignment: .leading)
                .padding(.horizontal, 12)

                if i < deals.count - 1 { columnDivider }
            }
        }
        .frame(height: 52)
        .background(shellSurface)
    }

    // MARK: Metric Row

    private func metricRow(_ metric: ComparisonMetric) -> some View {
        let values  = deals.map { metric.getValue($0) }
        let best    = bestIndex(values: values, direction: metric.direction)
        let worst   = worstIndex(values: values, direction: metric.direction)

        return HStack(spacing: 0) {
            // Label
            Text(metric.label)
                .font(.custom("JetBrains Mono", size: 13).weight(.regular))
                .tracking(0.02)
                .foregroundStyle(textTertiary)
                .frame(width: labelWidth, alignment: .leading)
                .padding(.leading, 16)

            columnDivider

            // Deal value cells
            ForEach(deals.indices, id: \.self) { i in
                let val   = values[i]
                let color = cellColor(
                    index:     i,
                    best:      best,
                    worst:     worst,
                    direction: metric.direction,
                    hasValue:  val != nil
                )

                HStack(spacing: 4) {
                    Spacer()
                    if let v = val {
                        Text(metric.format(v))
                            .font(.custom("JetBrains Mono", size: 17).weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(color)
                        // Best marker
                        if i == best && metric.direction != .neutral {
                            Circle()
                                .fill(colorBest)
                                .frame(width: 5, height: 5)
                        }
                    } else {
                        Text("—")
                            .font(.custom("JetBrains Mono", size: 17))
                            .foregroundStyle(textTertiary)
                    }
                }
                .frame(width: dealWidth)
                .padding(.horizontal, 12)

                if i < deals.count - 1 { columnDivider }
            }
        }
        .frame(height: rowHeight)
        .background(rowBg())
    }

    // Alternate row background for readability
    @State private var _rowCount = 0
    private func rowBg() -> Color {
        Color.clear  // uniform; border lines provide sufficient separation
    }

    // MARK: Value Color

    private func cellColor(
        index: Int, best: Int?, worst: Int?,
        direction: ComparisonMetric.Direction, hasValue: Bool
    ) -> Color {
        guard hasValue, direction != .neutral else { return textPrimary }
        if index == best  { return colorBest  }
        if index == worst { return colorWorst }
        return textPrimary
    }

    // MARK: Best / Worst Index

    private func bestIndex(values: [Double?], direction: ComparisonMetric.Direction) -> Int? {
        guard direction != .neutral else { return nil }
        let nonNil = values.enumerated().compactMap { i, v in v.map { (i, $0) } }
        guard nonNil.count >= 2 else { return nil }
        return direction == .higherBetter
            ? nonNil.max(by: { $0.1 < $1.1 })?.0
            : nonNil.min(by: { $0.1 < $1.1 })?.0
    }

    private func worstIndex(values: [Double?], direction: ComparisonMetric.Direction) -> Int? {
        guard direction != .neutral else { return nil }
        let nonNil = values.enumerated().compactMap { i, v in v.map { (i, $0) } }
        guard nonNil.count >= 2 else { return nil }
        return direction == .higherBetter
            ? nonNil.min(by: { $0.1 < $1.1 })?.0
            : nonNil.max(by: { $0.1 < $1.1 })?.0
    }

    // MARK: Column Divider

    private var columnDivider: some View {
        Rectangle()
            .fill(shellBorder)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
    }

    // MARK: Calculators

    private func reMetrics(_ d: PropertyDeal) -> RealEstateCalculator.FullMetrics {
        RealEstateCalculator.calculateFull(inputs: .init(
            grossPotentialIncome:   d.grossPotentialIncome,
            vacancyRate:            d.vacancyRate,
            otherIncome:            d.otherIncome,
            operatingExpenses:      d.operatingExpenses,
            opexPropertyManagement: d.opexPropertyManagement,
            opexPropertyTax:        d.opexPropertyTax,
            opexInsurance:          d.opexInsurance,
            opexUtilities:          d.opexUtilities,
            opexMaintenance:        d.opexMaintenance,
            opexCapitalReserves:    d.opexCapitalReserves,
            purchasePrice:          d.purchasePrice,
            closingCosts:           d.closingCosts,
            renovationBudget:       d.renovationBudget,
            loanAmount:             d.loanAmount,
            interestRate:           d.interestRate,
            amortizationMonths:     d.amortizationMonths,
            exitCapRate:            d.exitCapRate
        ))
    }

    // MARK: Formatters

    private func eur(_ v: Double) -> String {
        v.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }

    private func pct(_ v: Double, dp: Int = 1) -> String {
        "\(v.formatted(.number.precision(.fractionLength(dp))))%"
    }

    private func statusColor(_ s: DealStatus) -> Color {
        switch s {
        case .viable:   return Color(hex: "#10B981")
        case .review:   return Color(hex: "#F59E0B")
        case .rejected: return Color(hex: "#EF4444")
        case .acquired: return Color(hex: "#3B82F6")
        case .pipeline: return Color(hex: "#64748B")
        }
    }
}

// MARK: - Double Helper

private extension Double {
    /// Returns nil if the value is 0 (treat zero as "no data").
    var nonZero: Double? { self == 0 ? nil : self }
}

// MARK: - Preview

#Preview {
    let deals: [PropertyDeal] = [
        PropertyDeal(propertyName: "Lisbon Office A", purchasePrice: 2_400_000,
                     grossPotentialIncome: 210_000, vacancyRate: 5,
                     operatingExpenses: 72_000, loanAmount: 1_680_000,
                     interestRate: 4.25, amortizationMonths: 360,
                     porteosScore: 78, status: .viable),
        PropertyDeal(propertyName: "Porto Warehouse", purchasePrice: 875_000,
                     grossPotentialIncome: 95_000, vacancyRate: 8,
                     operatingExpenses: 38_000, loanAmount: 612_500,
                     interestRate: 4.75, amortizationMonths: 300,
                     porteosScore: 64, status: .review),
        PropertyDeal(propertyName: "Cascais Villa", purchasePrice: 2_100_000,
                     grossPotentialIncome: 168_000, vacancyRate: 6,
                     operatingExpenses: 58_000, loanAmount: 1_470_000,
                     interestRate: 4.5, amortizationMonths: 360,
                     porteosScore: 71, status: .pipeline),
    ]
    ComparisonView(deals: deals)
        .frame(width: 900, height: 700)
        .background(Color(hex: "#0F1115"))
}
