import SwiftUI
import SwiftData

// MARK: - ComparisonMetric

private struct ComparisonMetric {
    let label: String
    let getValue: (PropertyDeal) -> Double?
    let format: (Double) -> String
    enum Direction { case higherBetter, lowerBetter, neutral }
    let direction: Direction
}

// MARK: - ComparisonView
// Figma img_00_12 — multi-deal metric table + OPEX breakdown.

struct ComparisonView: View {

    let deals: [PropertyDeal]
    var onDismiss: () -> Void = {}

    @Environment(\.modelContext) private var modelContext

    @State private var opexDraft: OpexDraft?
    @State private var opexBaseline: OpexDraft?

    private let labelWidth: CGFloat = 168
    private let dealWidth:  CGFloat = 148
    private let rowHeight:  CGFloat = DesignTokens.rowHeightHeader + 8

    /// Figma img_00_12 — OPEX block spans label column + first deal column.
    private var opexPanelWidth: CGFloat {
        labelWidth + DesignTokens.dividerWidth + dealWidth
    }

    private let opexValueFieldWidth: CGFloat = 104

    private var metrics: [ComparisonMetric] { [
        .init(label: "PURCHASE PRICE",
              getValue: { $0.purchasePrice > 0 ? $0.purchasePrice : nil },
              format: compactEur,
              direction: .lowerBetter),

        .init(label: "GROSS POTENTIAL INC",
              getValue: { $0.grossPotentialIncome > 0 ? $0.grossPotentialIncome : nil },
              format: compactEur,
              direction: .higherBetter),

        .init(label: "NOI",
              getValue: { reMetrics($0).netOperatingIncome.nonZero },
              format: compactEur,
              direction: .higherBetter),

        .init(label: "CAP RATE",
              getValue: { reMetrics($0).capRate.nonZero },
              format: { pct($0, dp: 1) },
              direction: .higherBetter),

        .init(label: "CASH FLOW BEFORE TAX",
              getValue: { deal in
                  let v = reMetrics(deal).cashFlowBeforeTax
                  return deal.grossPotentialIncome > 0 ? v : nil
              },
              format: compactEur,
              direction: .higherBetter),

        .init(label: "LTV",
              getValue: { reMetrics($0).loanToValue.nonZero },
              format: { pct($0, dp: 1) },
              direction: .lowerBetter),

        .init(label: "DSCR",
              getValue: { reMetrics($0).debtServiceCoverageRatio.nonZero },
              format: { String(format: "%.2fx", $0) },
              direction: .higherBetter),

        .init(label: "PORTEOS SCORE",
              getValue: { $0.porteosScore },
              format: { "\(Int($0.rounded())) / 100" },
              direction: .higherBetter),
    ] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cliHeader
            TerminalStructuralDivider()

            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    dealHeaders
                    TerminalStructuralDivider()

                    ForEach(metrics.indices, id: \.self) { i in
                        metricRow(metrics[i])
                        TerminalStructuralDivider()
                    }
                }
            }

            if opexDraft != nil {
                HStack(alignment: .top, spacing: 0) {
                    opexBreakdownPanel()
                        .frame(width: opexPanelWidth, alignment: .leading)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, DesignTokens.blockGutter)
                .padding(.vertical, 12)
                .background(DesignTokens.surfacePanel)
                .overlay(alignment: .top) { TerminalStructuralDivider() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.canvasBase)
        .onAppear { loadOpexDraft() }
        .onChange(of: deals.map(\.id)) { _, _ in loadOpexDraft() }
    }

    // MARK: Header

    private var cliHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .porteosCliPrompt()
                .foregroundStyle(DesignTokens.textDim)
            Text("deal --compare --assets=\(deals.count)")
                .porteosModuleCmd()
                .foregroundStyle(DesignTokens.accentRust)
            Spacer()
            Button { onDismiss() } label: {
                Text("[ CLOSE ]")
                    .porteosRowLabel()
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: Table

    private var dealHeaders: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: labelWidth)

            columnDivider

            ForEach(deals.indices, id: \.self) { i in
                let deal = deals[i]
                VStack(alignment: .leading, spacing: 2) {
                    Text(shortName(deal))
                        .porteosButtonPrimary()
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)
                    Text(deal.locationCity.isEmpty ? "—" : deal.locationCity)
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                }
                .frame(width: dealWidth, alignment: .leading)
                .padding(.horizontal, 10)

                if i < deals.count - 1 { columnDivider }
            }
        }
        .frame(height: 48)
        .background(DesignTokens.surfacePanel)
    }

    private func metricRow(_ metric: ComparisonMetric) -> some View {
        let values = deals.map { metric.getValue($0) }
        let best   = bestIndex(values: values, direction: metric.direction)
        let worst  = worstIndex(values: values, direction: metric.direction)

        return HStack(spacing: 0) {
            Text(metric.label)
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: labelWidth, alignment: .leading)
                .padding(.leading, DesignTokens.blockGutter)

            columnDivider

            ForEach(deals.indices, id: \.self) { i in
                let val   = values[i]
                let color = cellColor(index: i, best: best, worst: worst,
                                      direction: metric.direction, hasValue: val != nil)

                Text(val.map { metric.format($0) } ?? "—")
                    .porteosMetricValue()
                    .monospacedDigit()
                    .foregroundStyle(color)
                    .frame(width: dealWidth, alignment: .trailing)
                    .padding(.horizontal, 10)

                if i < deals.count - 1 { columnDivider }
            }
        }
        .frame(height: rowHeight)
        .background(DesignTokens.surfaceElevated.opacity(0.35))
    }

    // MARK: OPEX Panel

    private func opexBreakdownPanel() -> some View {
        let dealLabel = deals.first.map { shortName($0) } ?? "—"

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(DesignTokens.accentRust)
                    .frame(width: 2, height: 14)
                VStack(alignment: .leading, spacing: 2) {
                    Text("03 // OPEX BREAKDOWN")
                        .porteosModuleCmd()
                        .foregroundStyle(DesignTokens.textDim)
                    Text(dealLabel)
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(DesignTokens.surfacePanel)

            TerminalStructuralDivider()

            opexRow("PROPERTY MANAGEMENT", value: opexBinding(\.propertyManagement))
            opexInsetDivider
            opexRow("PROPERTY TAX", value: opexBinding(\.propertyTax))
            opexInsetDivider
            opexRow("INSURANCE", value: opexBinding(\.insurance))
            opexInsetDivider
            opexRow("UTILITIES", value: opexBinding(\.utilities))
            opexInsetDivider
            opexRow("MAINTENANCE", value: opexBinding(\.maintenance))
            opexInsetDivider
            opexRow("CAPITAL RESERVES", value: opexBinding(\.capitalReserves))

            TerminalStructuralDivider()

            HStack(spacing: 12) {
                Button { discardOpexChanges() } label: {
                    Text("[ DISCARD ]")
                        .porteosRowLabel()
                        .foregroundStyle(DesignTokens.textSecondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button { saveOpexChanges() } label: {
                    Text("[ SAVE CHANGES ]")
                }
                .buttonStyle(TerminalButtonStyle(color: .rust))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(DesignTokens.surfacePanel)
        }
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
    }

    private func opexBinding(_ keyPath: WritableKeyPath<OpexDraft, Double>) -> Binding<Double> {
        Binding(
            get: { opexDraft?[keyPath: keyPath] ?? 0 },
            set: { newValue in
                guard opexDraft != nil else { return }
                opexDraft![keyPath: keyPath] = newValue
            }
        )
    }

    private func opexRow(_ label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .lineLimit(1)
                .frame(maxWidth: opexPanelWidth - opexValueFieldWidth - 48, alignment: .leading)
            Spacer(minLength: 4)
            OpexInlineAmountField(value: value, fieldWidth: opexValueFieldWidth)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(minHeight: DesignTokens.rowHeightData)
        .background(DesignTokens.surfaceElevated)
    }

    private var opexInsetDivider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(height: DesignTokens.dividerWidth)
            .padding(.leading, 12)
    }

    // MARK: Helpers

    private var columnDivider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(width: DesignTokens.dividerWidth)
            .frame(maxHeight: .infinity)
    }

    private func shortName(_ deal: PropertyDeal) -> String {
        let name = deal.propertyName.isEmpty ? "UNTITLED" : deal.propertyName.uppercased()
        if name.count > 18 {
            return String(name.prefix(18))
        }
        return name
    }

    private func cellColor(
        index: Int, best: Int?, worst: Int?,
        direction: ComparisonMetric.Direction, hasValue: Bool
    ) -> Color {
        guard hasValue, direction != .neutral else { return DesignTokens.textPrimary }
        if index == best  { return DesignTokens.statusGo }
        if index == worst { return DesignTokens.statusCritical }
        return DesignTokens.textPrimary
    }

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

    private func loadOpexDraft() {
        guard let deal = deals.first else {
            opexDraft = nil
            opexBaseline = nil
            return
        }
        let draft = OpexDraft(deal: deal)
        opexDraft = draft
        opexBaseline = draft
    }

    private func discardOpexChanges() {
        opexDraft = opexBaseline
    }

    private func saveOpexChanges() {
        guard let deal = deals.first, let draft = opexDraft else { return }
        draft.apply(to: deal)
        deal.updatedAt = Date()
        try? modelContext.save()
        opexBaseline = draft
    }

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

    private func compactEur(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "€%.2fM", v / 1_000_000) }
        if v >= 1_000     { return String(format: "€%.1fk", v / 1_000) }
        return String(format: "€%.0f", v)
    }

    private func pct(_ v: Double, dp: Int = 1) -> String {
        "\(v.formatted(.number.precision(.fractionLength(dp))))%"
    }
}

// MARK: - OpexInlineAmountField
// String-backed € entry (same reliability pattern as TerminalInputField).

private struct OpexInlineAmountField: View {
    @Binding var value: Double
    let fieldWidth: CGFloat

    @State private var localText = ""

    var body: some View {
        HStack(spacing: 4) {
            Text("€")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            TextField("0", text: $localText)
                .textFieldStyle(.plain)
                .porteosRowValue()
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .frame(width: fieldWidth - 28)
                .onAppear { localText = displayString(for: value) }
                .onChange(of: localText) { _, newText in
                    value = parse(newText)
                }
                .onChange(of: value) { _, newValue in
                    guard abs(parse(localText) - newValue) > 0.001 else { return }
                    localText = displayString(for: newValue)
                }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(width: fieldWidth)
        .background(DesignTokens.canvasBase)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
    }

    private func parse(_ text: String) -> Double {
        let cleaned = text.filter { $0.isNumber || $0 == "." }
        return Double(cleaned) ?? 0
    }

    private func displayString(for value: Double) -> String {
        guard value != 0 else { return "" }
        if value.rounded() == value { return "\(Int(value))" }
        return String(format: "%.2f", value)
    }
}

// MARK: - OpexDraft

private struct OpexDraft: Equatable {
    var propertyManagement: Double
    var propertyTax: Double
    var insurance: Double
    var utilities: Double
    var maintenance: Double
    var capitalReserves: Double

    init(deal: PropertyDeal) {
        propertyManagement = deal.opexPropertyManagement
        propertyTax        = deal.opexPropertyTax
        insurance          = deal.opexInsurance
        utilities          = deal.opexUtilities
        maintenance        = deal.opexMaintenance
        capitalReserves    = deal.opexCapitalReserves
    }

    func apply(to deal: PropertyDeal) {
        deal.opexPropertyManagement = propertyManagement
        deal.opexPropertyTax        = propertyTax
        deal.opexInsurance          = insurance
        deal.opexUtilities          = utilities
        deal.opexMaintenance        = maintenance
        deal.opexCapitalReserves    = capitalReserves
    }
}

// MARK: - Double Helper

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}

// MARK: - Preview

#Preview {
    let deals: [PropertyDeal] = [
        PropertyDeal(propertyName: "Lisbon T2", locationCity: "Lisbon",
                     purchasePrice: 350_000, grossPotentialIncome: 18_000,
                     vacancyRate: 5, operatingExpenses: 4_000,
                     loanAmount: 262_500, interestRate: 4.5,
                     opexPropertyManagement: 2_400, opexPropertyTax: 2_000,
                     opexInsurance: 800, opexUtilities: 1_200,
                     opexMaintenance: 700, opexCapitalReserves: 400,
                     porteosScore: 82, status: .viable),
        PropertyDeal(propertyName: "Porto Historic", locationCity: "Porto",
                     purchasePrice: 280_000, grossPotentialIncome: 14_400,
                     vacancyRate: 5, operatingExpenses: 3_500,
                     loanAmount: 196_000, interestRate: 4.5,
                     porteosScore: 68, status: .review),
        PropertyDeal(propertyName: "Berlin Office", locationCity: "Berlin",
                     purchasePrice: 5_000_000, grossPotentialIncome: 300_000,
                     vacancyRate: 5, operatingExpenses: 80_000,
                     loanAmount: 3_500_000, interestRate: 4.0,
                     porteosScore: 74, status: .pipeline),
    ]
    ComparisonView(deals: deals)
        .frame(width: 720, height: 640)
        .background(DesignTokens.canvasBase)
}
