import Foundation
import SwiftData

// MARK: - DealScenario
//
// A SwiftData model that persists a named snapshot of sensitivity adjustment
// values for a specific deal and profile. Adjustments are serialised to JSON
// so that the flexible [String: Double] dictionary survives SwiftData storage.

@Model
final class DealScenario {

    // ── Identity ───────────────────────────────────────────────────────────────
    @Attribute(.unique) var id:        UUID
    var dealID:                        UUID
    var name:                          String
    var profile:                       String   // "realEstate" | "hospitality" | "design" | "circular"
    var createdAt:                     Date
    var notes:                         String   // empty string instead of nil for SwiftData compat

    // ── Adjustments (JSON-encoded for SwiftData compatibility) ─────────────────
    // Externally accessed as [String: Double] via the computed property below.
    var adjustmentsJSON: String

    // MARK: - Computed helpers

    var adjustments: [String: Double] {
        get {
            guard
                let data = adjustmentsJSON.data(using: .utf8),
                let dict = try? JSONDecoder().decode([String: Double].self, from: data)
            else { return [:] }
            return dict
        }
        set {
            let encoded = (try? JSONEncoder().encode(newValue)).flatMap {
                String(data: $0, encoding: .utf8)
            }
            adjustmentsJSON = encoded ?? "{}"
        }
    }

    // MARK: - Init

    init(
        dealID:      UUID,
        name:        String,
        profile:     String,
        adjustments: [String: Double],
        notes:       String = ""
    ) {
        self.id       = UUID()
        self.dealID   = dealID
        self.name     = name
        self.profile  = profile
        self.createdAt = Date()
        self.notes    = notes

        let encoded = (try? JSONEncoder().encode(adjustments)).flatMap {
            String(data: $0, encoding: .utf8)
        }
        self.adjustmentsJSON = encoded ?? "{}"
    }
}
