# LLM Integration Architecture — Multi-Provider AI System

Complete guide to the LLM integration layer, provider switching, prompt engineering, and adding new AI services.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Supported Providers](#supported-providers)
4. [LLMAnalysisService Deep Dive](#llmanalysisservice-deep-dive)
5. [Provider Configuration](#provider-configuration)
6. [Prompt Engineering Patterns](#prompt-engineering-patterns)
7. [Error Handling](#error-handling)
8. [Adding a New Provider](#adding-a-new-provider)
9. [Token Limits & Streaming](#token-limits--streaming)
10. [Testing AI Features](#testing-ai-features)

---

## Overview

Porteos Intelligence supports **3 LLM providers** for AI-powered features:
1. **Ollama** (local)
2. **OpenAI** (cloud)
3. **Google Gemini** (cloud)

### AI-Powered Features

| Feature | Location | Purpose |
|---------|----------|---------|
| **AI Vibe** | Inspector → AI VIBE tab | Property SWOT analysis |
| **RESEARCH Chat** | Inspector → RESEARCH tab | Deal-specific research assistant |
| **Intel Brief** | Global Intelligence → INTEL tab | Daily market intelligence summary |

### Key Design Principles

1. **Provider-agnostic:** ViewModels don't know which provider is active
2. **Graceful degradation:** Falls back to rule-based analysis if LLM fails
3. **User choice:** Provider configured in Settings, persisted in UserDefaults
4. **Secure credentials:** API keys stored in macOS Keychain
5. **Streaming support:** RESEARCH chat streams responses token-by-token

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AI-Powered Features                       │
│  (AIVibePanel, ResearchChatView, IntelBriefView)            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
            ┌────────────────────────────┐
            │   LLMAnalysisService       │
            │    (Multi-provider)        │
            └────────────┬───────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
   ┌─────────┐    ┌─────────┐    ┌─────────┐
   │ Ollama  │    │ OpenAI  │    │ Gemini  │
   │ (local) │    │ (cloud) │    │ (cloud) │
   └─────────┘    └─────────┘    └─────────┘
        │               │               │
        ▼               ▼               ▼
   localhost:     api.openai   generativelanguage
      11434          .com       .googleapis.com
```

### Service Layer

**File:** `PorteosIntelligence/Services/LLMAnalysisService.swift` (778 lines)

**Responsibilities:**
1. Abstract provider differences
2. Handle HTTP requests to each provider
3. Parse responses into common format
4. Stream tokens for chat interface
5. Enforce token limits
6. Handle errors and timeouts

**Singleton pattern:**
```swift
final class LLMAnalysisService {
    static let shared = LLMAnalysisService()
    private init() {}
}
```

---

## Supported Providers

### Provider Comparison

| Provider | Speed | Cost | Privacy | Quality | Setup |
|----------|-------|------|---------|---------|-------|
| **Ollama** | Medium | Free | ✅ Local | Good | Moderate |
| **OpenAI** | Fast | $0.01/call | ⚠️ Cloud | Excellent | Easy |
| **Gemini** | Fast | Free tier | ⚠️ Cloud | Very Good | Easy |

### Ollama (Local)

**Pros:**
- ✅ Completely private (never leaves your Mac)
- ✅ No API costs
- ✅ Works offline (after model download)

**Cons:**
- ⚠️ Requires ~4-8GB disk per model
- ⚠️ Slower inference on older Macs
- ⚠️ Quality depends on model size

**Recommended Models:**
- `qwen2.5-coder:7b` — Best balance (4.7GB)
- `phi4-mini` — Fastest (2.5GB)
- `deepseek-r1:14b` — Best quality (9GB)

**Endpoint:** `http://localhost:11434/api/chat`

### OpenAI

**Pros:**
- ✅ Highest quality responses
- ✅ Fast (cloud GPUs)
- ✅ Reliable uptime

**Cons:**
- ⚠️ Costs $0.01-$0.02 per analysis
- ⚠️ Requires internet
- ⚠️ Data sent to OpenAI servers

**Model:** `gpt-4o-mini`  
**Endpoint:** `https://api.openai.com/v1/chat/completions`

### Google Gemini

**Pros:**
- ✅ Free tier (15 requests/minute)
- ✅ Good quality
- ✅ Fast responses

**Cons:**
- ⚠️ Rate limits on free tier
- ⚠️ Requires internet
- ⚠️ Data sent to Google servers

**Model:** `gemini-3.5-flash`  
**Endpoint:** `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent`

---

## LLMAnalysisService Deep Dive

### Configuration Storage

**UserDefaults keys:**
```swift
enum Keys {
    static let baseURL    = "porteos.llm.baseURL"       // Ollama only
    static let modelName  = "porteos.llm.modelName"     // Ollama only
    static let aiProvider = "porteos.aiProvider"        // "ollama" | "openai" | "gemini"
    static let openAIKey  = "porteos.openaiApiKey"      // Keychain reference
    static let geminiKey  = "porteos.geminiApiKey"      // Keychain reference
}
```

**Defaults:**
```swift
static let defaultBaseURL   = "http://localhost:11434"
static let defaultModelName = "qwen2.5:0.5b"
static let openAIModelName  = "gpt-4o-mini"
static let geminiModelName  = "gemini-3.5-flash"
```

### Provider Selection Logic

```swift
var currentProvider: AIProvider {
    AIProvider(rawValue: UserDefaults.standard.string(forKey: Keys.aiProvider) ?? "ollama") ?? .ollama
}
```

**Provider enum:**
```swift
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
```

### Main Entry Points

**1. Generate SWOT (AI Vibe):**
```swift
func generateSWOT(
    propertyName: String,
    propertyType: String,
    notes: String,
    metrics: String
) async throws -> String
```

**Usage in AIVibePanel:**
```swift
Task {
    do {
        let swot = try await LLMAnalysisService.shared.generateSWOT(
            propertyName: deal.propertyName,
            propertyType: deal.propertyType,
            notes: deal.notes,
            metrics: viewModel.metricsForPrompt
        )
        self.aiAnalysis = parseSWOT(swot)
    } catch LLMError.offline {
        // Fall back to rule-based analysis
        self.aiAnalysis = AIAnalysisService.shared.generateFallbackAnalysis(deal)
    }
}
```

**2. Stream Chat Response (RESEARCH):**
```swift
func streamChatResponse(
    messages: [ResearchMessage],
    onToken: @escaping (String) -> Void,
    onComplete: @escaping (String) -> Void
) async throws
```

**Usage in ResearchChatView:**
```swift
Task {
    var fullResponse = ""
    try await LLMAnalysisService.shared.streamChatResponse(
        messages: chatHistory,
        onToken: { token in
            fullResponse += token
            self.streamingText = fullResponse  // Live update UI
        },
        onComplete: { final in
            let message = ResearchMessage(role: "assistant", content: final)
            context.insert(message)
        }
    )
}
```

**3. Generate Intel Brief (Global Intelligence):**
```swift
func generateMarketBrief(
    headlines: [String],
    marketName: String
) async throws -> String
```

---

## Provider Configuration

### How Providers Are Configured

**Ollama:**
```swift
// SettingsView → AI Provider → Ollama selected
UserDefaults.standard.set("ollama", forKey: "porteos.aiProvider")
UserDefaults.standard.set("http://localhost:11434", forKey: "porteos.llm.baseURL")
UserDefaults.standard.set("qwen2.5-coder:7b", forKey: "porteos.llm.modelName")
```

**OpenAI:**
```swift
// SettingsView → AI Provider → OpenAI selected → API key entered
UserDefaults.standard.set("openai", forKey: "porteos.aiProvider")
// API key stored in Keychain (secure)
try storeAPIKey("sk-proj-...", service: "porteos.openaiApiKey")
```

**Gemini:**
```swift
// SettingsView → AI Provider → Gemini selected → API key entered
UserDefaults.standard.set("gemini", forKey: "porteos.aiProvider")
// API key stored in Keychain (secure)
try storeAPIKey("AIzaSy...", service: "porteos.geminiApiKey")
```

### Keychain Storage

**Store API key:**
```swift
private func storeAPIKey(_ key: String, service: String) throws {
    let data = key.data(using: .utf8)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecValueData as String: data
    ]
    
    SecItemDelete(query as CFDictionary)  // Remove old key
    let status = SecItemAdd(query as CFDictionary, nil)
    
    guard status == errSecSuccess else {
        throw LLMError.invalidKey(provider: service, message: "Keychain error")
    }
}
```

**Retrieve API key:**
```swift
var openAIKey: String {
    guard let data = try? retrieveAPIKey(service: "porteos.openaiApiKey"),
          let key = String(data: data, encoding: .utf8) else {
        return ""
    }
    return key
}
```

---

## Prompt Engineering Patterns

### SWOT Analysis Prompt

**Template:**
```swift
private func buildSWOTPrompt(
    propertyName: String,
    propertyType: String,
    notes: String,
    metrics: String
) -> String {
    """
    You are a real estate investment analyst. Generate a SWOT analysis for this property.
    
    Property: \(propertyName)
    Type: \(propertyType)
    
    Deal Notes:
    \(notes.isEmpty ? "None provided" : notes)
    
    Key Metrics:
    \(metrics)
    
    Provide a structured SWOT analysis:
    
    ## Strengths
    - [3-5 bullet points]
    
    ## Weaknesses
    - [3-5 bullet points]
    
    ## Opportunities
    - [3-5 bullet points]
    
    ## Threats
    - [3-5 bullet points]
    
    Be specific to this property type and metrics. Focus on investment viability.
    """
}
```

### Research Chat Prompt

**System message (context):**
```swift
let systemPrompt = """
You are a real estate investment research assistant. Answer questions about this property:

Property: \(deal.propertyName)
Location: \(deal.locationCity), \(deal.locationCountry)
Type: \(deal.propertyType)
Price: \(deal.purchasePrice.formatted(.currency(code: "USD")))

Provide concise, actionable answers. When possible, cite specific numbers from the deal data. 
If information is missing, suggest what the investor should research next.
"""
```

**User query format:**
```swift
let userMessage = """
Question: \(userInput)

Available data:
- Purchase Price: \(deal.purchasePrice)
- NOI: \(viewModel.noi)
- Cap Rate: \(viewModel.capRate)%
- DSCR: \(viewModel.dscr)
"""
```

### Intel Brief Prompt

**Template:**
```swift
private func buildIntelBriefPrompt(headlines: [String], market: String) -> String {
    """
    Analyze these recent news headlines for \(market) real estate market:
    
    \(headlines.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n"))
    
    Generate a brief intelligence summary (2-3 paragraphs):
    1. Key trends and themes
    2. Investment implications
    3. Risks or opportunities
    
    Be specific and actionable for real estate investors.
    """
}
```

### Best Practices

1. **Be specific:** Reference actual property data in prompts
2. **Set format:** Request structured output (markdown, bullets)
3. **Context matters:** Include property type, location, metrics
4. **Actionable:** Ask for investment-focused insights
5. **Limit scope:** Don't ask for legal/financial advice disclaimers

---

## Error Handling

### Error Types

```swift
enum LLMError: Error {
    case offline                                     // Provider not running/reachable
    case badResponse                                 // HTTP non-200 or malformed JSON
    case emptyContent                                // 200 OK but empty text
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
```

### Graceful Degradation

**In AIVibePanel:**
```swift
Task {
    do {
        // Try LLM-powered analysis
        let swot = try await LLMAnalysisService.shared.generateSWOT(...)
        self.analysis = swot
    } catch LLMError.offline {
        // Fall back to rule-based analysis
        self.analysis = AIAnalysisService.shared.generateFallbackAnalysis(deal)
        self.showOfflineWarning = true
    } catch {
        // Show error to user
        self.errorMessage = error.localizedDescription
    }
}
```

**Rule-based fallback (AIAnalysisService):**
```swift
func generateFallbackAnalysis(_ deal: PropertyDeal) -> String {
    // Rule-based SWOT using thresholds
    var strengths: [String] = []
    
    if deal.capRate > 8.0 {
        strengths.append("Strong cap rate above market average")
    }
    
    if deal.dscr > 1.25 {
        strengths.append("Healthy debt service coverage")
    }
    
    // ... similar logic for weaknesses, opportunities, threats
    
    return formatSWOT(strengths, weaknesses, opportunities, threats)
}
```

### Timeout Handling

**Ollama timeout: 45 seconds**
```swift
static let ollamaTimeoutSeconds: Double = 45

var request = URLRequest(url: url)
request.timeoutInterval = Self.ollamaTimeoutSeconds
```

**Cloud providers timeout: 60 seconds**
```swift
static let cloudTimeoutSeconds: Double = 60

var request = URLRequest(url: url)
request.timeoutInterval = Self.cloudTimeoutSeconds
```

### Retry Logic

**Currently:** No automatic retries (user manually clicks "Regenerate")

**Future improvement:**
```swift
func generateSWOTWithRetry(..., maxRetries: Int = 2) async throws -> String {
    var attempts = 0
    while attempts < maxRetries {
        do {
            return try await generateSWOT(...)
        } catch LLMError.offline where attempts < maxRetries - 1 {
            attempts += 1
            try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 second backoff
        } catch {
            throw error
        }
    }
    throw LLMError.offline
}
```

---

## Adding a New Provider

### Example: Add Anthropic Claude

**Step 1: Update AIProvider enum**
```swift
// LLMAnalysisService.swift

enum AIProvider: String, CaseIterable {
    case ollama = "ollama"
    case openai = "openai"
    case gemini = "gemini"
    case anthropic = "anthropic"  // ← NEW
    
    var displayName: String {
        switch self {
        case .ollama: return "Local (Ollama)"
        case .openai: return "OpenAI (ChatGPT)"
        case .gemini: return "Google Gemini"
        case .anthropic: return "Anthropic Claude"  // ← NEW
        }
    }
}
```

**Step 2: Add configuration keys**
```swift
enum Keys {
    static let baseURL    = "porteos.llm.baseURL"
    static let modelName  = "porteos.llm.modelName"
    static let aiProvider = "porteos.aiProvider"
    static let openAIKey  = "porteos.openaiApiKey"
    static let geminiKey  = "porteos.geminiApiKey"
    static let anthropicKey = "porteos.anthropicApiKey"  // ← NEW
}

static let anthropicModelName = "claude-3-5-sonnet-20240320"  // ← NEW
```

**Step 3: Implement request builder**
```swift
private func buildAnthropicRequest(messages: [[String: String]]) -> URLRequest? {
    guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return nil }
    guard !anthropicKey.isEmpty else { return nil }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(anthropicKey, forHTTPHeaderField: "x-api-key")
    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
    request.timeoutInterval = Self.cloudTimeoutSeconds
    
    let body: [String: Any] = [
        "model": Self.anthropicModelName,
        "max_tokens": 3000,
        "messages": messages
    ]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    return request
}
```

**Step 4: Implement response parser**
```swift
private func parseAnthropicResponse(_ data: Data) throws -> String {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let content = json["content"] as? [[String: Any]],
          let firstContent = content.first,
          let text = firstContent["text"] as? String else {
        throw LLMError.badResponse
    }
    
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
}
```

**Step 5: Update generateSWOT routing**
```swift
func generateSWOT(...) async throws -> String {
    let prompt = buildSWOTPrompt(...)
    
    switch currentProvider {
    case .ollama:
        return try await generateWithOllama(prompt: prompt)
    case .openai:
        return try await generateWithOpenAI(prompt: prompt)
    case .gemini:
        return try await generateWithGemini(prompt: prompt)
    case .anthropic:  // ← NEW
        return try await generateWithAnthropic(prompt: prompt)
    }
}
```

**Step 6: Update SettingsView UI**
```swift
// SettingsView.swift → AI Provider section

Picker("Provider", selection: $selectedProvider) {
    ForEach(AIProvider.allCases, id: \.self) { provider in
        Text(provider.displayName).tag(provider)
    }
}

if selectedProvider == .anthropic {
    SecureField("API Key", text: $anthropicAPIKey)
        .textFieldStyle(TerminalTextFieldStyle())
}
```

**Step 7: Test**
- Add Anthropic API key in Settings
- Generate AI Vibe → Verify Claude response
- Test error handling (invalid key, offline, etc.)

---

## Token Limits & Streaming

### Token Limits by Provider

| Provider | Max Tokens | Enforced By |
|----------|-----------|-------------|
| **Ollama** | 4,096 | Request parameter `num_predict` |
| **OpenAI** | 3,000 | Request parameter `max_tokens` |
| **Gemini** | 3,000 | Request parameter `maxOutputTokens` |

**Why limits?**
- Prevent runaway costs (OpenAI/Gemini)
- Ensure responses fit in UI
- Ollama: Higher limit for longer research responses

### Streaming Implementation (Ollama Example)

**Request:**
```swift
let body: [String: Any] = [
    "model": modelName,
    "messages": messages,
    "stream": true,  // ← Enable streaming
    "options": [
        "num_predict": 4096,
        "temperature": 0.7
    ]
]
```

**Response parsing:**
```swift
func streamChatResponse(...) async throws {
    let (bytes, response) = try await URLSession.shared.bytes(for: request)
    
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw LLMError.badResponse
    }
    
    var fullText = ""
    
    for try await line in bytes.lines {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let content = message["content"] as? String else {
            continue
        }
        
        fullText += content
        await MainActor.run {
            onToken(content)  // Update UI with each token
        }
        
        if let done = json["done"] as? Bool, done {
            await MainActor.run {
                onComplete(fullText)
            }
            break
        }
    }
}
```

**UI update (ResearchChatView):**
```swift
@State private var streamingText: String = ""
@State private var isStreaming: Bool = false

var body: some View {
    ScrollView {
        ForEach(messages) { message in
            MessageBubble(message: message)
        }
        
        if isStreaming {
            MessageBubble(
                role: "assistant",
                content: streamingText,  // ← Live updates
                isStreaming: true
            )
        }
    }
}
```

---

## Testing AI Features

### Manual Testing Checklist

**AI Vibe:**
- [ ] Test with Ollama (qwen2.5-coder:7b)
- [ ] Test with OpenAI (gpt-4o-mini)
- [ ] Test with Gemini (gemini-3.5-flash)
- [ ] Test with invalid API key → Shows error
- [ ] Test with Ollama offline → Falls back to rule-based
- [ ] Test with minimal deal data → Still generates SWOT
- [ ] Test with full deal data → Specific insights
- [ ] Test regenerate button → New analysis generated

**RESEARCH Chat:**
- [ ] Test streaming with Ollama → Tokens appear live
- [ ] Test multi-turn conversation → Context preserved
- [ ] Test copy conversation → Formatted correctly
- [ ] Test clear chat → History deleted
- [ ] Test with long responses → Token limit respected
- [ ] Test provider switch mid-conversation → Works

**Intel Brief:**
- [ ] Test with 10 headlines → Brief generated
- [ ] Test with no headlines → Graceful handling
- [ ] Test provider offline → Error shown

### Unit Testing

**Mock LLM responses:**
```swift
class MockLLMService: LLMAnalysisService {
    var mockResponse: String = ""
    var shouldFail: Bool = false
    
    override func generateSWOT(...) async throws -> String {
        if shouldFail {
            throw LLMError.offline
        }
        return mockResponse
    }
}
```

**Test error handling:**
```swift
func testSWOTFallback() async throws {
    let mockService = MockLLMService()
    mockService.shouldFail = true
    
    // Inject mock
    let panel = AIVibePanel(deal: testDeal, llmService: mockService)
    
    await panel.regenerate()
    
    // Should fall back to rule-based
    XCTAssertTrue(panel.analysis.contains("Rule-based"))
    XCTAssertFalse(panel.analysis.isEmpty)
}
```

---

## Summary

**LLM Integration:**
- 3 providers (Ollama, OpenAI, Gemini)
- Provider-agnostic service layer
- Graceful degradation to rule-based analysis
- Streaming support for chat
- Secure credential storage (Keychain)

**Key Files:**
- [`LLMAnalysisService.swift`](PorteosIntelligence/Services/LLMAnalysisService.swift) (778 lines) — Multi-provider gateway
- [`AIAnalysisService.swift`](PorteosIntelligence/Services/AIAnalysisService.swift) (989 lines) — Rule-based fallback
- [`AIVibePanel.swift`](PorteosIntelligence/Views/Components/AIVibePanel.swift) (1,149 lines) — SWOT UI
- [`ResearchChatView.swift`](PorteosIntelligence/Views/Components/ResearchChatView.swift) — Chat UI

**Adding Providers:**
1. Update `AIProvider` enum
2. Add configuration keys
3. Implement request builder
4. Implement response parser
5. Update routing logic
6. Update Settings UI
7. Test thoroughly

**Critical:** Always provide graceful degradation paths. LLM failures should never block core functionality.

**Next:** See [`CALCULATOR_SYSTEM.md`](CALCULATOR_SYSTEM.md) for financial metrics implementation.
