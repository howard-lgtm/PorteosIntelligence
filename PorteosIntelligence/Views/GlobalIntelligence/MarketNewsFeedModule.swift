import SwiftUI

// MARK: - MarketNewsFeedModule

struct MarketNewsFeedModule: View {

    let articles: [IntelNewsArticle]
    let marketFilterId: String?
    let sectorFilter: IntelSector?
    let windowDays: Int
    let lastRefresh: Date?
    let isRefreshing: Bool
    var onMarketFilterChange: (String?) -> Void
    var onSectorFilterChange: (IntelSector?) -> Void
    var onWindowDaysChange: (Int) -> Void
    var onRefresh: () -> Void

    @State private var expandedArticleID: String?

    private let accent = ProfileType.globalIntelligence.accentColor

    private static let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let refreshStamp: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    var body: some View {
        TerminalBlock(
            command: "02 // MARKET_NEWS_FEED",
            accentColor: accent,
            contentPadding: 0,
            headerActionLabel: isRefreshing ? "./refresh --news …" : "./refresh --news",
            onHeaderAction: onRefresh
        ) {
            VStack(alignment: .leading, spacing: 0) {
                filterBars
                    .padding(.horizontal, DesignTokens.blockGutter)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                TerminalStructuralDivider()
                feedBody
                refreshFooter
                    .padding(.horizontal, DesignTokens.blockGutter)
                    .padding(.bottom, 8)
            }
        }
    }

    @ViewBuilder
    private var feedBody: some View {
        if articles.isEmpty {
            Text(emptyStateMessage)
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textDim)
                .padding(.horizontal, DesignTokens.blockGutter)
                .padding(.vertical, 12)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(articles) { article in
                        newsRow(article)
                            .padding(.horizontal, DesignTokens.blockGutter)
                        TerminalStructuralDivider()
                    }
                }
            }
        }
    }

    private var emptyStateMessage: String {
        if sectorFilter != nil {
            return "// NO_SECTOR_HEADLINES — try ALL sector or refresh feeds"
        }
        if marketFilterId != nil {
            return "// NO_HEADLINES — tap ./refresh --news or widen window"
        }
        return "// NO_HEADLINES — tap ./refresh --news to fetch feeds"
    }

    private var filterBars: some View {
        VStack(alignment: .leading, spacing: 8) {
            marketFilterBar
            HStack(alignment: .top, spacing: 16) {
                windowFilterBar
                sectorFilterBar
            }
        }
    }

    private var marketFilterBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("MARKET")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    marketChip(label: "ALL", marketId: nil, isActive: marketFilterId == nil, hasFeeds: true)
                    ForEach(MarketFeedRegistry.countries) { country in
                        let hasFeeds = !country.rssFeeds.isEmpty
                        let label = country.id == marketFilterId
                            ? "\(country.displayName) *"
                            : country.id
                        marketChip(
                            label: label,
                            marketId: country.id,
                            isActive: marketFilterId == country.id,
                            hasFeeds: hasFeeds
                        )
                    }
                }
            }
        }
    }

    private var windowFilterBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("WINDOW")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            HStack(spacing: 6) {
                windowChip(days: 30)
                windowChip(days: 60)
            }
        }
    }

    private var sectorFilterBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SECTOR")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    sectorChip(label: "ALL", sector: nil, isActive: sectorFilter == nil)
                    ForEach(IntelSector.classificationOrder) { sector in
                        sectorChip(
                            label: sector.chipLabel,
                            sector: sector,
                            isActive: sectorFilter == sector
                        )
                    }
                }
            }
        }
    }

    private var refreshFooter: some View {
        HStack(spacing: 0) {
            if let lastRefresh {
                Text("Last refresh: \(Self.refreshStamp.string(from: lastRefresh)) UTC")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                Text(" · ")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
            }
            Text("\(articles.count) article\(articles.count == 1 ? "" : "s")")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            Spacer()
        }
        .padding(.top, 6)
    }

    private func marketChip(label: String, marketId: String?, isActive: Bool, hasFeeds: Bool = true) -> some View {
        Button { onMarketFilterChange(marketId) } label: {
            filterChipLabel(label, isActive: isActive, dimmed: !hasFeeds)
        }
        .buttonStyle(.plain)
        .help(hasFeeds ? "" : "No RSS feeds configured for this market")
    }

    private func windowChip(days: Int) -> some View {
        Button { onWindowDaysChange(days) } label: {
            filterChipLabel("\(days)d", isActive: windowDays == days)
        }
        .buttonStyle(.plain)
    }

    private func sectorChip(label: String, sector: IntelSector?, isActive: Bool) -> some View {
        Button { onSectorFilterChange(sector) } label: {
            filterChipLabel(label, isActive: isActive)
        }
        .buttonStyle(.plain)
    }

    private func filterChipLabel(_ label: String, isActive: Bool, dimmed: Bool = false) -> some View {
        Text("[ \(label) ]")
            .porteosMeta()
            .foregroundStyle(
                dimmed    ? DesignTokens.textDim.opacity(0.4) :
                isActive  ? accent : DesignTokens.textDim
            )
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isActive && !dimmed ? accent.opacity(0.12) : Color.clear)
            .overlay {
                if isActive && !dimmed {
                    Rectangle().strokeBorder(accent.opacity(0.5), lineWidth: 1)
                }
            }
    }

    private func newsRow(_ article: IntelNewsArticle) -> some View {
        let isExpanded = expandedArticleID == article.id
        let topicLabel = article.primarySector?.displayName ?? article.marketId
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(metadataLine(article, topic: topicLabel))
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                    Text(article.title)
                        .porteosRowValue()
                        .foregroundStyle(DesignTokens.textPrimary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Button {
                    expandedArticleID = isExpanded ? nil : article.id
                } label: {
                    Text(isExpanded ? "[ − ]" : "[ + ]")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                expandedBody(article)
            }
        }
        .padding(.vertical, 8)
    }

    private func metadataLine(_ article: IntelNewsArticle, topic: String) -> String {
        let date = Self.isoDate.string(from: article.pubDate)
        return "\(date) · \(article.sourceDisplayName) · \(topic)"
    }

    @ViewBuilder
    private func expandedBody(_ article: IntelNewsArticle) -> some View {
        let bodyText = article.summary.isEmpty ? article.title : article.summary
        Text(bodyText)
            .porteosMeta()
            .foregroundStyle(DesignTokens.textSecondary)
            .fixedSize(horizontal: false, vertical: true)

        if let url = URL(string: article.link), !article.link.isEmpty {
            Link(destination: url) {
                Text("open \(truncatedLink(article.link))")
                    .porteosMeta()
                    .foregroundStyle(accent)
                    .lineLimit(1)
            }
        }

        topicPills(for: article)
    }

    private func truncatedLink(_ link: String) -> String {
        let max = 48
        guard link.count > max else { return link }
        return String(link.prefix(max)) + "…"
    }

    @ViewBuilder
    private func topicPills(for article: IntelNewsArticle) -> some View {
        let pills = topicPillLabels(for: article)
        if !pills.isEmpty {
            HStack(spacing: 6) {
                ForEach(pills, id: \.self) { pill in
                    Text(pill)
                        .porteosMeta()
                        .foregroundStyle(accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay {
                            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1)
                        }
                }
            }
            .padding(.top, 2)
        }
    }

    private func topicPillLabels(for article: IntelNewsArticle) -> [String] {
        var labels: [String] = []
        if let market = MarketFeedRegistry.market(id: article.marketId) {
            labels.append(market.displayName.uppercased())
        } else {
            labels.append(article.marketId)
        }
        labels.append(contentsOf: article.sectorLabels.map { $0.uppercased() })
        return Array(Set(labels)).sorted()
    }
}
