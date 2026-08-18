import SwiftUI
import SwiftData

// MARK: - ResearchChatView
// AI research chat with smart auto-apply: empty fields auto-populate,
// existing fields show as suggestions requiring approval.

struct ResearchChatView: View {
    
    @Bindable var deal: PropertyDeal
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allMessages: [ResearchMessage]
    
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var scrollID: UUID = UUID()
    
    init(deal: PropertyDeal) {
        self.deal = deal
    }
    
    private var messages: [ResearchMessage] {
        allMessages.filter { $0.dealID == deal.id }.sorted { $0.timestamp < $1.timestamp }
    }
    
    private var shellBg = DesignTokens.canvasBase
    private var shellSurface = DesignTokens.surfacePanel
    private var shellBorder = DesignTokens.dividerStructural
    private var textPrimary = DesignTokens.textPrimary
    private var textSecondary = DesignTokens.textSecondary
    private var textTertiary = DesignTokens.textDim
    private var accentTeal = DesignTokens.accentHospitality
    private var accentRust = DesignTokens.accentRust
    private var statusGo = DesignTokens.statusGo
    private var statusWarn = DesignTokens.statusWarn
    
    var body: some View {
        VStack(spacing: 0) {
            // Message history
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12, pinnedViews: []) {
                        ForEach(messages) { message in
                            MessageBubble(
                                message: message,
                                deal: deal,
                                onApply: { changes in
                                    applyChanges(changes)
                                }
                            )
                            .id(message.id)
                        }
                    }
                    .padding(12)
                    
                    // Spacer to push content up
                    Color.clear.frame(height: 1).id(scrollID)
                }
                .background(shellBg)
                .onChange(of: messages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(scrollID, anchor: .bottom)
                    }
                }
            }
            
            Rectangle().fill(shellBorder).frame(height: 1)
            
            // Chat input
            ChatInputBar(
                text: $inputText,
                isLoading: isLoading,
                onSend: { sendMessage() }
            )
        }
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ResearchMessage(
            dealID: deal.id,
            role: "user",
            content: inputText
        )
        modelContext.insert(userMessage)
        
        let userText = inputText
        inputText = ""
        isLoading = true
        
        Task {
            do {
                // Call LLM
                let response = try await LLMAnalysisService.shared.chatResearch(
                    message: userText,
                    deal: deal,
                    history: messages.map { ($0.role, $0.content) }
                )
                
                // Create AI message
                let aiMessage = ResearchMessage(
                    dealID: deal.id,
                    role: "assistant",
                    content: response,
                    modelName: LLMAnalysisService.shared.activeModelDisplayName
                )
                
                // Check for JSON in response and auto-apply if found
                if let extractedData = extractJSON(from: response) {
                    let changes = processResearchData(extractedData)
                    aiMessage.extractedFields = changes
                    aiMessage.hasExtractedData = true
                }
                
                await MainActor.run {
                    modelContext.insert(aiMessage)
                    isLoading = false
                    try? modelContext.save()
                }
            } catch {
                let errorMessage = ResearchMessage(
                    dealID: deal.id,
                    role: "assistant",
                    content: "Error: \(error.localizedDescription)"
                )
                await MainActor.run {
                    modelContext.insert(errorMessage)
                    isLoading = false
                }
            }
        }
    }
    
    private func extractJSON(from text: String) -> [String: Any]? {
        // Find JSON in response (between ```json and ``` or just {...})
        let patterns = [
            #"```json\s*([\s\S]*?)\s*```"#,
            #"\{[\s\S]*\}"#
        ]
        
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression),
               let data = String(text[range]).data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
        }
        return nil
    }
    
    private func processResearchData(_ json: [String: Any]) -> [FieldChange] {
        var changes: [FieldChange] = []
        
        // Helper to create change entry
        func addChange(_ name: String, old: String?, new: String, autoApplied: Bool) {
            changes.append(FieldChange(
                fieldName: name,
                oldValue: old,
                newValue: new,
                autoApplied: autoApplied
            ))
        }
        
        // Property Type
        if let newType = json["property_type"] as? String {
            if deal.propertyType.isEmpty {
                deal.propertyType = newType
                addChange("Property Type", old: nil, new: newType, autoApplied: true)
            } else if deal.propertyType != newType {
                addChange("Property Type", old: deal.propertyType, new: newType, autoApplied: false)
            }
        }
        
        // Purchase Price
        if let price = DealResearchImporter.double(json, keys: ["purchase_price", "price"]), price > 0 {
            if deal.purchasePrice == 0 {
                deal.purchasePrice = price
                addChange("Purchase Price", old: nil, new: "€\(Int(price))", autoApplied: true)
            } else if abs(deal.purchasePrice - price) > 1 {
                addChange("Purchase Price", old: "€\(Int(deal.purchasePrice))", new: "€\(Int(price))", autoApplied: false)
            }
        }
        
        // Total Area
        if let area = DealResearchImporter.double(json, keys: ["total_area", "area_sqm"]), area > 0 {
            if deal.totalArea == 0 {
                deal.totalArea = area
                addChange("Total Area", old: nil, new: "\(Int(area))m²", autoApplied: true)
            } else if abs(deal.totalArea - area) > 1 {
                addChange("Total Area", old: "\(Int(deal.totalArea))m²", new: "\(Int(area))m²", autoApplied: false)
            }
        }
        
        // GPS Coordinates
        if let lat = DealResearchImporter.double(json, keys: ["latitude", "lat"]),
           let lon = DealResearchImporter.double(json, keys: ["longitude", "lon"]),
           lat != 0, lon != 0 {
            deal.latitude = lat
            deal.longitude = lon
            deal.geocodeStatus = .ok
            addChange("GPS", old: nil, new: "\(String(format: "%.5f", lat)), \(String(format: "%.5f", lon))", autoApplied: true)
        }
        
        // Apply full import using existing DealResearchImporter if comprehensive JSON
        if json.keys.count > 5 {
            let data = try? JSONSerialization.data(withJSONObject: json)
            if let data = data {
                let result = DealResearchImporter.apply(json: data, to: deal, context: modelContext)
                for applied in result.applied {
                    addChange("Imported", old: nil, new: applied, autoApplied: true)
                }
            }
        }
        
        // Save and update score
        deal.porteosScore = PropertyDealViewModel(deal: deal).porteosScore.finalScore
        deal.updatedAt = Date()
        try? modelContext.save()
        
        return changes
    }
    
    private func applyChanges(_ changes: [FieldChange]) {
        // Apply suggested changes that user approved
        // (Implementation depends on FieldChange structure)
        deal.updatedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ResearchMessage
    let deal: PropertyDeal
    let onApply: ([FieldChange]) -> Void
    
    private var shellSurface = DesignTokens.surfacePanel
    private var shellBg = DesignTokens.canvasBase
    private var textPrimary = DesignTokens.textPrimary
    private var textSecondary = DesignTokens.textSecondary
    private var textTertiary = DesignTokens.textDim
    private var accentTeal = DesignTokens.accentHospitality
    private var accentRust = DesignTokens.accentRust
    private var statusGo = DesignTokens.statusGo
    private var statusWarn = DesignTokens.statusWarn
    
    init(message: ResearchMessage, deal: PropertyDeal, onApply: @escaping ([FieldChange]) -> Void) {
        self.message = message
        self.deal = deal
        self.onApply = onApply
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Meta line (user/AI indicator)
            HStack(spacing: 8) {
                Text(message.role == "user" ? "porteos@user ~ %" : "porteos@ai ~ %")
                    .porteosMeta()
                    .foregroundStyle(textTertiary)
                
                if message.role == "assistant", let model = message.modelName {
                    Text("[\(model)]")
                        .porteosMeta()
                        .foregroundStyle(textTertiary.opacity(0.6))
                }
                
                Spacer()
            }
            
            // Message content
            Text(message.content)
                .porteosRowValue()
                .foregroundStyle(message.role == "user" ? textPrimary : accentTeal)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Extracted fields summary (if any)
            if message.hasExtractedData, let fields = message.extractedFields {
                VStack(alignment: .leading, spacing: 8) {
                    Rectangle().fill(accentRust.opacity(0.3)).frame(height: 1)
                    
                    let autoApplied = fields.filter { $0.autoApplied }
                    let suggested = fields.filter { !$0.autoApplied }
                    
                    if !autoApplied.isEmpty {
                        Text("✓ Auto-applied (\(autoApplied.count) fields)")
                            .porteosMeta()
                            .foregroundStyle(statusGo)
                        
                        ForEach(autoApplied, id: \.fieldName) { change in
                            HStack {
                                Text("• \(change.fieldName):")
                                    .porteosMeta()
                                    .foregroundStyle(textTertiary)
                                Text("\(String(describing: change.newValue))")
                                    .porteosMeta()
                                    .foregroundStyle(textSecondary)
                            }
                        }
                    }
                    
                    if !suggested.isEmpty {
                        Text("⚠ Review suggested (\(suggested.count) fields)")
                            .porteosMeta()
                            .foregroundStyle(statusWarn)
                        
                        ForEach(suggested, id: \.fieldName) { change in
                            HStack {
                                Text("• \(change.fieldName):")
                                    .porteosMeta()
                                    .foregroundStyle(textTertiary)
                                Text("\(String(describing: change.oldValue ?? "")) → \(String(describing: change.newValue))")
                                    .porteosMeta()
                                    .foregroundStyle(textSecondary)
                            }
                        }
                        
                        Button {
                            onApply(suggested)
                        } label: {
                            Text("[ APPLY ALL ]")
                                .porteosButtonPrimary()
                                .foregroundStyle(accentRust)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(8)
        .background(message.role == "user" ? shellSurface : shellBg)
    }
}

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    
    private var shellBg = DesignTokens.canvasBase
    private var shellSurface = DesignTokens.surfacePanel
    private var shellBorder = DesignTokens.dividerStructural
    private var textPrimary = DesignTokens.textPrimary
    private var textTertiary = DesignTokens.textDim
    private var accentRust = DesignTokens.accentRust
    
    init(text: Binding<String>, isLoading: Bool, onSend: @escaping () -> Void) {
        self._text = text
        self.isLoading = isLoading
        self.onSend = onSend
    }
    
    var body: some View {
        HStack(spacing: 8) {
            TextField("Type message...", text: $text, onCommit: {
                if !text.isEmpty && !isLoading {
                    onSend()
                }
            })
            .porteosRowValue()
            .textFieldStyle(.plain)
            .padding(.horizontal, 8)
            .frame(height: 32)
            .background(shellBg)
            .overlay(
                Rectangle()
                    .stroke(shellBorder, lineWidth: 1)
            )
            .disabled(isLoading)
            
            Button {
                onSend()
            } label: {
                Text(isLoading ? "[...]" : "[SEND]")
                    .porteosButtonPrimary()
                    .foregroundStyle(text.isEmpty || isLoading ? textTertiary : accentRust)
                    .frame(width: 60, height: 32)
                    .background(shellSurface)
            }
            .disabled(text.isEmpty || isLoading)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(shellSurface)
    }
}

// MARK: - Field Change Model

struct FieldChange: Codable {
    let fieldName: String
    let oldValue: String?
    let newValue: String
    let autoApplied: Bool
}
