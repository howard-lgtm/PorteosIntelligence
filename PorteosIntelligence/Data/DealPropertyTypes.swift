import Foundation

// MARK: - DealPropertyTypes
// Shared property-type vocabulary for Quick Add, Full Edit, and email ingestion.
// Named DealPropertyTypes to avoid colliding with SDK symbols named PropertyTypes.

struct DealPropertyTypes {

    static let defaults: [String] = [
        "Apartment",
        "Multi-Dwelling",
        "Commercial",
        "Hotel",
        "Office",
        "Residential",
        "Mixed-Use",
        "Hospitality",
        "Industrial",
        "Retail",
        "Warehouse",
        "Land",
        "Other",
    ]

    /// Case-insensitive prefix match; returns up to `limit` suggestions.
    static func suggestions(matching query: String, limit: Int = 8) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return Array(defaults.prefix(limit)) }

        let needle = trimmed.lowercased()
        let ranked = defaults.filter { $0.lowercased().contains(needle) }
        if ranked.count >= limit { return Array(ranked.prefix(limit)) }

        let extras = ingestionAliases
            .filter { $0.lowercased().contains(needle) && !ranked.contains($0) }
        return Array((ranked + extras).prefix(limit))
    }

    private static let ingestionAliases: [String] = [
        "Apartment", "Hotel", "Office", "Villa", "Townhouse", "Studio",
    ]
}
