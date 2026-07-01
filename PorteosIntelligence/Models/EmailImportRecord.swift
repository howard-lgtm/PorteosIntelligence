import Foundation
import SwiftData

/// Tracks every listing URL already imported so the pipeline never creates duplicates.
@Model
final class EmailImportRecord {

    /// Unique listing URL used as the dedup key.
    @Attribute(.unique) var listingURL: String

    var importedAt: Date
    /// The deal created from this import (nil if creation failed or was skipped).
    var dealID: UUID?
    /// "idealista" | "zillow" | "hemnet" | "generic"
    var source: String
    var rawSubject: String

    init(
        listingURL: String,
        source: String,
        rawSubject: String,
        dealID: UUID? = nil
    ) {
        self.listingURL  = listingURL
        self.importedAt  = Date()
        self.source      = source
        self.rawSubject  = rawSubject
        self.dealID      = dealID
    }
}
