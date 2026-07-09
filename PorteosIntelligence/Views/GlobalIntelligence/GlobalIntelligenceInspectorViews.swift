import SwiftData
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

// MARK: - GeocodeStatusInspector
// Figma frame 4 — inspector when deals lack coordinates.

struct GeocodeStatusInspector: View {

    @Environment(\.modelContext) private var modelContext

    let deals: [PropertyDeal]

    private let accent = ProfileType.globalIntelligence.accentColor

    private var locatable: [PropertyDeal] {
        deals.filter { !$0.locationCity.isEmpty || !$0.address.isEmpty }
    }

    private var geocodedCount: Int { locatable.filter(\.isGeocoded).count }
    private var pendingCount: Int {
        locatable.filter { !$0.isGeocoded && $0.geocodeStatus != .failed }.count
    }
    private var failedCount: Int { locatable.filter { $0.geocodeStatus == .failed }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("// GEOCODE_STATUS")
                        .porteosModuleCmd()
                        .foregroundStyle(accent)
                    Text("Portfolio coordinate health")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textSecondary)
                }
                .padding(.bottom, 12)

                TerminalStructuralDivider()
                kpiRow("GEOCODED", "\(geocodedCount) / \(locatable.count)")
                kpiRow("PENDING", "\(pendingCount)")
                kpiRow("FAILED", "\(failedCount)")

                if pendingCount > 0 || failedCount > 0 {
                    TerminalStructuralDivider()
                        .padding(.vertical, 12)
                    Button {
                        GeocodingService.shared.scheduleGeocodeAllPending(
                            deals: locatable.filter { $0.needsGeocode },
                            context: modelContext
                        )
                    } label: {
                        Text("[ RUN GEOCODE PASS ]")
                            .porteosMeta()
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DesignTokens.blockGutter)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.surfacePanel)
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
}
