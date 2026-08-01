import Foundation
import Observation

// MARK: - IntelNewsArticle

struct IntelNewsArticle: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let summary: String
    let link: String
    let pubDate: Date
    let marketId: String
    let sourceFeed: String
    let topics: [String]

    var sectorLabels: [String] {
        topics.compactMap { IntelSector(rawValue: $0)?.displayName }
    }

    var topicLabels: [String] { sectorLabels }

    var primarySector: IntelSector? {
        topics.compactMap { IntelSector(rawValue: $0) }.first
    }

    var sourceDisplayName: String {
        Self.displayName(forFeed: sourceFeed)
    }

    /// Human-readable publisher label from feed URL host.
    static func displayName(forFeed urlString: String) -> String {
        guard let host = URL(string: urlString)?.host?
            .replacingOccurrences(of: "www.", with: "") else {
            return "RSS"
        }
        let known: [String: String] = [
            "jornaldenegocios.pt": "Jornal de Negócios",
            "publico.pt": "Público",
            "feeds.elpais.com": "El País",
            "elpais.com": "El País",
            "feeds.bbci.co.uk": "BBC",
            "bbc.co.uk": "BBC",
            "lemonde.fr": "Le Monde",
            "repubblica.it": "La Repubblica",
            "di.se": "Dagens Industri",
            "feeds.a.dj.com": "WSJ",
            "japantimes.co.jp": "Japan Times",
            "ecb.europa.eu": "ECB",
            "feeds.feedburner.com": "Euronews",
        ]
        if let name = known[host] { return name }
        if let name = known.first(where: { host.hasSuffix($0.key) })?.value { return name }
        let stem = host.split(separator: ".").first.map(String.init) ?? host
        return stem.prefix(1).uppercased() + stem.dropFirst()
    }

    enum CodingKeys: String, CodingKey {
        case id, title, summary, link, pubDate, marketId, sourceFeed, topics
    }

    init(
        id: String,
        title: String,
        summary: String = "",
        link: String,
        pubDate: Date,
        marketId: String,
        sourceFeed: String,
        topics: [String]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.link = link
        self.pubDate = pubDate
        self.marketId = marketId
        self.sourceFeed = sourceFeed
        self.topics = topics
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        summary = try c.decodeIfPresent(String.self, forKey: .summary) ?? ""
        link = try c.decode(String.self, forKey: .link)
        pubDate = try c.decode(Date.self, forKey: .pubDate)
        marketId = try c.decode(String.self, forKey: .marketId)
        sourceFeed = try c.decode(String.self, forKey: .sourceFeed)
        topics = try c.decode([String].self, forKey: .topics)
    }
}

// MARK: - NewsAggregatorService
// Daily RSS fetch with JSON disk cache; filters to 30–60-day window.

@Observable
@MainActor
final class NewsAggregatorService {

    static let shared = NewsAggregatorService()

    private(set) var articles: [IntelNewsArticle] = []
    private(set) var isRefreshing = false
    private(set) var lastRefresh: Date?

    private let cacheFileName = "intel_news_cache.json"
    private let refreshInterval: TimeInterval = 86_400
    private let retentionDays = 60

    private init() {
        loadCache()
        pruneStale()
    }

    func articles(
        marketId: String?,
        dealMarketId: String?,
        sectorFilter: IntelSector? = nil,
        withinDays: Int = 60
    ) -> [IntelNewsArticle] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -withinDays, to: Date()) ?? .distantPast
        return articles
            .filter { $0.pubDate >= cutoff }
            .filter { matchesMarket($0, filter: marketId, dealMarketId: dealMarketId) }
            .filter { matchesSector($0, filter: sectorFilter) }
            .sorted { $0.pubDate > $1.pubDate }
    }

    func refreshIfNeeded(marketIds: [String]) async {
        if let last = lastRefresh, Date().timeIntervalSince(last) < refreshInterval { return }
        await refresh(marketIds: marketIds)
    }

    func refresh(marketIds: [String]) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        var fetched: [IntelNewsArticle] = []
        let uniqueMarkets = Array(Set(marketIds)).filter { !$0.isEmpty }

        for marketId in uniqueMarkets {
            let urls = MarketFeedRegistry.feedURLs(for: marketId)
            for urlString in urls {
                guard let url = URL(string: urlString) else { continue }
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    fetched.append(contentsOf: RSSFeedParser.parse(data: data, marketId: marketId, feedURL: urlString))
                } catch {
                    print("[NewsAggregator] feed failed \(urlString): \(error.localizedDescription)")
                }
            }
        }

        if !fetched.isEmpty {
            merge(fetched)
            lastRefresh = Date()
            saveCache()
        } else if lastRefresh == nil {
            lastRefresh = Date()
        }
    }

    // MARK: - Private

    private func matchesSector(_ article: IntelNewsArticle, filter: IntelSector?) -> Bool {
        guard let filter else { return true }
        return article.topics.contains(filter.rawValue)
    }

    private func matchesMarket(_ article: IntelNewsArticle, filter: String?, dealMarketId: String?) -> Bool {
        if let dealMarketId, !dealMarketId.isEmpty {
            if article.marketId == dealMarketId { return true }
            if let country = MarketFeedRegistry.countryId(for: dealMarketId), article.marketId == country { return true }
            return false
        }
        guard let filter, !filter.isEmpty else { return true }
        if article.marketId == filter { return true }
        if let country = MarketFeedRegistry.countryId(for: filter), article.marketId == country { return true }
        if let parent = MarketFeedRegistry.market(id: filter)?.parentId, article.marketId == parent { return true }
        return false
    }

    private func merge(_ incoming: [IntelNewsArticle]) {
        var byID = Dictionary(uniqueKeysWithValues: articles.map { ($0.id, $0) })
        for item in incoming { byID[item.id] = item }
        articles = Array(byID.values)
        pruneStale()
    }

    private func pruneStale() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? .distantPast
        articles = articles.filter { $0.pubDate >= cutoff }
    }

    private var cacheURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("PorteosIntelligence", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(cacheFileName)
    }

    private struct CachePayload: Codable {
        let lastRefresh: Date?
        let articles: [IntelNewsArticle]
    }

    private func loadCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let payload = try? JSONDecoder().decode(CachePayload.self, from: data) else { return }
        articles = payload.articles.map { retagIfNeeded($0) }
        lastRefresh = payload.lastRefresh
    }

    /// Re-classify cached headlines when sector taxonomy changes.
    private func retagIfNeeded(_ article: IntelNewsArticle) -> IntelNewsArticle {
        let sectors = MarketFeedRegistry.sectors(in: "\(article.title) \(article.summary)")
        let raw = sectors.isEmpty
            ? [IntelSector.adjacent.rawValue]
            : sectors.map(\.rawValue)
        guard raw != article.topics else { return article }
        return IntelNewsArticle(
            id: article.id,
            title: article.title,
            summary: article.summary,
            link: article.link,
            pubDate: article.pubDate,
            marketId: article.marketId,
            sourceFeed: article.sourceFeed,
            topics: raw
        )
    }

    private func saveCache() {
        let payload = CachePayload(lastRefresh: lastRefresh, articles: articles)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}

// MARK: - RSSFeedParser

private enum RSSFeedParser {

    static func parse(data: Data, marketId: String, feedURL: String) -> [IntelNewsArticle] {
        let delegate = RSSParserDelegate(marketId: marketId, feedURL: feedURL)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.items
    }
}

private final class RSSParserDelegate: NSObject, XMLParserDelegate {

    let marketId: String
    let feedURL: String
    private(set) var items: [IntelNewsArticle] = []

    private var inItem = false
    private var currentTitle = ""
    private var currentSummary = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var elementStack: [String] = []

    init(marketId: String, feedURL: String) {
        self.marketId = marketId
        self.feedURL = feedURL
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        let name = elementName.lowercased()
        elementStack.append(name)
        if name == "item" || name == "entry" {
            inItem = true
            currentTitle = ""
            currentSummary = ""
            currentLink = attributeDict["href"] ?? attributeDict["url"] ?? ""
            currentPubDate = ""
        }
        if inItem && name == "link" && currentLink.isEmpty {
            currentLink = attributeDict["href"] ?? ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard inItem, let current = elementStack.last else { return }
        switch current {
        case "title":     currentTitle += string
        case "link":      if currentLink.isEmpty { currentLink += string }
        case "pubdate", "published", "updated": currentPubDate += string
        case "description", "summary", "content":
            currentSummary += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        let name = elementName.lowercased()
        if name == "item" || name == "entry" {
            let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let link  = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else {
                inItem = false
                _ = elementStack.popLast()
                return
            }
            let summary = RSSHTMLStripper.plainText(from: currentSummary)
            // Undated articles get .distantPast — they sort to the bottom and
            // fail the 30/60d window rather than falsely appearing as "just now".
            let pub = RSSDateParser.parse(currentPubDate) ?? .distantPast
            let sectors = MarketFeedRegistry.sectors(in: "\(title) \(summary)")
            let topics = sectors.isEmpty
                ? [IntelSector.adjacent.rawValue]
                : sectors.map(\.rawValue)
            let id = "\(feedURL)|\(link)|\(title)".data(using: .utf8).map { $0.base64EncodedString() } ?? UUID().uuidString
            items.append(IntelNewsArticle(
                id: id, title: title, summary: summary, link: link, pubDate: pub,
                marketId: marketId, sourceFeed: feedURL, topics: topics
            ))
            inItem = false
        }
        if !elementStack.isEmpty { _ = elementStack.popLast() }
    }
}

private enum RSSHTMLStripper {

    static func plainText(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return trimmed
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum RSSDateParser {

    private static let rfc822: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f
    }()

    static func parse(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let d = ISO8601DateFormatter().date(from: trimmed) { return d }
        if let d = rfc822.date(from: trimmed) { return d }
        return nil
    }
}
