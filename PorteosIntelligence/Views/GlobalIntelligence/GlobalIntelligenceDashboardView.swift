import SwiftData
import SwiftUI

// MARK: - GlobalIntelligenceDashboardView
// Center pane: map 60% + market news 40% (Profile 6).

struct GlobalIntelligenceDashboardView: View {

    @Environment(\.modelContext) private var modelContext

    let deals: [PropertyDeal]

    private let wm = WindowManager.shared
    private let news = NewsAggregatorService.shared
    private let accent = ProfileType.globalIntelligence.accentColor

    private var selectedDeal: PropertyDeal? {
        deals.first { $0.id == wm.selectedDealID }
    }

    private var marketFilterBinding: Binding<String?> {
        Binding(
            get: { wm.geoMarketFilterId },
            set: { wm.geoMarketFilterId = $0 }
        )
    }

    private var selectedDealBinding: Binding<UUID?> {
        Binding(
            get: { wm.selectedDealID },
            set: { wm.selectedDealID = $0 }
        )
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

            GeometryReader { geo in
                let mapShare = selectedDeal == nil ? 0.58 : 0.52
                VStack(spacing: 0) {
                    mapSection
                        .frame(height: geo.size.height * mapShare)

                    TerminalStructuralDivider()

                    VStack(spacing: 0) {
                        if let deal = selectedDeal {
                            GeoAssetContextCard(deal: deal) {
                                wm.selectedDealID = nil
                            }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.canvasBase)
        .task { await refreshNews() }
        .onChange(of: wm.geoMarketFilterId) { _, _ in Task { await refreshNews() } }
    }

    private var giModeLabel: String {
        if selectedDeal != nil { return "// PIN" }
        if let market = wm.geoMarketFilterId { return "// MARKET:\(market)" }
        if deals.contains(where: { !$0.isGeocoded && (!$0.locationCity.isEmpty || !$0.address.isEmpty) }) {
            return "// GEOCODE"
        }
        return "// IDLE"
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

            HStack(spacing: 12) {
                Text(giModeLabel)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                if news.isRefreshing {
                    Text("// FETCHING_FEEDS")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 8)
        .background(DesignTokens.surfacePanel)
    }

    private var geoHeaderCommand: String {
        if let deal = selectedDeal {
            let name = deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName
            return "intel --asset=\"\(name)\""
        }
        return ProfileType.geoCommandLine(marketId: wm.geoMarketFilterId)
    }

    private var mapSection: some View {
        TerminalBlock(command: "01 // GEO_PORTFOLIO_MAP", accentColor: accent, contentPadding: 0) {
            GeoPortfolioMapView(
                deals: deals,
                marketFilterId: wm.geoMarketFilterId,
                selectedDealID: selectedDealBinding
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(DesignTokens.blockGutter)
    }

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
