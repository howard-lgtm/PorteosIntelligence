import SwiftUI

// MARK: - GlobalIntelligenceIdleInspector

struct GlobalIntelligenceIdleInspector: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text("// SELECT_PIN_OR_MARKET")
                    .porteosRowLabel()
                    .foregroundStyle(DesignTokens.textDim)
                Text("Tap a map pin for deal weights, or filter a market for aggregate KPIs.")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.surfacePanel)
    }
}

// MARK: - MarketContextInspector

struct MarketContextInspector: View {

    let marketId: String
    let deals: [PropertyDeal]

    private let accent = ProfileType.globalIntelligence.accentColor

    private var marketDeals: [PropertyDeal] {
        deals.filter { deal in
            if deal.marketId == marketId { return true }
            if let country = MarketFeedRegistry.countryId(for: marketId), deal.marketId == country { return true }
            if let parent = MarketFeedRegistry.market(id: deal.marketId)?.parentId, parent == marketId { return true }
            return false
        }
    }

    private var totalExposure: Double {
        marketDeals.reduce(0) { $0 + $1.purchasePrice }
    }

    private var geocodedCount: Int {
        marketDeals.filter(\.isGeocoded).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                inspectorHeader
                TerminalStructuralDivider()
                kpiRow("DEALS", "\(marketDeals.count)")
                kpiRow("ON_MAP", "\(geocodedCount)")
                kpiRow("EXPOSURE", formatCurrency(totalExposure))
                kpiRow("PRIME_YIELD", "// DATA_PENDING")
            }
            .padding(DesignTokens.blockGutter)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.surfacePanel)
    }

    private var inspectorHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("02 // MARKET_CONTEXT")
                .porteosModuleCmd()
                .foregroundStyle(accent)
            Text(MarketFeedRegistry.market(id: marketId)?.displayName ?? marketId)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textPrimary)
        }
        .padding(.bottom, 12)
    }

    private func kpiRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textDim)
            Spacer()
            Text(value)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(.vertical, 8)
    }

    private func formatCurrency(_ value: Double) -> String {
        guard value > 0 else { return "—" }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "€\(Int(value))"
    }
}
