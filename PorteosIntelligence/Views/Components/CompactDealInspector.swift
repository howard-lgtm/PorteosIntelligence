import SwiftUI
import SwiftData

// MARK: - CompactDealInspector
// Simplified right-side inspector for independent profile windows.
// Shows score, key metrics, and an edit button. No WindowManager dependency.

struct CompactDealInspector: View {

    let deal: PropertyDeal
    @State private var showEditSheet = false

    // MARK: Derived

    private var vm: PropertyDealViewModel { PropertyDealViewModel(deal: deal) }

    private var score: PorteosScoreCalculator.PorteosMetrics { vm.porteosScore }

    private var dealName: String {
        deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName
    }

    private var location: String {
        let parts = [deal.locationCity, deal.locationCountry]
            .filter { !$0.isEmpty }
        return parts.isEmpty ? "—" : parts.joined(separator: ", ")
    }

    private var statusLabel: String { deal.status.rawValue.uppercased() }
    private var statusColor: Color  { deal.status.tokenColor }

    // Property type detection for metric routing
    private var isHospitality: Bool {
        deal.hospitalityRoomCount > 0 || deal.hospitalityADR > 0
    }
    private var isRural: Bool {
        let t = deal.propertyType.lowercased()
        return t.contains("farm") || t.contains("rural") || t.contains("quinta") || t.contains("agri")
    }
    private var isMultiDwelling: Bool {
        let t = deal.propertyType.lowercased()
        return t.contains("multi") || t.contains("apartment block") || t.contains("residential block")
    }

    // MARK: Tokens

    private var surface:     Color { DesignTokens.surfacePanel }
    private var border:      Color { DesignTokens.dividerStructural }
    private var textPrimary: Color { DesignTokens.textPrimary }
    private var textDim:     Color { DesignTokens.textDim }
    private var accentRust:  Color { DesignTokens.accentRust }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            inspectorHeader
            divider
            PorteosScoreBlock(metrics: score)
                .padding(.bottom, DesignTokens.blockGutter)
            divider
            metricsBlock
            divider
            editButton
            Spacer(minLength: 0)
        }
        .frame(width: DesignTokens.inspectorPaneWidth)
        .frame(maxHeight: .infinity)
        .background(surface)
        .clipShape(Rectangle())
        .sheet(isPresented: $showEditSheet) {
            FullDealEditSheet(deal: deal)
        }
    }

    // MARK: Header

    private var inspectorHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("// INSPECTOR")
                .porteosMeta()
                .foregroundStyle(textDim)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignTokens.blockGutter)
                .frame(height: DesignTokens.rowHeightHeader)

            divider

            VStack(alignment: .leading, spacing: 4) {
                Text(dealName)
                    .porteosRowValue()
                    .foregroundStyle(textPrimary)
                    .lineLimit(2)

                if !location.isEmpty && location != "—" {
                    Text(location)
                        .porteosMeta()
                        .foregroundStyle(textDim)
                }

                HStack(spacing: 4) {
                    Text("STATUS:")
                        .porteosMeta()
                        .foregroundStyle(textDim)
                    Text(statusLabel)
                        .porteosMeta()
                        .foregroundStyle(statusColor)
                }
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 10)
        }
    }

    // MARK: Metrics

    @ViewBuilder
    private var metricsBlock: some View {
        VStack(spacing: 0) {
            if isHospitality {
                hospitalityMetrics
            } else if isRural {
                ruralMetrics
            } else if isMultiDwelling {
                multiDwellingMetrics
            } else {
                commercialMetrics
            }
        }
    }

    private var commercialMetrics: some View {
        let re = vm.realEstateMetrics
        let sym = deal.currencySymbol
        let country = deal.locationCountry
        return Group {
            TerminalMetricRow(label: "Price",    value: formatCurrency(deal.purchasePrice, sym: sym),   state: .neutral)
            TerminalMetricRow(label: "Area",     value: UnitSystemService.shared.formatArea(deal.totalArea, country: country), state: .neutral)
            TerminalMetricRow(label: "Cap Rate", value: formatPct(re.capRate),   state: capRateState(re.capRate))
            TerminalMetricRow(label: "NOI",      value: formatCurrency(re.netOperatingIncome, sym: sym), state: .neutral)
            TerminalMetricRow(label: "DSCR",     value: formatDSCR(re.debtServiceCoverageRatio), state: dscrState(re.debtServiceCoverageRatio))
        }
    }

    private var hospitalityMetrics: some View {
        let h = vm.hospitalityMetrics
        let sym = deal.currencySymbol
        return Group {
            TerminalMetricRow(label: "ADR",       value: formatCurrency(deal.hospitalityADR, sym: sym), state: .neutral)
            TerminalMetricRow(label: "RevPAR",    value: formatCurrency(h.revPAR, sym: sym),           state: .neutral)
            TerminalMetricRow(label: "Occupancy", value: formatPct(deal.hospitalityOccupancyRate),      state: occupancyState(deal.hospitalityOccupancyRate))
            TerminalMetricRow(label: "GOP",       value: formatCurrency(h.gop, sym: sym),              state: .neutral)
        }
    }

    private var ruralMetrics: some View {
        let re = vm.realEstateMetrics
        let sym = deal.currencySymbol
        let country = deal.locationCountry
        return Group {
            TerminalMetricRow(label: "Price",     value: formatCurrency(deal.purchasePrice, sym: sym), state: .neutral)
            TerminalMetricRow(label: "Land Area", value: UnitSystemService.shared.formatArea(deal.landArea > 0 ? deal.landArea : deal.totalArea, country: country), state: .neutral)
            TerminalMetricRow(label: "Cap Rate",  value: formatPct(re.capRate), state: capRateState(re.capRate))
        }
    }

    private var multiDwellingMetrics: some View {
        let re = vm.realEstateMetrics
        let sym = deal.currencySymbol
        return Group {
            TerminalMetricRow(label: "Price",    value: formatCurrency(deal.purchasePrice, sym: sym), state: .neutral)
            TerminalMetricRow(label: "Units",    value: deal.maxBedroomsOrUnits > 0 ? "\(deal.maxBedroomsOrUnits)" : "—", state: .neutral)
            TerminalMetricRow(label: "Cap Rate", value: formatPct(re.capRate), state: capRateState(re.capRate))
            TerminalMetricRow(label: "NOI",      value: formatCurrency(re.netOperatingIncome, sym: sym), state: .neutral)
        }
    }

    // MARK: Edit Button

    private var editButton: some View {
        Button("[ EDIT DEAL DATA ]") { showEditSheet = true }
            .porteosButtonPrimary()
            .foregroundStyle(accentRust)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.rowHeightButton)
            .overlay(Rectangle().strokeBorder(accentRust.opacity(0.4), lineWidth: 1))
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 8)
            .buttonStyle(.plain)
    }

    // MARK: Divider

    private var divider: some View {
        Rectangle()
            .fill(border)
            .frame(height: 1)
    }

    // MARK: Formatting Helpers

    private func formatCurrency(_ value: Double, sym: String) -> String {
        guard value > 0 else { return "—" }
        let formatted = value.formatted(.number.precision(.fractionLength(0)))
        return "\(sym) \(formatted)"
    }

    private func formatPct(_ value: Double) -> String {
        guard value > 0 else { return "—" }
        return String(format: "%.2f%%", value)
    }

    private func formatDSCR(_ value: Double) -> String {
        guard value > 0 else { return "—" }
        return String(format: "%.2fx", value)
    }

    // MARK: Semantic State Helpers

    private func capRateState(_ v: Double) -> MetricState {
        if v <= 0 { return .neutral }
        if v >= 7 { return .optimal }
        if v >= 5 { return .neutral }
        return .warning
    }

    private func dscrState(_ v: Double) -> MetricState {
        if v <= 0 { return .neutral }
        if v >= 1.25 { return .optimal }
        if v >= 1.0  { return .warning }
        return .danger
    }

    private func occupancyState(_ v: Double) -> MetricState {
        if v <= 0   { return .neutral }
        if v >= 75  { return .optimal }
        if v >= 60  { return .warning }
        return .danger
    }
}
