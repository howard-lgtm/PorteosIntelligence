import SwiftUI

// MARK: - MarketNewsFeedModule

struct MarketNewsFeedModule: View {

    let articles: [IntelNewsArticle]
    let marketFilterId: String?
    let sectorFilter: IntelSector?
    var onMarketFilterChange: (String?) -> Void
    var onSectorFilterChange: (IntelSector?) -> Void

    @State private var expandedIDs: Set<String> = []

    private let accent = ProfileType.globalIntelligence.accentColor

    var body: some View {
        TerminalBlock(command: "feed --market-news --sectors", accentColor: accent) {
            VStack(alignment: .leading, spacing: 0) {
                marketFilterBar
                    .padding(.bottom, 6)
                sectorFilterBar
                    .padding(.bottom, 8)
                TerminalStructuralDivider()
                    .padding(.vertical, 8)

                if articles.isEmpty {
                    Text("// NO_SECTOR_HEADLINES — widen filter or refresh feeds")
                        .porteosRowLabel()
                        .foregroundStyle(DesignTokens.textDim)
                        .padding(.vertical, 12)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(articles) { article in
                                newsRow(article)
                                TerminalStructuralDivider()
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var marketFilterBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("MARKET")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    marketChip(label: "ALL", marketId: nil, isActive: marketFilterId == nil)
                    ForEach(MarketFeedRegistry.countries) { country in
                        marketChip(label: country.id, marketId: country.id, isActive: marketFilterId == country.id)
                    }
                }
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

    private func marketChip(label: String, marketId: String?, isActive: Bool) -> some View {
        Button { onMarketFilterChange(marketId) } label: {
            filterChipLabel(label, isActive: isActive)
        }
        .buttonStyle(.plain)
    }

    private func sectorChip(label: String, sector: IntelSector?, isActive: Bool) -> some View {
        Button { onSectorFilterChange(sector) } label: {
            filterChipLabel(label, isActive: isActive)
        }
        .buttonStyle(.plain)
    }

    private func filterChipLabel(_ label: String, isActive: Bool) -> some View {
        Text("[ \(label) ]")
            .porteosMeta()
            .foregroundStyle(isActive ? accent : DesignTokens.textDim)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isActive ? accent.opacity(0.12) : Color.clear)
            .overlay {
                if isActive {
                    Rectangle().strokeBorder(accent.opacity(0.5), lineWidth: 1)
                }
            }
    }

    private func newsRow(_ article: IntelNewsArticle) -> some View {
        let isExpanded = expandedIDs.contains(article.id)
        return VStack(alignment: .leading, spacing: 4) {
            Button {
                if isExpanded { expandedIDs.remove(article.id) }
                else { expandedIDs.insert(article.id) }
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    Text(isExpanded ? "[ − ]" : "[ + ]")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(article.title)
                            .porteosRowValue()
                            .foregroundStyle(DesignTokens.textPrimary)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: 8) {
                            if let primary = article.primarySector {
                                Text(primary.chipLabel)
                                    .porteosMeta()
                                    .foregroundStyle(accent)
                            }
                            Text(article.marketId)
                                .porteosMeta()
                                .foregroundStyle(DesignTokens.textSecondary)
                            Text(article.pubDate, style: .date)
                                .porteosMeta()
                                .foregroundStyle(DesignTokens.textDim)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                if article.sectorLabels.count > 1 {
                    Text(article.sectorLabels.joined(separator: " · "))
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textSecondary)
                        .padding(.leading, 28)
                }
                if let url = URL(string: article.link), !article.link.isEmpty {
                    Link(destination: url) {
                        Text(article.link)
                            .porteosMeta()
                            .foregroundStyle(accent)
                            .lineLimit(2)
                            .padding(.leading, 28)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
