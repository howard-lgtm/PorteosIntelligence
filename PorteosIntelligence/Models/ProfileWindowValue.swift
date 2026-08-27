import Foundation

// MARK: - ProfileWindowValue
// Typed value passed to the profile WindowGroup scene via openWindow(value:).
// Carries the deal ID and profile identifier so each window is self-contained.

struct ProfileWindowValue: Hashable, Codable {
    var dealID:  UUID
    var profile: String   // "realEstate" | "hospitality" | "design" | "circular"
}
