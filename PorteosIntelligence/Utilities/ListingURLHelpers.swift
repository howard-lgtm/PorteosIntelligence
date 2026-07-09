import Foundation

enum ListingURLHelpers {

    /// Canonical key for dedup — strips tracking params, trailing slash, lowercases host.
    static func normalize(_ urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed) else {
            return trimmed.lowercased()
        }

        components.fragment = nil
        if let items = components.queryItems, !items.isEmpty {
            let tracking = Set([
                "utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term",
                "fbclid", "gclid", "ref", "source"
            ])
            components.queryItems = items.filter { !tracking.contains($0.name.lowercased()) }
            if components.queryItems?.isEmpty == true { components.queryItems = nil }
        }

        if components.path.hasSuffix("/"), components.path.count > 1 {
            components.path = String(components.path.dropLast())
        }

        return components.string?.lowercased() ?? trimmed.lowercased()
    }

    /// Reads `URL: …` line written by browser/email import pipelines.
    static func extractFromNotes(_ notes: String) -> String? {
        for line in notes.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.uppercased().hasPrefix("URL:") else { continue }
            let url = trimmed.dropFirst(4).trimmingCharacters(in: .whitespaces)
            return url.isEmpty ? nil : String(url)
        }
        return nil
    }
}
