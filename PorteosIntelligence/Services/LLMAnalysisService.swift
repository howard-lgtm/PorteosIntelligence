import Foundation

// MARK: - AIProvider

enum AIProvider: String, CaseIterable {
    case ollama = "ollama"
    case openai = "openai"
    case gemini = "gemini"

    var displayName: String {
        switch self {
        case .ollama: return "Local (Ollama)"
        case .openai: return "OpenAI (ChatGPT)"
        case .gemini: return "Google Gemini"
        }
    }
}

// MARK: - LLMAnalysisService
//
// Multi-provider LLM gateway for the entire app.
// - AI Vibe (deal-level): generateSWOT()
// - Global Intelligence INTEL tab: generateMarketBrief()
//
// Configuration is read from UserDefaults so the user can override in Settings.
// If the configured provider is unreachable or has no key set, throws LLMError.offline
// so callers degrade gracefully to rule-based analysis.

enum LLMError: Error {
    case offline        // provider not running, unreachable, or API key missing
    case badResponse    // HTTP non-200 or undecodable JSON
    case emptyContent   // 200 OK but empty text returned
    case invalidKey(provider: String, message: String?)  // API key rejected
}

extension LLMError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .offline:
            return "Provider offline or API key missing"
        case .badResponse:
            return "Invalid response from API"
        case .emptyContent:
            return "API returned empty response"
        case .invalidKey(let provider, let message):
            if let msg = message {
                return "\(provider) API error: \(msg)"
            }
            return "\(provider) API key is invalid or quota exceeded"
        }
    }
}

final class LLMAnalysisService {

    static let shared = LLMAnalysisService()
    private init() {}

    // MARK: Configuration

    /// UserDefaults keys — written by SettingsView, read here.
    enum Keys {
        static let baseURL    = "porteos.llm.baseURL"
        static let modelName  = "porteos.llm.modelName"
        static let aiProvider = "porteos.aiProvider"
        static let openAIKey  = "porteos.openaiApiKey"
        static let geminiKey  = "porteos.geminiApiKey"
    }

    static let defaultBaseURL   = "http://localhost:11434"
    static let defaultModelName = "qwen2.5:0.5b"
    static let openAIModelName  = "gpt-4o-mini"
    static let geminiModelName  = "gemini-3.5-flash"
    static let ollamaTimeoutSeconds: Double = 45
    static let cloudTimeoutSeconds:  Double = 60

    var baseURL: String {
        UserDefaults.standard.string(forKey: Keys.baseURL) ?? Self.defaultBaseURL
    }
    var modelName: String {
        UserDefaults.standard.string(forKey: Keys.modelName) ?? Self.defaultModelName
    }

    var currentProvider: AIProvider {
        AIProvider(rawValue: UserDefaults.standard.string(forKey: Keys.aiProvider) ?? "ollama") ?? .ollama
    }

    var openAIKey: String {
        UserDefaults.standard.string(forKey: Keys.openAIKey) ?? ""
    }

    var geminiKey: String {
        UserDefaults.standard.string(forKey: Keys.geminiKey) ?? ""
    }

    /// Model name shown in UI and used for the currently selected provider.
    var activeModelDisplayName: String {
        switch currentProvider {
        case .ollama: return modelName
        case .openai: return Self.openAIModelName
        case .gemini: return Self.geminiModelName
        }
    }

    // MARK: Public API — Deal Analysis (AI Vibe)

    /// Generates a SWOT analysis + Go/Review/NoGo verdict for a deal.
    /// `benchmark` provides city-level market reference data for a grounded assessment.
    func generateSWOT(
        dealName: String,
        grade: String,
        score: Double?,
        signals: [String],
        benchmark: CityMetrics? = nil,
        analystNotes: String? = nil,
        regulatoryContext: String? = nil
    ) async throws -> String {
        let prompt = buildSWOTPrompt(dealName: dealName, grade: grade, score: score,
                                     signals: signals, benchmark: benchmark,
                                     analystNotes: analystNotes,
                                     regulatoryContext: regulatoryContext)
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

    // MARK: Public API — Research Chat

    /// Generates a conversational response for property research questions.
    /// Used by `ResearchChatView` in the RESEARCH tab.
    func chatResearch(
        message: String,
        deal: PropertyDeal,
        history: [(String, String)]  // (role, content)
    ) async throws -> String {
        let prompt = buildResearchPrompt(message: message, deal: deal, history: history)
        return try await call(prompt: prompt)
    }

    // MARK: Ping

    /// Returns true if the configured provider is ready to accept requests.
    func isAvailable() async -> Bool {
        switch currentProvider {
        case .ollama:
            guard let url = URL(string: "\(baseURL)/api/tags") else { return false }
            var request = URLRequest(url: url, timeoutInterval: 5)
            request.httpMethod = "GET"
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                return (response as? HTTPURLResponse)?.statusCode == 200
            } catch {
                return false
            }
        case .openai:
            return !openAIKey.isEmpty
        case .gemini:
            return !geminiKey.isEmpty
        }
    }

    // MARK: Private — HTTP call (provider-routed)

    private func call(prompt: String) async throws -> String {
        switch currentProvider {
        case .ollama:
            return try await callOllama(prompt: prompt)
        case .openai:
            return try await callOpenAI(prompt: prompt)
        case .gemini:
            return try await callGemini(prompt: prompt)
        }
    }

    // MARK: Private — Ollama

    private func callOllama(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/generate") else { throw LLMError.offline }
        var request = URLRequest(url: url, timeoutInterval: Self.ollamaTimeoutSeconds)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "stream": false,
            "options": ["num_predict": 2048]
        ]
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

    // MARK: Private — OpenAI

    private func callOpenAI(prompt: String) async throws -> String {
        let key = openAIKey
        guard !key.isEmpty else { throw LLMError.offline }
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw LLMError.offline
        }

        var request = URLRequest(url: url, timeoutInterval: Self.cloudTimeoutSeconds)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": Self.openAIModelName,
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 1500
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw LLMError.offline
        }

        guard let http = response as? HTTPURLResponse else {
            throw LLMError.badResponse
        }
        
        if http.statusCode != 200 {
            // Try to parse error message from response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw LLMError.invalidKey(provider: "OpenAI", message: message)
            }
            throw LLMError.invalidKey(provider: "OpenAI", message: nil)
        }
        
        guard let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices  = json["choices"] as? [[String: Any]],
              let first    = choices.first,
              let message  = first["message"] as? [String: Any],
              let text     = message["content"] as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMError.emptyContent
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Private — Google Gemini

    private func callGemini(prompt: String) async throws -> String {
        let key = geminiKey
        guard !key.isEmpty else { throw LLMError.offline }
        // Use v1 endpoint with gemini-3.5-flash (free tier, current model as of 2026)
        let urlString = "https://generativelanguage.googleapis.com/v1/models/\(Self.geminiModelName):generateContent?key=\(key)"
        guard let url = URL(string: urlString) else { throw LLMError.offline }

        var request = URLRequest(url: url, timeoutInterval: Self.cloudTimeoutSeconds)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": ["maxOutputTokens": 1500]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw LLMError.offline
        }

        guard let http = response as? HTTPURLResponse else {
            throw LLMError.badResponse
        }
        
        if http.statusCode != 200 {
            // Try to parse error message from Gemini response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw LLMError.invalidKey(provider: "Gemini", message: message)
            }
            throw LLMError.invalidKey(provider: "Gemini", message: "HTTP \(http.statusCode)")
        }
        
        guard let json        = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates   = json["candidates"] as? [[String: Any]],
              let first        = candidates.first,
              let content      = first["content"] as? [String: Any],
              let parts        = content["parts"] as? [[String: Any]],
              let text         = parts.first?["text"] as? String,
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
        benchmark: CityMetrics? = nil,
        analystNotes: String? = nil,
        regulatoryContext: String? = nil
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

        let regulatoryBlock: String
        if let reg = regulatoryContext, !reg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            regulatoryBlock = """

Regulatory advisory (user-entered, not verified):
  \(reg.trimmingCharacters(in: .whitespacesAndNewlines))
Factor these into SWOT — flag FAR violations as Weaknesses, STR/planning issues as Threats, headroom as Opportunities.
"""
        } else {
            regulatoryBlock = ""
        }

        let notesBlock: String
        if let notes = analystNotes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            notesBlock = "\nAnalyst field notes (treat as first-hand observations — factor into SWOT):\n  \(notes.trimmingCharacters(in: .whitespacesAndNewlines))\n"
        } else {
            notesBlock = ""
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
\(benchmarkBlock)\(regulatoryBlock)\(notesBlock)
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
You are a real estate portfolio intelligence assistant. Generate exactly 5 one-sentence market signal observations relevant to property investment in \(market).

Rules:
- Only include signals relevant to \(market) real estate, yields, tourism, or regulation.
- If a headline is not relevant to \(market), ignore it.
- Each signal must reference a specific headline or fact, not generic global commentary.
- Be specific: mention yields, rates, locations, or policy names where possible.
- Respond with exactly 5 lines numbered 1 through 5, no other text.

Market focus: \(market)
Portfolio assets: \(dealList)

Headlines (source in brackets):
\(headlineList.isEmpty ? "No headlines available." : headlineList)
"""
    }

    private func buildResearchPrompt(
        message: String,
        deal: PropertyDeal,
        history: [(String, String)]
    ) -> String {
        // Build conversation history context
        let historyContext: String
        if history.isEmpty {
            historyContext = ""
        } else {
            let formatted = history.suffix(6)  // Last 6 messages for context
                .map { role, content in
                    let prefix = role == "user" ? "User" : "Assistant"
                    return "\(prefix): \(content)"
                }
                .joined(separator: "\n\n")
            historyContext = """

Previous conversation:
\(formatted)

"""
        }
        
        // Build deal context
        let dealContext = """
Current deal: \(deal.propertyName.isEmpty ? "Unnamed Property" : deal.propertyName)
Location: \(deal.locationCity), \(deal.locationCountry)
Type: \(deal.propertyType.isEmpty ? "Not specified" : deal.propertyType)
Area: \(deal.totalArea > 0 ? "\(Int(deal.totalArea))m²" : "Not specified")
Price: \(deal.purchasePrice > 0 ? deal.currencySymbol + "\(Int(deal.purchasePrice))" : "Not specified")
Score: \((deal.porteosScore ?? 0) > 0 ? "\(Int(deal.porteosScore ?? 0))/100" : "Not evaluated yet")
"""
        
        return """
You are an expert real estate investment analyst helping a user research property deals. Your role is to provide clear, actionable insights in a conversational tone.

\(dealContext)\(historyContext)
User question: \(message)

## Response Guidelines:

1. **Start with a direct answer** to the user's question in 1-2 sentences
2. **Provide context and reasoning** - explain why this matters for the deal
3. **Include specific data** when relevant (market rates, benchmarks, comparable properties)
4. **Be conversational but professional** - like a knowledgeable colleague, not a robot
5. **Use formatting** for readability:
   - **Bold** for key terms and metrics
   - Bullet points for lists
   - Clear section breaks for complex topics

6. **If providing numerical data**, structure it clearly within your explanation, then OPTIONALLY provide a JSON block at the end for import:

```json
{
  "field_name": value,
  "another_field": value
}
```

## JSON Format (OPTIONAL - only if you're providing importable data):
- Use snake_case field names
- Common fields: `property_type`, `total_area`, `purchase_price`, `land_area`, `latitude`, `longitude`
- Hospitality: `target_keys_count`, `adr_eur`, `occupancy_rate_pct`, `opex_ratio_pct`
- Financial: `closing_costs_eur`, `renovation_capex_eur`, `interest_rate_pct`, `ltv_pct`
- Regulatory: `zoning_class`, `floor_area_ratio`, `max_building_height_m`, `planning_status`

**Example response format:**

"Based on market data for the centro histórico in Porto, average hotel ADR is around **€95-110** per night for boutique properties. This is 15-20% higher than the city average due to tourism demand and UNESCO heritage status.

For a 25-room hotel in this area, you'd typically see:
- **Occupancy**: 70-75% annually
- **RevPAR**: €70-80
- **OpEx ratio**: 25-30% of revenue

This market has strong fundamentals - Porto saw 3.5M tourists in 2025, and boutique hotels under 30 keys perform particularly well in the historic core.

```json
{
  "property_type": "Hotel",
  "target_keys_count": 25,
  "adr_eur": 102,
  "occupancy_rate_pct": 72,
  "opex_ratio_pct": 27
}
```"

Now respond to the user's question:
"""
    }
}
