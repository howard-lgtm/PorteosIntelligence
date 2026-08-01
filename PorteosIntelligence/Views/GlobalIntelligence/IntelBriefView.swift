import Foundation
import SwiftUI

// MARK: - IntelBriefView
// Figma frame 6, Variant A — 03 // DAILY_INTEL_BRIEF + 04 // MARKET_SIGNALS.

struct IntelBriefView: View {

    let deals: [PropertyDeal]
    let marketId: String?

    @State private var briefState: BriefState = .idle
    @State private var signals: [IntelSignal] = []
    @State private var errorMessage: String = ""

    private let accent = ProfileType.globalIntelligence.accentColor
    private let news   = NewsAggregatorService.shared

    var body: some View {
        HStack(spacing: 0) {
            briefColumn
            TerminalStructuralDivider()
            signalsColumn
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.canvasBase)
        .task { await generateIfStale() }
        .onChange(of: marketId ?? "") { _, _ in
            briefState = .idle
            Task { await generateIfStale() }
        }
    }

    // MARK: - Brief column

    private var briefColumn: some View {
        TerminalBlock(command: briefCommand, accentColor: accent) {
            VStack(alignment: .leading, spacing: 0) {
                switch briefState {
                case .idle:
                    Text("// INITIALISING …")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)

                case .generating:
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.6).tint(accent)
                        Text("// SCANNING MARKET …")
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textDim)
                    }

                case .ready:
                    briefSignalList

                case .offline:
                    offlineFallback

                case .error:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("// BRIEF_ERROR")
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.statusWarn)
                        Text(errorMessage)
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        regenerateButton
                    }
                }

                Spacer(minLength: 0)
                TerminalStructuralDivider().padding(.vertical, 10)

                HStack {
                    Text("// LOCAL LLM · NO DATA LEAVES DEVICE")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                    Spacer()
                    regenerateButton
                }
            }
        }
        .padding(DesignTokens.blockGutter)
        .frame(maxWidth: .infinity)
    }

    private var briefCommand: String {
        let month = Calendar.current.component(.month, from: Date())
        let year  = Calendar.current.component(.year,  from: Date())
        return "03 // DAILY_INTEL_BRIEF [\(year)-\(String(format: "%02d", month))]"
    }

    private var briefSignalList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Context header — shows data basis
                let mktName = marketId.flatMap { MarketFeedRegistry.market(id: $0)?.displayName } ?? "Global"
                Text("// \(articles.count) articles · \(mktName) · last 60d")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .padding(.bottom, 10)

                ForEach(Array(signals.enumerated()), id: \.offset) { idx, signal in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 8) {
                            Text(">")
                                .porteosMeta()
                                .foregroundStyle(accent)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("SIGNAL \(String(format: "%02d", idx + 1))")
                                    .porteosMeta()
                                    .foregroundStyle(accent)
                                Text(signal.text)
                                    .porteosMeta()
                                    .foregroundStyle(DesignTokens.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }
                        }

                        // Source attribution — matched post-hoc by word overlap
                        if let article = signal.sourceArticle {
                            HStack(spacing: 6) {
                                Rectangle()
                                    .fill(accent.opacity(0.3))
                                    .frame(width: 2)
                                    .frame(height: 12)
                                Text("\(article.sourceDisplayName) · \(article.marketId) · \(pubDateStr(article.pubDate))")
                                    .porteosMeta()
                                    .foregroundStyle(DesignTokens.textDim)
                                    .font(.system(size: 9, design: .monospaced))
                                if let url = URL(string: article.link), !article.link.isEmpty {
                                    Link("[ ↗ ]", destination: url)
                                        .porteosMeta()
                                        .foregroundStyle(accent)
                                        .font(.system(size: 9, design: .monospaced))
                                }
                            }
                            .padding(.leading, 20)
                        } else {
                            Text("// general market inference")
                                .porteosMeta()
                                .foregroundStyle(DesignTokens.textDim)
                                .font(.system(size: 9, design: .monospaced))
                                .padding(.leading, 20)
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_GB")
        return f
    }()

    private func pubDateStr(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    private var offlineFallback: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("// AGENT_OFFLINE")
                .porteosMeta().foregroundStyle(DesignTokens.statusWarn)
            Text("Local model not running. Start Ollama: ollama serve")
                .porteosMeta().foregroundStyle(DesignTokens.textSecondary)
            HStack(spacing: 8) {
                regenerateButton
                Button { briefState = .offline } label: {
                    Text("[ DISMISS ]").porteosMeta().foregroundStyle(DesignTokens.textDim)
                }.buttonStyle(.plain)
            }.padding(.top, 4)
        }
    }

    private var regenerateButton: some View {
        Button {
            Task { await generate() }
        } label: {
            Text(briefState == .generating ? "[ … ]" : "[ REGENERATE ]")
                .porteosMeta().foregroundStyle(accent)
        }
        .buttonStyle(.plain)
        .disabled(briefState == .generating)
    }

    // MARK: - Signals column

    private var signalsColumn: some View {
        TerminalBlock(command: "04 // MARKET_SIGNALS", accentColor: accent) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(marketSignalCards) { card in signalCard(card) }
                Spacer(minLength: 0)
            }
        }
        .padding(DesignTokens.blockGutter)
        .frame(maxWidth: 280)
    }

    private func signalCard(_ card: MarketSignalCard) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(card.rating)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(card.ratingColor)
            Text(card.label)
                .porteosMeta().foregroundStyle(DesignTokens.textDim)
            Text(card.sublabel)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .font(.system(size: 9, design: .monospaced))
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.surfacePanel)
        .overlay { Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1) }
    }

    // MARK: - Signal derivation from cached news

    private var articles: [IntelNewsArticle] {
        news.articles(marketId: marketId, dealMarketId: nil, withinDays: 60)
    }

    private var marketSignalCards: [MarketSignalCard] {
        let regCount     = articles.filter {
            $0.topics.contains(IntelSector.energy.rawValue) ||
            $0.topics.contains(IntelSector.adjacent.rawValue)
        }.count
        let rateCount    = articles.filter { $0.topics.contains(IntelSector.capMarkets.rawValue) }.count
        let tourismCount = articles.filter { $0.topics.contains(IntelSector.travel.rawValue) }.count
        let reCount      = articles.filter { $0.topics.contains(IntelSector.realEstate.rawValue) }.count

        return [
            MarketSignalCard(
                label: "REG. PRESSURE",
                sublabel: "\(regCount) headline\(regCount == 1 ? "" : "s")",
                rating: regCount >= 2 ? "HIGH" : regCount == 1 ? "MODERATE" : "LOW",
                ratingColor: regCount >= 2 ? DesignTokens.statusWarn
                           : regCount == 1 ? DesignTokens.statusWarn.opacity(0.7)
                           : DesignTokens.statusGo
            ),
            MarketSignalCard(
                label: "RATE OUTLOOK",
                sublabel: "\(rateCount) headline\(rateCount == 1 ? "" : "s")",
                rating: rateCount >= 2 ? "VOLATILE" : "STABLE",
                ratingColor: rateCount >= 2 ? DesignTokens.statusWarn : DesignTokens.textPrimary
            ),
            MarketSignalCard(
                label: "TOURISM INDEX",
                sublabel: "\(tourismCount) headline\(tourismCount == 1 ? "" : "s")",
                rating: tourismCount >= 1 ? "POSITIVE" : "NEUTRAL",
                ratingColor: tourismCount >= 1 ? DesignTokens.statusGo : DesignTokens.textDim
            ),
            MarketSignalCard(
                label: "SUPPLY PIPELINE",
                sublabel: "\(reCount) headline\(reCount == 1 ? "" : "s")",
                rating: reCount >= 3 ? "ACTIVE" : reCount >= 1 ? "MODERATE" : "TIGHT",
                ratingColor: reCount >= 3 ? DesignTokens.statusGo
                           : reCount >= 1 ? DesignTokens.statusWarn.opacity(0.7)
                           : DesignTokens.statusWarn
            ),
        ]
    }

    // MARK: - Generation via LLMAnalysisService

    private var staleKey: String { "intel_brief_last_\(marketId ?? "all")" }

    private func generateIfStale() async {
        if let last = UserDefaults.standard.object(forKey: staleKey) as? Date,
           Date().timeIntervalSince(last) < 8 * 3600,
           !signals.isEmpty { return }
        await generate()
    }

    private func generate() async {
        briefState = .generating
        signals = []

        let currentArticles = articles
        if currentArticles.isEmpty {
            signals = [IntelSignal(text: "No headlines cached — refresh news on the MAP tab first, then regenerate.", sourceArticle: nil)]
            briefState = .ready
            return
        }

        let marketName = marketId.flatMap { MarketFeedRegistry.market(id: $0)?.displayName } ?? "global markets"
        // Pass article title + source so LLM can focus on market-relevant signals
        let articleLines = currentArticles.prefix(12).map { a in
            "\(a.title) [\(a.sourceDisplayName), \(a.marketId)]"
        }
        let dealNames = deals
            .filter { deal in
                guard let mid = marketId else { return true }
                return deal.marketId == mid || MarketFeedRegistry.countryId(for: deal.marketId) == mid
            }
            .prefix(6)
            .map { $0.propertyName.isEmpty ? "Untitled" : $0.propertyName }

        do {
            let raw = try await LLMAnalysisService.shared.generateMarketBrief(
                market: marketName,
                articles: Array(articleLines),
                dealNames: Array(dealNames)
            )
            var parsed = parseSignals(from: raw)
            if parsed.isEmpty {
                parsed = raw.components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .prefix(5)
                    .map { IntelSignal(text: $0, sourceArticle: nil) }
            }
            // Match each signal to its most likely source article by word overlap
            signals = matchSources(signals: parsed, articles: Array(currentArticles))
            UserDefaults.standard.set(Date(), forKey: staleKey)
            briefState = .ready
        } catch LLMError.offline {
            briefState = .offline
        } catch {
            briefState = .error
            errorMessage = error.localizedDescription
        }
    }

    /// Post-hoc source matching: for each signal, find the article whose title
    /// shares the most meaningful words with the signal text (>4 chars, ≥2 overlap).
    private func matchSources(signals: [IntelSignal], articles: [IntelNewsArticle]) -> [IntelSignal] {
        signals.map { signal in
            let signalWords = Set(
                signal.text.lowercased()
                    .components(separatedBy: .init(charactersIn: " ,.;:!?()\"'"))
                    .filter { $0.count > 4 }
            )
            guard !signalWords.isEmpty else { return signal }

            var bestArticle: IntelNewsArticle? = nil
            var bestOverlap = 1  // require at least 2 overlapping words

            for article in articles {
                let articleWords = Set(
                    article.title.lowercased()
                        .components(separatedBy: .init(charactersIn: " ,.;:!?()\"'"))
                        .filter { $0.count > 4 }
                )
                let overlap = signalWords.intersection(articleWords).count
                if overlap > bestOverlap {
                    bestOverlap = overlap
                    bestArticle = article
                }
            }
            return IntelSignal(text: signal.text, sourceArticle: bestArticle)
        }
    }

    private func parseSignals(from text: String) -> [IntelSignal] {
        var results: [IntelSignal] = []
        for line in text.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty else { continue }
            let cleaned = t
                .replacingOccurrences(of: #"^[\d]+[.)]\s*"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"^>\s*"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            if !cleaned.isEmpty { results.append(IntelSignal(text: cleaned, sourceArticle: nil)) }
            if results.count == 5 { break }
        }
        return results
    }
}

// MARK: - Supporting types

struct IntelSignal: Identifiable {
    let id = UUID()
    let text: String
    var sourceArticle: IntelNewsArticle?
}

struct MarketSignalCard: Identifiable {
    let id = UUID()
    let label: String
    let sublabel: String
    let rating: String
    let ratingColor: Color
}

enum BriefState { case idle, generating, ready, offline, error }
