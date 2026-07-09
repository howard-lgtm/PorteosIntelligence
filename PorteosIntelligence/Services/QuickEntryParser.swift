import Foundation

// MARK: - QuickEntryResult

struct QuickEntryResult {
    var propertyName:   String
    var location:       String
    var purchasePrice:  Double
    var currency:       String   = "EUR"   // "EUR" | "USD" | "SEK"
    var totalArea:      Double   = 0
    var bedrooms:       Int?
    var propertyType:   String   = "Apartment"
    var sourceURL:      String?
    var notes:          String   = ""
    var confidence:     Confidence

    // Derived on-save
    var estimatedGPI:   Double   = 0       // gross potential income estimate
    var vacancyRate:    Double   = 5.0     // default 5 %
    var opex:           Double   = 0       // estimated opex

    enum Confidence { case high, medium, low }

    /// Human-readable price string for display.
    var priceLabel: String {
        let sym = currency == "USD" ? "$" : (currency == "SEK" ? "" : "€")
        let suf = currency == "SEK" ? " kr" : ""
        if purchasePrice >= 1_000_000 {
            return "\(sym)\(String(format: "%.2f", purchasePrice / 1_000_000))M\(suf)"
        }
        return "\(sym)\(Int(purchasePrice).formatted())\(suf)"
    }
}

// MARK: - QuickEntryParser

enum QuickEntryParser {

    // MARK: Public entry point

    static func parse(_ input: String) -> QuickEntryResult? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if isURL(trimmed) {
            return parseURL(trimmed)
        } else {
            return parseText(trimmed)
        }
    }

    // MARK: URL detection

    static func isURL(_ text: String) -> Bool {
        text.lowercased().hasPrefix("http://") || text.lowercased().hasPrefix("https://") ||
        (text.contains(".com") || text.contains(".pt") || text.contains(".se") || text.contains(".es")) &&
        text.contains("/")
    }

    // MARK: - Text parser

    static func parseText(_ text: String) -> QuickEntryResult? {
        var remaining = text

        // 1. Price + currency
        let (price, currency, priceRange) = extractPrice(from: remaining)
        if let r = priceRange { remaining = remaining.replacingCharacters(in: r, with: " ") }

        // 2. Area
        let (area, areaRange) = extractArea(from: remaining)
        if let r = areaRange { remaining = remaining.replacingCharacters(in: r, with: " ") }

        // 3. Bedrooms / type token
        let (bedrooms, bedroomRange) = extractBedrooms(from: remaining)
        if let r = bedroomRange { remaining = remaining.replacingCharacters(in: r, with: " ") }

        // 4. Property type keyword
        let propType = extractPropertyType(from: text)

        // 5. Location — what's left after removing parsed tokens
        let location = extractLocation(from: remaining) ?? "Unknown"

        guard price > 0 else { return nil }

        // 6. Derived estimates
        var gpi  = 0.0
        var opex = 0.0
        if area > 0 {
            // Rough estimate: €12/m²/month for European residential
            let monthlyRentEstimate = area * (currency == "USD" ? 14 : 12)
            gpi  = monthlyRentEstimate * 12
            opex = gpi * 0.30
        } else if price > 0 {
            // Assume 4% gross yield
            gpi  = price * 0.04
            opex = gpi  * 0.30
        }

        let confidence: QuickEntryResult.Confidence =
            (price > 0 && area > 0 && location != "Unknown") ? .high :
            (price > 0 && location != "Unknown") ? .medium : .low

        let propName = buildName(type: propType, bedrooms: bedrooms, location: location)

        return QuickEntryResult(
            propertyName:  propName,
            location:      location,
            purchasePrice: price,
            currency:      currency,
            totalArea:     area,
            bedrooms:      bedrooms,
            propertyType:  propType,
            sourceURL:     nil,
            notes:         "Quick-add: \"\(text)\"",
            confidence:    confidence,
            estimatedGPI:  gpi,
            vacancyRate:   5.0,
            opex:          opex
        )
    }

    // MARK: - URL parser

    static func parseURL(_ urlString: String) -> QuickEntryResult? {
        guard let url = URL(string: urlString) else { return nil }
        let host   = url.host?.lowercased() ?? ""
        let path   = url.path.lowercased()
        var source = "web"
        var location = "Unknown"
        var propType = "Apartment"

        if host.contains("idealista") {
            source = "idealista"
            location = extractIdealistaLocation(from: path)
        } else if host.contains("zillow") {
            source = "zillow"
            location = extractZillowLocation(from: path)
        } else if host.contains("hemnet") {
            source = "hemnet"
            location = "Sweden"
            propType = extractHemnetType(from: path)
        } else if host.contains("rightmove") {
            source = "rightmove"
            location = "United Kingdom"
        } else if host.contains("immobiliare") {
            source = "immobiliare"
            location = "Italy"
        }

        let propName = "URL Import: \(source.capitalized) — \(location)"

        return QuickEntryResult(
            propertyName:  propName,
            location:      location,
            purchasePrice: 0,              // unknown from URL alone
            currency:      "EUR",
            totalArea:     0,
            bedrooms:      nil,
            propertyType:  propType,
            sourceURL:     urlString,
            notes:         "Quick-add URL: \(urlString)",
            confidence:    .low,
            estimatedGPI:  0,
            vacancyRate:   5.0,
            opex:          0
        )
    }

    // MARK: - Price extraction

    private static func extractPrice(from text: String) -> (Double, String, Range<String.Index>?) {
        // Try each pattern; first match wins
        let patterns: [(pattern: String, multiplier: Double, currency: String)] = [
            ("€\\s*([0-9]+(?:[.,][0-9]{3})*)(?:\\s*[kK])",  1_000,       "EUR"),
            ("€\\s*([0-9]+(?:[.,][0-9]{1,2})?)\\s*[Mm]",    1_000_000,   "EUR"),
            ("([0-9]+(?:[.,][0-9]{3})*)(?:\\s*[kK])\\s*€",  1_000,       "EUR"),
            ("([0-9]+(?:[.,][0-9]{1,2})?)\\s*[Mm]\\s*€",    1_000_000,   "EUR"),
            ("€\\s*([0-9]+(?:[.,][0-9]{3})*(?:[.,][0-9]{1,2})?)", 1,     "EUR"),
            ("([0-9]+(?:[.,][0-9]{3})*(?:[.,][0-9]{1,2})?)\\s*€", 1,     "EUR"),
            ("\\$\\s*([0-9]+(?:,[0-9]{3})*)(?:\\s*[kK])",   1_000,       "USD"),
            ("\\$\\s*([0-9]+(?:,[0-9]{1,2})?)\\s*[Mm]",     1_000_000,   "USD"),
            ("\\$\\s*([0-9]+(?:,[0-9]{3})*(?:\\.[0-9]{1,2})?)", 1,       "USD"),
            ("([0-9][0-9 ]+)\\s+kr(?:[^a-z]|$)",            1,           "SEK"),
        ]

        for (pattern, multiplier, curr) in patterns {
            guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let m  = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { continue }

            let captureRange = m.numberOfRanges > 1 ? m.range(at: 1) : m.range
            guard let r = Range(captureRange, in: text) else { continue }

            let cleaned = cleanNumericString(String(text[r]))
            if let val = Double(cleaned), val > 0 {
                let fullRange = Range(m.range, in: text)
                return (val * multiplier, curr, fullRange)
            }
        }
        return (0, "EUR", nil)
    }

    // Strips thousand-separator dots/commas, keeping the decimal part.
    private static func cleanNumericString(_ raw: String) -> String {
        let stripped = raw.replacingOccurrences(of: " ", with: "")
        // Handle European format: 350.000 → 350000, 350,000 → 350000
        // But 1.5 (decimal) should stay 1.5
        let dotCount = stripped.components(separatedBy: ".").count - 1

        if dotCount == 1 && stripped.components(separatedBy: ".").last?.count == 2 {
            // Likely decimal: 350.00 or 1.25 → keep dot
            return stripped.replacingOccurrences(of: ",", with: "")
        }
        // Otherwise treat all dots and commas as thousand separators
        return stripped
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
    }

    // MARK: - Area extraction

    private static func extractArea(from text: String) -> (Double, Range<String.Index>?) {
        let patterns = [
            "([0-9]+(?:[.,][0-9]+)?)\\s*m²",
            "([0-9]+(?:[.,][0-9]+)?)\\s*m2",
            "([0-9]+(?:[.,][0-9]+)?)\\s*sqm",
            "([0-9]+(?:[.,][0-9]+)?)\\s*sq\\.?\\s*m",
            "([0-9]+(?:[.,][0-9]+)?)\\s*sq\\s*ft",   // sq ft → convert
            "([0-9]+(?:[.,][0-9]+)?)\\s*sf",
        ]
        let isSqFt = [false, false, false, false, true, true]

        for (i, pattern) in patterns.enumerated() {
            guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let m  = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let r  = Range(m.range(at: 1), in: text),
                  let fullR = Range(m.range, in: text) else { continue }

            let raw = String(text[r]).replacingOccurrences(of: ",", with: ".")
            if var val = Double(raw), val > 0 {
                if isSqFt[i] { val *= 0.0929 }  // convert sqft → m²
                return (val, fullR)
            }
        }
        return (0, nil)
    }

    // MARK: - Bedrooms extraction

    private static func extractBedrooms(from text: String) -> (Int?, Range<String.Index>?) {
        let patterns = [
            "T([0-9])",                     // Portuguese/French: T2, T3
            "([0-9]+)\\s*BR",              // 3BR, 2BR
            "([0-9]+)\\s*bd",              // 3bd
            "([0-9]+)\\s*bedroom",         // 3 bedroom
            "([0-9]+)\\s*-?\\s*zimmer",   // German: 3-Zimmer
            "([0-9]+)\\s*rum",             // Swedish: 4 rum
        ]

        for pattern in patterns {
            guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let m  = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let r  = Range(m.range(at: 1), in: text),
                  let fullR = Range(m.range, in: text),
                  let beds = Int(text[r]) else { continue }
            return (beds, fullR)
        }
        return (nil, nil)
    }

    // MARK: - Property type extraction

    private static func extractPropertyType(from text: String) -> String {
        let lower = text.lowercased()
        let map: [(String, String)] = [
            ("studio",      "Studio"),
            ("apartamento", "Apartment"), ("apartment", "Apartment"),
            ("piso",        "Apartment"), ("flat", "Apartment"),
            ("moradia",     "House"),     ("vivenda", "House"),
            ("house",       "House"),     ("villa",   "House"),
            ("casa",        "House"),
            ("escritório",  "Office"),    ("office",  "Office"),
            ("loja",        "Retail"),    ("retail",  "Retail"),
            ("hotel",       "Hotel"),
            ("garage",      "Garage"),    ("garagem", "Garage"),
        ]
        for (kw, label) in map {
            if lower.contains(kw) { return label }
        }
        // T0 = studio, T1+ = apartment
        if let re = try? NSRegularExpression(pattern: "\\bT([0-9])\\b", options: .caseInsensitive),
           let m  = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let r  = Range(m.range(at: 1), in: text),
           let n  = Int(text[r]) {
            return n == 0 ? "Studio" : "Apartment"
        }
        return "Apartment"
    }

    // MARK: - Location extraction

    private static func extractLocation(from text: String) -> String? {
        // Strip extra whitespace from removed tokens
        let cleaned = text
            .components(separatedBy: .whitespaces)
            .filter { !$0.trimmingCharacters(in: .punctuationCharacters).isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)

        guard !cleaned.isEmpty else { return nil }

        // Common city / country names we recognise explicitly
        let known = ["Lisbon", "Lisboa", "Porto", "Madrid", "Barcelona", "Valencia",
                     "Stockholm", "Gothenburg", "Göteborg", "Malmö",
                     "Berlin", "Munich", "München", "Hamburg",
                     "Paris", "Lyon", "Marseille",
                     "Amsterdam", "Rotterdam",
                     "London", "Manchester", "Edinburgh",
                     "Rome", "Roma", "Milan", "Milano", "Florence",
                     "Prague", "Vienna", "Budapest", "Warsaw",
                     "Dubai", "New York", "Los Angeles", "Miami", "Chicago",
                     "Algarve", "Cascais", "Sintra", "Setúbal"]
        for city in known {
            if cleaned.localizedCaseInsensitiveContains(city) { return city }
        }

        // Fall back: first sequence of Title-Case words
        let pattern = "[A-ZÀÁÂÃÈÉÊÌÍÎÒÓÔÕÙÚÛÜ][a-zàáâãèéêìíîòóôõùúûü]{2,}(?:\\s+[A-ZÀÁÂÃÈÉÊÌÍÎÒÓÔÕÙÚÛÜ][a-zàáâãèéêìíîòóôõùúûü]{2,})*"
        if let re = try? NSRegularExpression(pattern: pattern),
           let m  = re.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
           let r  = Range(m.range, in: cleaned) {
            return String(cleaned[r])
        }
        return nil
    }

    // MARK: - URL location helpers

    private static func extractIdealistaLocation(from path: String) -> String {
        // /venta-viviendas/barcelona-capital/ → Barcelona
        // /imoveis/lisboa/ → Lisbon
        let components = path.components(separatedBy: "/").filter { !$0.isEmpty }
        for comp in components {
            // Skip known non-location segments
            let skip = ["venta-viviendas", "alquiler", "imoveis", "imovel", "inmueble",
                        "casas", "comprar", "arrendar", "t1", "t2", "t3", "t4"]
            if skip.contains(comp) { continue }
            if comp.count < 3 { continue }
            // Capitalise first letter and clean hyphens
            let clean = comp.components(separatedBy: "-").first ?? comp
            return clean.prefix(1).uppercased() + clean.dropFirst()
        }
        return "Portugal"
    }

    private static func extractZillowLocation(from path: String) -> String {
        // /homes/for_sale/Seattle-WA/ or /homedetails/123-Main-St-Seattle-WA
        let parts = path.components(separatedBy: "/").filter { !$0.isEmpty }
        for part in parts {
            if part.contains("-") {
                let words = part.components(separatedBy: "-").filter { $0.count > 1 }
                let location = words.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
                if location.count > 3 { return location }
            }
        }
        return "United States"
    }

    private static func extractHemnetType(from path: String) -> String {
        if path.contains("villa") { return "House" }
        if path.contains("lagenhet") || path.contains("lgh") { return "Apartment" }
        return "Apartment"
    }

    // MARK: - Name builder

    private static func buildName(type: String, bedrooms: Int?, location: String) -> String {
        var parts: [String] = []
        if let b = bedrooms {
            parts.append(b == 0 ? "Studio" : "\(b)-bed \(type)")
        } else {
            parts.append(type)
        }
        if location != "Unknown" { parts.append("in \(location)") }
        return parts.joined(separator: " ")
    }
}
