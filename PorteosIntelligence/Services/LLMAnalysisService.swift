import Foundation

// MARK: - LLMAnalysisService
//
// Single Ollama gateway for the entire app.
// - AI Vibe (deal-level): generateSWOT()
// - Global Intelligence INTEL tab: generateMarketBrief()
//
// Configuration is read from UserDefaults so the user can override in Settings.
// If Ollama is unreachable or times out, throws LLMError.offline so callers
// degrade gracefully to rule-based analysis.

enum LLMError: Error {
    case offline        // Ollama not running or unreachable
    case badResponse    // HTTP non-200 or undecodable JSON
    case emptyContent   // 200 OK but empty text returned
}

final class LLMAnalysisService {

    static let shared = LLMAnalysisService()
    private init() {}

    // MARK: Configuration

    /// UserDefaults keys — written by SettingsView, read here.
    enum Keys {
        static let baseURL   = "porteos.llm.baseURL"
        static let modelName = "porteos.llm.modelName"
    }

    static let defaultBaseURL   = "http://localhost:11434"
    static let defaultModelName = "qwen2.5:0.5b"
    static let timeoutSeconds: Double = 45  // qwen2.5:0.5b is fast; 45s is generous headroom

    var baseURL: String {
        UserDefaults.standard.string(forKey: Keys.baseURL) ?? Self.defaultBaseURL
    }
    var modelName: String {
        UserDefaults.standard.string(forKey: Keys.modelName) ?? Self.defaultModelName
    }

    // MARK: Public API — Deal Analysis (AI Vibe)

    /// Generates a SWOT analysis + Go/Review/NoGo verdict for a deal.
    /// `benchmark` provides city-level market reference data for a grounded assessment.
    func generateSWOT(
        dealName: String,
        grade: String,
        score: Double?,
        signals: [String],
        benchmark: CityMetrics? = nil
    ) async throws -> String {
        let prompt = buildSWOTPrompt(dealName: dealName, grade: grade, score: score,
                                     signals: signals, benchmark: benchmark)
        return try await call(prompt: prompt)
    }

    // MARK: Public API — Market Brief (Global Intelligence INTEL tab)

    /// Generates 5 market signal observations from cached news + deal context.
    /// Used by `IntelBriefView` in the INTEL tab.
    func generateMarketBrief(
        market: String,
        articles: [String],
        dealNames: [String]
    ) async throws -> String {
        let prompt = buildMarketBriefPrompt(market: market, articles: articles, dealNames: dealNames)
        return try await call(prompt: prompt)
    }

    // MARK: Ping

    /// Returns true if Ollama's API responds within a 5s quick check.
    func isAvailable() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return false }
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.httpMethod = "GET"
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: Private — HTTP call

    private func call(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/generate") else { throw LLMError.offline }
        var request = URLRequest(url: url, timeoutInterval: Self.timeoutSeconds)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["model": modelName, "prompt": prompt, "stream": false]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw LLMError.offline
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw LLMError.badResponse
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["response"] as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMError.emptyContent
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Private — Prompt builders

    private func buildSWOTPrompt(
        dealName: String,
        grade: String,
        score: Double?,
        signals: [String],
        benchmark: CityMetrics? = nil
    ) -> String {
        let scoreStr = score.map { "Score: \(Int($0.rounded()))/100" } ?? "Score: N/A"
        let signalList = signals.prefix(12).enumerated()
            .map { "  \($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        let benchmarkBlock: String
        if let bm = benchmark {
            benchmarkBlock = """

Market benchmarks for \(bm.cityName), \(bm.country):
  Prime yield (cap rate): \(String(format: "%.1f", bm.avgCapRate))%
  Typical vacancy rate:   \(String(format: "%.1f", bm.avgVacancyRate))%
  Gross potential income: €\(String(format: "%.0f", bm.avgGPIPerSqm))/m²/yr
  Operating expenses:     €\(String(format: "%.0f", bm.avgOpExPerSqm))/m²/yr
  Insurance (est.):       €\(String(format: "%.1f", bm.avgInsuranceRatePerSqm))/m²/yr
  Market interest rate:   \(String(format: "%.1f", bm.avgInterestRate))%
  Property tax rate:      \(String(format: "%.2f", bm.avgPropertyTaxRate))%\
\(bm.avgADR > 0 ? "\n  Hospitality ADR:        €\(String(format: "%.0f", bm.avgADR))" : "")\
\(bm.avgOccupancyRate > 0 ? "\n  Hospitality occupancy:  \(String(format: "%.0f", bm.avgOccupancyRate))%" : "")

Use these benchmarks when assessing the deal. Flag explicitly when deal metrics deviate from market norms above.
"""
        } else {
            benchmarkBlock = ""
        }

        return """
You are a professional real estate investment analyst. Analyse the following deal and produce a structured response in exactly this format with no other text:

VERDICT: [GO | REVIEW | NO GO]
S: [one sentence — key strength, referencing a specific metric or market comparison]
W: [one sentence — main weakness or data gap dragging the score]
O: [one concrete, specific action that would raise the score to the next grade]
T: [one sentence — biggest external risk for this market and deal type]

Deal: \(dealName)
Grade: \(grade) | \(scoreStr)
\(benchmarkBlock)
Signals:
\(signalList.isEmpty ? "  No signals available." : signalList)
"""
    }

    private func buildMarketBriefPrompt(
        market: String,
        articles: [String],
        dealNames: [String]
    ) -> String {
        let headlineList = articles.prefix(12)
            .map { "- \($0)" }
            .joined(separator: "\n")
        let dealList = dealNames.isEmpty ? "None" : dealNames.joined(separator: ", ")

        return """
You are a real estate portfolio intelligence assistant. Based on the news headlines and portfolio assets below, generate exactly 5 brief one-sentence market signal observations for a property investor.

Respond with exactly 5 lines numbered 1 through 5, no other text.

Market: \(market)
Portfolio assets: \(dealList)

Recent headlines:
\(headlineList.isEmpty ? "No headlines available." : headlineList)
"""
    }
}
