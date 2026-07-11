import Foundation

// MARK: - ParsedListing

/// Data extracted from a single real-estate alert email.
struct ParsedListing {
    var propertyName:  String
    var location:      String
    var price:         Double          // raw numeric value in originating currency
    var currency:      String          // "EUR" | "USD" | "SEK"
    var listingURL:    String?
    var source:        String          // parser source label
    var rawSubject:    String
    var propertyType:  String          = "Apartment"
    var areaSqM:       Double?
    var bedrooms:      Int?
}

// MARK: - Protocol

protocol ListingEmailParser {
    var sourceName: String { get }
    /// Returns `true` when this parser should handle the message.
    func canParse(subject: String, senderDomain: String) -> Bool
    /// Returns `nil` when extraction fails (too little data to create a usable deal).
    func parse(subject: String, body: String) -> ParsedListing?
}

// MARK: - Shared extraction helpers (file-private)

/// Extracts the first URL whose host contains `domain`.
private func extractURL(from text: String, containing domain: String) -> String? {
    let pattern = "https?://[^\\s\"'<>]*\(NSRegularExpression.escapedPattern(for: domain))[^\\s\"'<>]*"
    guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
          let m  = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
          let r  = Range(m.range, in: text) else { return nil }
    return String(text[r])
}

/// Generic URL extractor — returns the first https link found anywhere in the text.
private func extractAnyURL(from text: String) -> String? {
    let pattern = "https?://[^\\s\"'<>]{10,}"
    guard let re = try? NSRegularExpression(pattern: pattern),
          let m  = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
          let r  = Range(m.range, in: text) else { return nil }
    return String(text[r])
}

/// Parses European-format euro prices: "350.000 €", "€ 1.250.000", "650000€".
private func parseEuroPrice(from text: String) -> Double? {
    let patterns = [
        "([0-9]+(?:[.,][0-9]{3})+(?:[.,][0-9]{1,2})?)\\s*€",
        "€\\s*([0-9]+(?:[.,][0-9]{3})+(?:[.,][0-9]{1,2})?)",
        "([0-9]{5,9})\\s*€",
        "€\\s*([0-9]{5,9})",
    ]
    for pattern in patterns {
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m  = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r  = Range(m.range(at: 1), in: text) else { continue }
        let raw = String(text[r])
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        if let v = Double(raw), v > 1_000 { return v }
    }
    return nil
}

/// Parses US dollar prices: "$450,000", "$1.2M", "$1,200,000".
private func parseDollarPrice(from text: String) -> Double? {
    let patterns: [(String, Double)] = [
        ("\\$([0-9,]+)", 1),
        ("\\$([0-9.]+)[Mm]", 1_000_000),
        ("\\$([0-9.]+)[Kk]", 1_000),
    ]
    for (pattern, multiplier) in patterns {
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m  = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r  = Range(m.range(at: 1), in: text) else { continue }
        let raw = String(text[r]).replacingOccurrences(of: ",", with: "")
        if let v = Double(raw), v > 0 { return v * multiplier }
    }
    return nil
}

/// Parses Swedish krona prices: "5 500 000 kr", "3 250 000 kronor".
private func parseKronaPrice(from text: String) -> Double? {
    let pattern = "([0-9][0-9 ]+)\\s+(?:kr|kronor)"
    guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
          let m  = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
          let r  = Range(m.range(at: 1), in: text) else { return nil }
    let raw = String(text[r]).replacingOccurrences(of: " ", with: "")
    if let v = Double(raw), v > 10_000 { return v }
    return nil
}

/// Extracts an integer bedroom count from patterns like "3bd", "3BR", "3 rum", "T2", "T3".
private func parseBedrooms(from text: String) -> Int? {
    let patterns = ["(\\d+)(?:bd|BR|bed)", "(\\d+)\\s+rum", "[Tt](\\d+)(?:[^\\d]|$)"]
    for pattern in patterns {
        guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let m  = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r  = Range(m.range(at: 1), in: text),
              let v  = Int(text[r]) else { continue }
        return v
    }
    return nil
}

/// Extracts property type keyword (returns English label).
private func parsePropertyType(from text: String) -> String {
    let lower = text.lowercased()
    let map: [(String, String)] = [
        ("apartamento", "Apartment"), ("piso", "Apartment"), ("flat", "Apartment"),
        ("apartment", "Apartment"), ("lägenhet", "Apartment"),
        ("moradia", "House"), ("vivenda", "House"), ("house", "House"), ("villa", "House"),
        ("casa", "House"), ("villa", "House"),
        ("escritório", "Office"), ("office", "Office"), ("kontor", "Office"),
        ("loja", "Retail"), ("retail", "Retail"), ("butik", "Retail"),
        ("hotel", "Hotel"), ("boutique", "Hotel"),
        ("garagem", "Garage"), ("parking", "Garage"),
    ]
    for (keyword, label) in map {
        if lower.contains(keyword) { return label }
    }
    return "Apartment"
}

// MARK: - Idealista Parser

struct IdealistaEmailParser: ListingEmailParser {
    let sourceName = "idealista"

    func canParse(subject: String, senderDomain: String) -> Bool {
        senderDomain.contains("idealista.com") ||
        senderDomain.contains("idealista.pt") ||
        subject.lowercased().contains("idealista")
    }

    func parse(subject: String, body: String) -> ParsedListing? {
        guard let price = parseEuroPrice(from: subject) ?? parseEuroPrice(from: body) else { return nil }

        // Location: after "em " (PT) or "en " (ES) or "in " (EN)
        var location = "Portugal"
        let locPatterns = ["\\bem\\s+([A-ZÀ-Ú][a-zà-ú\\-]+(?: [A-ZÀ-Ú][a-zà-ú\\-]+)*)",
                           "\\ben\\s+([A-ZÀ-Ú][a-zà-ú\\-]+(?: [A-ZÀ-Ú][a-zà-ú\\-]+)*)",
                           "\\bin\\s+([A-Z][a-z\\-]+(?: [A-Z][a-z\\-]+)*)"]
        for pattern in locPatterns {
            if let re = try? NSRegularExpression(pattern: pattern),
               let m  = re.firstMatch(in: subject, range: NSRange(subject.startIndex..., in: subject)),
               let r  = Range(m.range(at: 1), in: subject) {
                location = String(subject[r])
                break
            }
        }

        let url = extractURL(from: body, containing: "idealista.") ?? extractURL(from: body, containing: "idealista")
        let type = parsePropertyType(from: subject)
        let beds = parseBedrooms(from: subject)

        return ParsedListing(
            propertyName: "Idealista: \(type) in \(location)",
            location:     location,
            price:        price,
            currency:     "EUR",
            listingURL:   url,
            source:       sourceName,
            rawSubject:   subject,
            propertyType: type,
            bedrooms:     beds
        )
    }
}

// MARK: - Zillow Parser

struct ZillowEmailParser: ListingEmailParser {
    let sourceName = "zillow"

    func canParse(subject: String, senderDomain: String) -> Bool {
        senderDomain.contains("zillow.com") ||
        subject.lowercased().contains("zillow")
    }

    func parse(subject: String, body: String) -> ParsedListing? {
        guard let price = parseDollarPrice(from: subject) ?? parseDollarPrice(from: body) else { return nil }

        // Location: "in Seattle, WA" or "in Brooklyn, NY"
        var location = "United States"
        let locPattern = "\\bin\\s+([A-Z][a-z]+(?:[\\s,]+[A-Z][A-Za-z]+)*)"
        if let re = try? NSRegularExpression(pattern: locPattern),
           let m  = re.firstMatch(in: subject, range: NSRange(subject.startIndex..., in: subject)),
           let r  = Range(m.range(at: 1), in: subject) {
            location = String(subject[r])
                .trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        }

        let url  = extractURL(from: body, containing: "zillow.com")
        let type = parsePropertyType(from: subject)
        let beds = parseBedrooms(from: subject)

        return ParsedListing(
            propertyName: "Zillow: \(type) in \(location)",
            location:     location,
            price:        price,
            currency:     "USD",
            listingURL:   url,
            source:       sourceName,
            rawSubject:   subject,
            propertyType: type,
            bedrooms:     beds
        )
    }
}

// MARK: - Hemnet Parser

struct HemnetEmailParser: ListingEmailParser {
    let sourceName = "hemnet"

    func canParse(subject: String, senderDomain: String) -> Bool {
        senderDomain.contains("hemnet.se") ||
        subject.lowercased().contains("hemnet")
    }

    func parse(subject: String, body: String) -> ParsedListing? {
        guard let price = parseKronaPrice(from: subject) ?? parseKronaPrice(from: body) else { return nil }

        // Swedish location: "i Stockholm" or "i Göteborg"
        var location = "Sweden"
        let locPattern = "\\bi\\s+([A-ZÅÄÖ][a-zåäö]+(?:[\\s\\-][A-ZÅÄÖa-zåäö]+)*)"
        if let re = try? NSRegularExpression(pattern: locPattern),
           let m  = re.firstMatch(in: subject, range: NSRange(subject.startIndex..., in: subject)),
           let r  = Range(m.range(at: 1), in: subject) {
            location = String(subject[r])
        }

        let url  = extractURL(from: body, containing: "hemnet.se")
        let type = parsePropertyType(from: subject)
        let beds = parseBedrooms(from: subject)

        return ParsedListing(
            propertyName: "Hemnet: \(type) in \(location)",
            location:     location,
            price:        price,
            currency:     "SEK",
            listingURL:   url,
            source:       sourceName,
            rawSubject:   subject,
            propertyType: type,
            bedrooms:     beds
        )
    }
}

// MARK: - Generic Fallback Parser

/// Handles any real-estate alert email not matched by a platform-specific parser.
struct GenericListingEmailParser: ListingEmailParser {
    let sourceName = "generic"

    func canParse(subject: String, senderDomain: String) -> Bool {
        let lower = subject.lowercased()
        let keywords = ["listing", "property", "apartment", "house", "villa",
                        "imóvel", "piso", "alerta", "alert", "annons", "bevakning"]
        return keywords.contains { lower.contains($0) }
    }

    func parse(subject: String, body: String) -> ParsedListing? {
        let combined = subject + " " + body
        let price: Double
        let currency: String
        if let p = parseEuroPrice(from: combined) {
            price = p; currency = "EUR"
        } else if let p = parseDollarPrice(from: combined) {
            price = p; currency = "USD"
        } else if let p = parseKronaPrice(from: combined) {
            price = p; currency = "SEK"
        } else {
            return nil
        }

        let url  = extractAnyURL(from: body)
        let type = parsePropertyType(from: subject)

        // Pull a rough location from the subject (first Title-Cased word cluster)
        var location = "Unknown"
        let locPattern = "[A-ZÀÁÂÃÈÉÊÌÍÎÒÓÔÕÙÚÛÜ][a-zàáâãèéêìíîòóôõùúûü]{2,}(?:\\s+[A-ZÀÁÂÃÈÉÊÌÍÎÒÓÔÕÙÚÛÜ][a-zàáâãèéêìíîòóôõùúûü]{2,})*"
        if let re = try? NSRegularExpression(pattern: locPattern),
           let m  = re.firstMatch(in: subject, range: NSRange(subject.startIndex..., in: subject)),
           let r  = Range(m.range, in: subject) {
            location = String(subject[r])
        }

        // Attempt inference if location is still generic
        if location == "Unknown" {
            let inferred = DealIngestionServer.inferCity(
                name: subject, address: "", country: "", url: url ?? "")
            if !inferred.isEmpty { location = inferred }
        }

        return ParsedListing(
            propertyName: "Import: \(type) in \(location)",
            location:     location,
            price:        price,
            currency:     currency,
            listingURL:   url,
            source:       sourceName,
            rawSubject:   subject,
            propertyType: type
        )
    }
}

// MARK: - RE/MAX Portugal Parser

struct RemaxPTEmailParser: ListingEmailParser {
    let sourceName = "remax_pt"

    func canParse(subject: String, senderDomain: String) -> Bool {
        senderDomain.contains("remax.pt") ||
        subject.lowercased().contains("re/max") ||
        subject.lowercased().contains("remax")
    }

    func parse(subject: String, body: String) -> ParsedListing? {
        let combined = subject + " " + body
        guard let price = parseEuroPrice(from: combined) else { return nil }

        // RE/MAX Portugal uses Portuguese location patterns: "em Lisboa", "em Porto"
        var location = "Portugal"
        let locPatterns = [
            "\\bem\\s+([A-ZÀ-Ú][a-zà-ú\\-]+(?: [A-ZÀ-Ú][a-zà-ú\\-]+)*)",
            "\\bde\\s+([A-ZÀ-Ú][a-zà-ú\\-]+(?: [A-ZÀ-Ú][a-zà-ú\\-]+)*)",
        ]
        for pattern in locPatterns {
            if let re = try? NSRegularExpression(pattern: pattern),
               let m  = re.firstMatch(in: subject, range: NSRange(subject.startIndex..., in: subject)),
               let r  = Range(m.range(at: 1), in: subject) {
                location = String(subject[r])
                break
            }
        }

        // Bedrooms from T1/T2/T3 pattern common in Portuguese listings
        let beds = parseBedrooms(from: combined)

        // Area in m²
        var areaSqM: Double? = nil
        let areaPatterns = ["(\\d+(?:[.,]\\d+)?)\\s*m[²2]", "área(?:[^0-9]*)(\\d+)"]
        for pattern in areaPatterns {
            if let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let m  = re.firstMatch(in: combined, range: NSRange(combined.startIndex..., in: combined)),
               let r  = Range(m.range(at: 1), in: combined),
               let v  = Double(String(combined[r]).replacingOccurrences(of: ",", with: ".")) {
                areaSqM = v
                break
            }
        }

        let url  = extractURL(from: body, containing: "remax.pt") ?? extractAnyURL(from: body)
        let type = parsePropertyType(from: combined)

        return ParsedListing(
            propertyName: "RE/MAX: \(type) in \(location)",
            location:     location,
            price:        price,
            currency:     "EUR",
            listingURL:   url,
            source:       sourceName,
            rawSubject:   subject,
            propertyType: type,
            areaSqM:      areaSqM,
            bedrooms:     beds
        )
    }
}

// MARK: - Parser registry

let allListingParsers: [any ListingEmailParser] = [
    IdealistaEmailParser(),
    RemaxPTEmailParser(),
    ZillowEmailParser(),
    HemnetEmailParser(),
    GenericListingEmailParser(),   // always last
]
