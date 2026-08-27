import Foundation
import SwiftData

// MARK: - ResearchMessage
// Stores AI research chat messages per deal.
// Messages are deleted when deal is deleted (cascade).

@Model
final class ResearchMessage {
    
    @Attribute(.unique) var id: UUID
    var dealID: UUID              // Links to PropertyDeal
    var role: String              // "user" or "assistant"
    var content: String           // Message text
    var modelName: String?        // e.g. "phi4-mini", "gpt-4o", "gemini-3.5-flash"
    var timestamp: Date
    var hasExtractedData: Bool    // True if contains extractable JSON/fields
    var extractedFields: [FieldChange]?  // Auto-applied and suggested changes
    
    init(dealID: UUID, role: String, content: String, modelName: String? = nil) {
        self.id = UUID()
        self.dealID = dealID
        self.role = role
        self.content = content
        self.modelName = modelName
        self.timestamp = Date()
        self.hasExtractedData = false
        self.extractedFields = nil
    }
}
