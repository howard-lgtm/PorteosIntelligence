import SwiftData
import SwiftUI

// MARK: - GlobalIntelligenceDashboardView
// Center pane: [ MAP ] / [ INTEL ] tab bar + respective content.

struct GlobalIntelligenceDashboardView: View {

    let deals: [PropertyDeal]

    private let wm   = WindowManager.shared
    private let news = NewsAggregatorService.shared
    private let accent = ProfileType.globalIntelligence.accentColor

    private var selectedDeal: PropertyDeal? {
        deals.first { $0.id == wm.selectedDealID }
    }

    private var selectedDealBinding: Binding<UUID?> {
        Binding(get: { wm.selectedDealID }, set: { wm.selectedDealID = $0 })
    }

    private var visibleArticles: [IntelNewsArticle] {
        news.articles(
            marketId: wm.geoMarketFilterId,
            dealMarketId: selectedDeal?.marketId,
            sectorFilter: wm.geoSectorFilter,
            withinDays: wm.geoNewsWindowDays
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            dashboardHeader
            TerminalStructuralDivider()
            giTabBar
            TerminalStructuralDivider()

            if wm.geoActiveTab == "map" {
                mapTabContent
            } else if wm.geoActiveTab == "comps" {
                CompsTabContent(deal: selectedDeal)
            } else {
                IntelBriefView(deals: deals, marketId: effectiveIntelMarketId)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.canvasBase)
        .task { await refreshNews() }
        // Refresh news whenever market chip OR selected deal changes
        .onChange(of: wm.geoMarketFilterId) { _, _ in Task { await refreshNews() } }
        .onChange(of: wm.selectedDealID)    { _, _ in Task { await refreshNews() } }
    }

    // MARK: - Tab Bar

    private var giTabBar: some View {
        HStack(spacing: 0) {
            tabButton(label: "[ MAP ]",   id: "map")
            tabButton(label: "[ INTEL ]", id: "intel")
            tabButton(label: "[ COMPS ]", id: "comps")
            Spacer()
            if wm.geoActiveTab == "map" {
                Text(giModeLabel)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .padding(.trailing, DesignTokens.blockGutter)
            }
        }
        .frame(height: 32)
        .background(DesignTokens.surfacePanel)
    }

    private func tabButton(label: String, id: String) -> some View {
        let isActive = wm.geoActiveTab == id
        return Button { wm.geoActiveTab = id } label: {
            VStack(spacing: 0) {
                Spacer()
                Text(label)
                    .porteosMeta()
                    .foregroundStyle(isActive ? DesignTokens.textPrimary : DesignTokens.textDim)
                    .padding(.horizontal, 10)
                Spacer()
                Rectangle()
                    .fill(isActive ? accent : Color.clear)
                    .frame(height: 2)
            }
            .frame(height: 32)
        }
        .buttonStyle(.plain)
    }

    // MARK: - MAP tab

    private var mapTabContent: some View {
        GeometryReader { geo in
            let mapShare: CGFloat = selectedDeal == nil ? 0.58 : 0.52
            VStack(spacing: 0) {
                mapSection
                    .frame(height: geo.size.height * mapShare)

                TerminalStructuralDivider()

                VStack(spacing: 0) {
                    if let deal = selectedDeal {
                        GeoAssetContextCard(deal: deal) { wm.selectedDealID = nil }
                            .padding(.horizontal, DesignTokens.blockGutter)
                            .padding(.top, 6)
                            .padding(.bottom, 4)
                    }

                    MarketNewsFeedModule(
                        articles: visibleArticles,
                        marketFilterId: wm.geoMarketFilterId,
                        sectorFilter: wm.geoSectorFilter,
                        windowDays: wm.geoNewsWindowDays,
                        lastRefresh: news.lastRefresh,
                        isRefreshing: news.isRefreshing,
                        onMarketFilterChange: { wm.geoMarketFilterId = $0 },
                        onSectorFilterChange: { wm.geoSectorFilter = $0 },
                        onWindowDaysChange: { wm.geoNewsWindowDays = $0 },
                        onRefresh: { Task { await refreshNews(force: true) } }
                    )
                    .padding(DesignTokens.blockGutter)
                }
                .frame(height: geo.size.height * (1 - mapShare))
            }
        }
    }

    private var mapBlockCommand: String {
        if let market = wm.geoMarketFilterId,
           let name = MarketFeedRegistry.market(id: market)?.displayName {
            return "01 // GEO_PORTFOLIO_MAP > \(name.uppercased())"
        }
        return "01 // GEO_PORTFOLIO_MAP"
    }

    private var mapSection: some View {
        TerminalBlock(command: mapBlockCommand, accentColor: accent, contentPadding: 0) {
            GeoPortfolioMapView(
                deals: deals,
                marketFilterId: wm.geoMarketFilterId,
                selectedDealID: selectedDealBinding
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(DesignTokens.blockGutter)
    }

    // MARK: - Header

    /// Effective market for the INTEL tab.
    /// Priority: explicit chip selection → selected deal's country → portfolio majority country.
    private var effectiveIntelMarketId: String? {
        if let chip = wm.geoMarketFilterId { return chip }
        if let deal = selectedDeal, !deal.marketId.isEmpty {
            return MarketFeedRegistry.countryId(for: deal.marketId)
        }
        // Fall back to the most common portfolio country
        let countries = deals.compactMap { MarketFeedRegistry.countryId(for: $0.marketId) }
        return Dictionary(grouping: countries, by: { $0 })
            .max(by: { $0.value.count < $1.value.count })?.key
    }

    private var giModeLabel: String {
        if selectedDeal != nil { return "// PIN" }
        if let market = wm.geoMarketFilterId { return "// MARKET:\(market)" }
        if deals.contains(where: { !$0.isGeocoded && (!$0.locationCity.isEmpty || !$0.address.isEmpty) }) {
            return "// GEOCODE"
        }
        return "// IDLE"
    }

    private var geoHeaderCommand: String {
        if let deal = selectedDeal {
            let name = deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName
            return "intel --asset=\"\(name)\""
        }
        return ProfileType.geoCommandLine(marketId: wm.geoMarketFilterId)
    }

    private var dashboardHeader: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("porteos@\(ProfileType.globalIntelligence.cliHost) ~ % ")
                    .porteosCliPrompt()
                    .foregroundStyle(DesignTokens.textDim)
                Text(geoHeaderCommand)
                    .porteosModuleCmd()
                    .foregroundStyle(accent)
            }
            .lineLimit(1)
            .truncationMode(.tail)
            .layoutPriority(0)

            Spacer(minLength: 12)

            if news.isRefreshing {
                Text("// FETCHING_FEEDS")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .fixedSize()
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 8)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: - News refresh

    private func refreshNews(force: Bool = false) async {
        var marketIds = MarketFeedRegistry.countryIds
        if let filter = wm.geoMarketFilterId { marketIds.append(filter) }
        if let dealMarket = selectedDeal?.marketId, !dealMarket.isEmpty { marketIds.append(dealMarket) }
        if force {
            await news.refresh(marketIds: marketIds)
        } else {
            await news.refreshIfNeeded(marketIds: marketIds)
        }
    }
}
