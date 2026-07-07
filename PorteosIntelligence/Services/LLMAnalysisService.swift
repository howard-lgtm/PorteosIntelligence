import Foundation

// MARK: - LLMAnalysisService
//
// Calls a locally-running Ollama instance (http://localhost:11434) to generate
// a concise narrative vibe paragraph for a deal.
//
// If Ollama is unreachable or the call times out, throws LLMError.offline so
// callers can gracefully fall back to rule-based analysis only.

enum LLMError: Error {
    case offline          // Ollama not running or unreachable
    case timeout          // Responded too slowly (> 5 s)
    case badResponse      // HTTP non-200 or undecodable JSON
    case emptyContent     // 200 OK but empty text returned
}

final class LLMAnalysisService {

    static let shared = LLMAnalysisService()
    private init() {}

    // MARK: Configuration

    var baseURL   = "http://localhost:11434"
    var modelName = "llama3"       // change to any Ollama-hosted model
    var timeoutSeconds: Double = 5

    // MARK: Public API

    /// Generates a 2-3 sentence narrative vibe paragraph for the supplied signals.
    /// Throws `LLMError` on any failure so callers can degrade gracefully.
    func generateVibeNarrative(
        dealName:  String,
        grade:     String,
        score:     Double?,
        signals:   [String]     // plain-text signal messages
    ) async throws -> String {

        let prompt = buildPrompt(dealName: dealName, grade: grade, score: score, signals: signals)

        let url = URL(string: "\(baseURL)/api/generate")!
        var request = URLRequest(url: url, timeoutInterval: timeoutSeconds)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model":  modelName,
            "prompt": prompt,
            "stream": false
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            // Connection refused, host unreachable, etc.
            if urlError.code == .cannotConnectToHost
                || urlError.code == .networkConnectionLost
                || urlError.code == .notConnectedToInternet
                || urlError.code == .timedOut {
                throw LLMError.offline
            }
            throw LLMError.offline
        } catch {
            throw LLMError.offline
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw LLMError.badResponse
        }

        guard let json   = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text   = json["response"] as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw LLMError.emptyContent
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Ping

    /// Returns true if Ollama's health endpoint responds within the timeout.
    func isAvailable() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return false }
        var request = URLRequest(url: url, timeoutInterval: timeoutSeconds)
        request.httpMethod = "GET"
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: Prompt Builder

    private func buildPrompt(
        dealName:  String,
        grade:     String,
        score:     Double?,
        signals:   [String]
    ) -> String {
        let scoreStr = score.map { "Score: \(Int($0.rounded()))/100" } ?? "Score: N/A"
        let signalList = signals.prefix(12).enumerated()
            .map { "  \($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        return """
You are a professional real estate and investment analyst. \
Write a concise 2-3 sentence narrative (max 60 words) summarising the investment vibe for the following deal. \
Be direct, use precise financial language, and do not repeat the signals verbatim.

Deal: \(dealName)
Grade: \(grade) | \(scoreStr)

Key signals:
\(signalList)

Narrative:
"""
    }
}
