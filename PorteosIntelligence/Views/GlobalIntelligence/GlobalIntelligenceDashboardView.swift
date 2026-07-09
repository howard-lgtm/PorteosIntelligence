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
            sectorFilter: wm.geoSectorFilter
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            dashboardHeader
            TerminalStructuralDivider()

            GeometryReader { geo in
                VStack(spacing: 0) {
                    mapSection
                        .frame(height: geo.size.height * 0.58)

                    TerminalStructuralDivider()

                    VStack(spacing: 0) {
                        if let deal = selectedDeal {
                            GeoAssetContextCard(deal: deal) {
                                wm.selectedDealID = nil
                            }
                            .padding(.horizontal, DesignTokens.blockGutter)
                            .padding(.top, 8)
                        }

                        MarketNewsFeedModule(
                            articles: visibleArticles,
                            marketFilterId: wm.geoMarketFilterId,
                            sectorFilter: wm.geoSectorFilter,
                            onMarketFilterChange: { wm.geoMarketFilterId = $0 },
                            onSectorFilterChange: { wm.geoSectorFilter = $0 }
                        )
                        .padding(DesignTokens.blockGutter)
                    }
                    .frame(height: geo.size.height * 0.42)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.canvasBase)
        .task { await refreshNews() }
        .onChange(of: wm.geoMarketFilterId) { _, _ in Task { await refreshNews() } }
    }

    private var dashboardHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@\(ProfileType.globalIntelligence.cliHost) ~ % ")
                .porteosCliPrompt()
                .foregroundStyle(DesignTokens.textDim)
            Text(ProfileType.globalIntelligence.commandLine)
                .porteosModuleCmd()
                .foregroundStyle(accent)
            Spacer()
            if news.isRefreshing {
                Text("// FETCHING_FEEDS")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
            } else {
                Button { Task { await refreshNews(force: true) } } label: {
                    Text("[ REFRESH ]")
                        .porteosMeta()
                        .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 10)
        .background(DesignTokens.surfacePanel)
    }

    private var mapSection: some View {
        TerminalBlock(command: "map --portfolio", accentColor: accent, contentPadding: 0) {
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
