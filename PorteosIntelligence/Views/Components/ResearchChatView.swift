import SwiftUI
import SwiftData
import Combine

// MARK: - ResearchChatView
// AI research chat with live streaming output, text wrapping,
// clear-chat command, and smart auto-apply for importable data.

struct ResearchChatView: View {

    @Bindable var deal: PropertyDeal
    @Environment(\.modelContext) private var modelContext

    @Query private var allMessages: [ResearchMessage]

    @State private var inputText: String      = ""
    @State private var isLoading: Bool        = false
    @State private var streamingText: String  = ""   // live chunks accumulate here
    @State private var streamTask: Task<Void, Never>? = nil
    @State private var showClearConfirm: Bool = false
    @State private var lastResponseTruncated: Bool = false  // warn if LLM hit token limit

    // MARK: Design tokens
    private let bg      = DesignTokens.canvasBase
    private let surf    = DesignTokens.surfacePanel
    private let border  = DesignTokens.dividerStructural
    private let tp1     = DesignTokens.textPrimary
    private let tp2     = DesignTokens.textSecondary
    private let tp3     = DesignTokens.textDim
    private let teal    = DesignTokens.accentHospitality
    private let rust    = DesignTokens.accentRust

    init(deal: PropertyDeal) { self.deal = deal }

    private var messages: [ResearchMessage] {
        allMessages.filter { $0.dealID == deal.id }.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            Divider().background(border)
            messageList
            Divider().background(border)
            inputBar
        }
        .confirmationDialog("Clear research history?",
                            isPresented: $showClearConfirm,
                            titleVisibility: .visible) {
            Button("Clear", role: .destructive) { clearChat() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All messages for this deal will be deleted.")
        }
    }

    // MARK: Header

    private var chatHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@research ~ %")
                .porteosMeta()
                .foregroundStyle(tp3)
            Spacer()
            if !messages.isEmpty || isLoading {
                Button {
                    showClearConfirm = true
                } label: {
                    Text("[ CLEAR ]")
                        .porteosMeta()
                        .foregroundStyle(tp3)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .overlay(Rectangle().stroke(border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: DesignTokens.rowHeightHeader)
        .background(surf)
    }

    // MARK: Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    if messages.isEmpty && !isLoading {
                        emptyState
                    } else {
                        ForEach(messages) { msg in
                            MessageRow(message: msg, deal: deal,
                                       onApply: applyChanges)
                                .id(msg.id)
                        }
                        if isLoading {
                            StreamingRow(text: streamingText,
                                         model: LLMAnalysisService.shared.activeModelDisplayName)
                                .id("stream")
                        }
                        
                        // Truncation warning (if last response hit token limit)
                        if lastResponseTruncated && !isLoading {
                            truncationWarning
                        }
                    }
                    // Bottom anchor with breathing room so the last message
                    // is fully visible after the deferred scroll
                    Color.clear.frame(height: 24).id("bottom")
                }
                // Explicit maxWidth: .infinity ensures the VStack — and every
                // Text inside it — receives a concrete horizontal bound from
                // the ScrollView, preventing right-edge overflow.
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(bg)
            // Streaming chunks: scroll immediately (no layout ambiguity —
            // the row already exists and is just growing taller)
            .onChange(of: streamingText) { _, _ in
                proxy.scrollTo("bottom", anchor: .bottom)
            }
            // New saved message: defer by one runloop tick so SwiftUI can
            // complete the layout pass and measure the new row's full height
            // before we ask ScrollViewReader to position to the bottom.
            .onChange(of: messages.count) { _, _ in
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            // Also scroll when loading state clears (streaming just finished)
            .onChange(of: isLoading) { _, loading in
                guard !loading else { return }
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("// research mode")
                .porteosMeta()
                .foregroundStyle(teal)
            Text("Ask anything about this deal —\nmarket comps, zoning, ADR benchmarks,\nfinancial feasibility, risk factors.")
                .porteosRowLabel()
                .foregroundStyle(tp3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Truncation warning

    private var truncationWarning: some View {
        HStack(spacing: 6) {
            Text("⚠")
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.statusWarn)
            Text("Response may be incomplete. Type \"continue\" or \"finish your thoughts\" for more.")
                .font(DesignTokens.TypeScale.meta)
                .foregroundStyle(tp3)
                .lineLimit(nil)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.statusWarn.opacity(0.08))
    }

    // MARK: Input bar

    private var inputBar: some View {
        HStack(spacing: 6) {
            TextField("Type message...", text: $inputText)
                .textFieldStyle(.plain)
                .porteosRowValue()
                .foregroundStyle(tp1)
                .padding(.horizontal, 8)
                .frame(height: 30)
                .background(bg)
                .overlay(Rectangle().stroke(border, lineWidth: 1))
                .disabled(isLoading)
                .onSubmit { sendMessage() }

            Button {
                if isLoading {
                    cancelStream()
                } else {
                    sendMessage()
                }
            } label: {
                Text(isLoading ? "[ ✕ ]" : "[ ↵ ]")
                    .porteosMeta()
                    .foregroundStyle(isLoading ? rust : (inputText.isEmpty ? tp3 : teal))
                    .frame(width: 40, height: 30)
                    .background(surf)
                    .overlay(Rectangle().stroke(border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(!isLoading && inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(surf)
    }

    // MARK: Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isLoading else { return }

        // Save user message immediately
        let userMsg = ResearchMessage(dealID: deal.id, role: "user", content: text)
        modelContext.insert(userMsg)
        try? modelContext.save()

        inputText    = ""
        isLoading    = true
        streamingText = ""
        lastResponseTruncated = false  // reset warning on new query

        let historySnapshot = messages.map { ($0.role, $0.content) }

        streamTask = Task { @MainActor in
            do {
                let stream = LLMAnalysisService.shared.streamResearch(
                    message: text,
                    deal: deal,
                    history: historySnapshot
                )
                for try await chunk in stream {
                    streamingText += chunk
                }
                // Stream finished — detect truncation.
                // Heuristic: if response is very long (≥2400 tokens ≈ 1800 words ≈ 9600 chars)
                // and ends mid-sentence, likely hit token limit.
                let charCount = streamingText.count
                let likelyTruncated = charCount >= 9000 &&
                                      !streamingText.hasSuffix(".") &&
                                      !streamingText.hasSuffix("?") &&
                                      !streamingText.hasSuffix("!") &&
                                      !streamingText.hasSuffix("```")
                lastResponseTruncated = likelyTruncated
                
                // Persist full response
                let aiMsg = ResearchMessage(
                    dealID: deal.id,
                    role: "assistant",
                    content: streamingText,
                    modelName: LLMAnalysisService.shared.activeModelDisplayName
                )
                // Check for importable JSON
                if let json = extractJSON(from: streamingText) {
                    let changes = processResearchData(json)
                    aiMsg.extractedFields    = changes
                    aiMsg.hasExtractedData   = !changes.isEmpty
                }
                modelContext.insert(aiMsg)
                try? modelContext.save()
                streamingText = ""
                isLoading = false
            } catch {
                // Show error as a message
                let errMsg = ResearchMessage(
                    dealID: deal.id,
                    role: "assistant",
                    content: "⚠ \(error.localizedDescription)"
                )
                modelContext.insert(errMsg)
                try? modelContext.save()
                streamingText = ""
                isLoading = false
            }
        }
    }

    private func cancelStream() {
        streamTask?.cancel()
        streamTask    = nil
        streamingText = ""
        isLoading     = false
    }

    private func clearChat() {
        for msg in messages { modelContext.delete(msg) }
        try? modelContext.save()
    }

    // MARK: JSON extraction + smart apply

    private func extractJSON(from text: String) -> [String: Any]? {
        // Look for ```json ... ``` block first, then bare { ... }
        if let range = text.range(of: #"```json\s*([\s\S]*?)\s*```"#, options: .regularExpression) {
            let raw = String(text[range])
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let data = raw.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
        }
        // Bare object fallback
        if let range = text.range(of: #"\{[\s\S]+\}"#, options: .regularExpression) {
            let raw = String(text[range])
            if let data = raw.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
        }
        return nil
    }

    private func processResearchData(_ json: [String: Any]) -> [FieldChange] {
        var changes: [FieldChange] = []

        func add(_ name: String, old: String?, new: String, auto: Bool) {
            changes.append(FieldChange(fieldName: name, oldValue: old, newValue: new, autoApplied: auto))
        }

        if let t = json["property_type"] as? String {
            if deal.propertyType.isEmpty { deal.propertyType = t; add("Property Type", old: nil, new: t, auto: true) }
            else if deal.propertyType != t { add("Property Type", old: deal.propertyType, new: t, auto: false) }
        }
        if let p = DealResearchImporter.double(json, keys: ["purchase_price", "price"]), p > 0 {
            if deal.purchasePrice == 0 { deal.purchasePrice = p; add("Purchase Price", old: nil, new: "€\(Int(p))", auto: true) }
            else if abs(deal.purchasePrice - p) > 1 { add("Purchase Price", old: "€\(Int(deal.purchasePrice))", new: "€\(Int(p))", auto: false) }
        }
        if let a = DealResearchImporter.double(json, keys: ["total_area", "area_sqm"]), a > 0 {
            if deal.totalArea == 0 { deal.totalArea = a; add("Total Area", old: nil, new: "\(Int(a))m²", auto: true) }
            else if abs(deal.totalArea - a) > 1 { add("Total Area", old: "\(Int(deal.totalArea))m²", new: "\(Int(a))m²", auto: false) }
        }
        if let lat = DealResearchImporter.double(json, keys: ["latitude", "lat"]),
           let lon = DealResearchImporter.double(json, keys: ["longitude", "lon"]),
           lat != 0, lon != 0 {
            deal.latitude = lat; deal.longitude = lon; deal.geocodeStatus = .ok
            add("GPS", old: nil, new: "\(String(format: "%.5f", lat)), \(String(format: "%.5f", lon))", auto: true)
        }
        // Full import pipeline for richer JSON
        if json.keys.count > 3, let data = try? JSONSerialization.data(withJSONObject: json) {
            let result = DealResearchImporter.apply(json: data, to: deal, context: modelContext)
            for label in result.applied {
                if !changes.contains(where: { $0.newValue == label }) {
                    add("Imported", old: nil, new: label, auto: true)
                }
            }
        }
        deal.porteosScore = PropertyDealViewModel(deal: deal).porteosScore.finalScore
        deal.updatedAt    = Date()
        try? modelContext.save()
        return changes
    }

    private func applyChanges(_ changes: [FieldChange]) {
        deal.updatedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - MessageRow
// Displays a saved (completed) message. Text wraps correctly at any width.

struct MessageRow: View {
    let message: ResearchMessage
    let deal: PropertyDeal
    let onApply: ([FieldChange]) -> Void

    private let bg      = DesignTokens.canvasBase
    private let surf    = DesignTokens.surfacePanel
    private let tp1     = DesignTokens.textPrimary
    private let tp2     = DesignTokens.textSecondary
    private let tp3     = DesignTokens.textDim
    private let teal    = DesignTokens.accentHospitality
    private let rust    = DesignTokens.accentRust
    private let go      = DesignTokens.statusGo
    private let warn    = DesignTokens.statusWarn

    init(message: ResearchMessage, deal: PropertyDeal,
         onApply: @escaping ([FieldChange]) -> Void) {
        self.message = message
        self.deal    = deal
        self.onApply = onApply
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Role header
            HStack(spacing: 6) {
                Text(message.role == "user" ? "porteos@user ~ %" : "porteos@ai ~ %")
                    .porteosMeta()
                    .foregroundStyle(message.role == "user" ? tp3 : teal)
                if message.role == "assistant", let m = message.modelName {
                    Text("[\(m)]")
                        .porteosMeta()
                        .foregroundStyle(tp3.opacity(0.6))
                }
            }

            // Chat body text — DO NOT use .porteosRowValue() here.
            // porteosTextStyle applies .frame(height: lineHeight) + .lineLimit(1)
            // which is correct for single-line data rows but clamps a chat
            // response to 16pt tall and overflows text horizontally.
            // Apply font token only, letting the view grow to its natural height.
            Text(message.content)
                .font(DesignTokens.TypeScale.rowValue)
                .foregroundStyle(message.role == "user" ? tp1 : tp2)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)

            // Applied / suggested fields summary
            if message.hasExtractedData, let fields = message.extractedFields, !fields.isEmpty {
                fieldsSummary(fields)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(message.role == "user" ? surf : bg)    }

    @ViewBuilder
    private func fieldsSummary(_ fields: [FieldChange]) -> some View {
        let auto      = fields.filter { $0.autoApplied }
        let suggested = fields.filter { !$0.autoApplied }

        VStack(alignment: .leading, spacing: 4) {
            Rectangle().fill(rust.opacity(0.3)).frame(height: 1)

            if !auto.isEmpty {
                Text("✓ auto-applied \(auto.count) field\(auto.count == 1 ? "" : "s")")
                    .porteosMeta().foregroundStyle(go)
                ForEach(auto, id: \.fieldName) { c in
                    Text("  • \(c.fieldName): \(c.newValue)")
                        .font(DesignTokens.TypeScale.meta)
                        .foregroundStyle(tp3)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if !suggested.isEmpty {
                Text("⚠ review \(suggested.count) suggested change\(suggested.count == 1 ? "" : "s")")
                    .font(DesignTokens.TypeScale.meta)
                    .foregroundStyle(warn)
                ForEach(suggested, id: \.fieldName) { c in
                    Text("  • \(c.fieldName): \(c.oldValue ?? "—") → \(c.newValue)")
                        .font(DesignTokens.TypeScale.meta)
                        .foregroundStyle(tp3)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button { onApply(suggested) } label: {
                    Text("[ APPLY ALL ]")
                        .porteosMeta()
                        .foregroundStyle(rust)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .overlay(Rectangle().stroke(rust.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - StreamingRow
// Live row shown while LLM is generating. Updates on every chunk.

struct StreamingRow: View {
    let text: String
    let model: String

    @State private var dotPhase: Int = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    private let bg   = DesignTokens.canvasBase
    private let tp2  = DesignTokens.textSecondary
    private let tp3  = DesignTokens.textDim
    private let teal = DesignTokens.accentHospitality

    init(text: String, model: String) { self.text = text; self.model = model }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("porteos@ai ~ %")
                    .porteosMeta().foregroundStyle(teal)
                Text("[\(model)]")
                    .porteosMeta().foregroundStyle(tp3.opacity(0.6))
            }

            if text.isEmpty {
                // Waiting for first chunk — animated dots
                Text(String(repeating: ".", count: dotPhase + 1))
                    .porteosMeta().foregroundStyle(teal.opacity(0.6))
                    .onReceive(timer) { _ in dotPhase = (dotPhase + 1) % 3 }
            } else {
                // Live streaming text + blinking cursor.
                // Font token only — no porteosRowValue() to avoid frame(height:16) clamp.
                (Text(text).foregroundStyle(tp2) +
                 Text("▋").foregroundStyle(teal.opacity(0.8)))
                    .font(DesignTokens.TypeScale.rowValue)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg)
    }
}

// MARK: - FieldChange model

struct FieldChange: Codable {
    let fieldName: String
    let oldValue: String?
    let newValue: String
    let autoApplied: Bool
}
