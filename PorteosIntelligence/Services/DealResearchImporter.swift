import Foundation
import SwiftData

// MARK: - DealResearchImporter
//
// Greedy JSON field mapper for AI/external research exports (Gemini, GPT, etc.).
// Understands the Gemini research format produced for Porteos deals plus generic
// flat research JSON. Applies only zero/empty fields — never overwrites user data.
// GPS coordinates are applied directly (bypassing CLGeocoder).
//
// Usage:
//   let result = DealResearchImporter.apply(json: data, to: deal, context: ctx)

struct DealResearchImporter {

    struct ImportResult {
        let applied: [String]   // human-readable list of fields applied
        let notes: String       // research text appended to deal.notes
        let hadGPS: Bool
    }

    // MARK: Public API

    static func apply(json: Data, to deal: PropertyDeal, context: ModelContext) -> ImportResult {
        guard let raw = try? JSONSerialization.jsonObject(with: json) as? [String: Any] else {
            return ImportResult(applied: [], notes: "", hadGPS: false)
        }
        return applyDict(raw, to: deal, context: context)
    }

    // MARK: Private

    private static func applyDict(
        _ dict: [String: Any],
        to deal: PropertyDeal,
        context: ModelContext
    ) -> ImportResult {
        DealHistoryManager.shared.push(deal: deal, label: "Import Research JSON")

        var applied: [String] = []
        var noteLines: [String] = []
        var hadGPS = false

        // ── Flatten all nested dicts into a single lookup map ──────────────────
        let flat = flatten(dict)

        // ── GPS coordinates — always apply when present and valid ──────────────
        if let lat = double(flat, keys: ["latitude", "lat", "decimal_latitude"]),
           let lon = double(flat, keys: ["longitude", "lon", "lng", "decimal_longitude"]),
           lat != 0, lon != 0,
           lat  >= -90,  lat  <= 90,
           lon >= -180, lon <= 180 {
            deal.latitude  = lat
            deal.longitude = lon
            deal.geocodeStatus = .ok
            applied.append("GPS \(String(format: "%.5f", lat)), \(String(format: "%.5f", lon))")
            hadGPS = true
        }

        // ── Price ──────────────────────────────────────────────────────────────
        if deal.purchasePrice == 0,
           let price = double(flat, keys: ["listing_price_eur", "purchasePrice",
                                           "purchase_price", "price_eur", "price"]),
           price > 0 {
            deal.purchasePrice = price
            applied.append("price €\(Int(price))")
        }

        // ── Built area ────────────────────────────────────────────────────────
        if deal.totalArea == 0,
           let area = double(flat, keys: ["gross_built_area_sqm", "totalArea", "total_area",
                                          "area_sqm", "floor_area_sqm", "built_area_sqm",
                                          "footprint_sqm"]),
           area > 0 {
            deal.totalArea = area
            applied.append("area \(Int(area))m²")
        }

        // ── Land / rustic area ────────────────────────────────────────────────
        if deal.landArea == 0,
           let land = double(flat, keys: ["rustic_land_area_sqm", "landArea", "land_area",
                                          "plot_area_sqm", "site_area_sqm"]),
           land > 0 {
            deal.landArea = land
            applied.append("land \(Int(land))m²")
        }

        // ── Bedrooms from typology string ─────────────────────────────────────
        if let bdr = int(flat, keys: ["bedrooms", "bedroom_count", "rooms"]), bdr > 0 {
            // direct integer field
        } else if let typology = string(flat, keys: ["typology", "property_type", "type"]) {
            // "T3 (Three-Bedroom Potential)" → 3
            if let m = typology.range(of: #"\bT(\d)\b"#, options: .regularExpression) {
                let tStr = String(typology[m]).dropFirst() // "T3" → "3"
                if let n = Int(tStr), n > 0, deal.hospitalityRoomCount == 0 {
                    // Store bedroom count in notes since PropertyDeal doesn't have a bedrooms field
                    // (it uses hospitalityRoomCount for hospitality only)
                    noteLines.append("Typology: \(typology)")
                    applied.append("typology \(typology)")
                }
            }
        }

        // ── Location ──────────────────────────────────────────────────────────
        if deal.locationCity.isEmpty {
            // Try most-specific first: parish → municipality → district → region
            let cityKeys = ["parish", "locality", "municipality", "district", "region", "city",
                            "locationCity", "location_city"]
            if let city = string(flat, keys: cityKeys), !city.isEmpty {
                deal.locationCity = city
                applied.append("city \(city)")
            }
        }

        // ── Address / access road ─────────────────────────────────────────────
        if deal.address.isEmpty,
           let road = string(flat, keys: ["access_road", "address", "street"]),
           !road.isEmpty {
            deal.address = road
            applied.append("address \(road)")
        }

        // ── Agency / agent (notes) ────────────────────────────────────────────
        if let agency = string(flat, keys: ["listing_agency", "agency", "agent_company"]) {
            noteLines.append("Agency: \(agency)")
        }
        if let agent = string(flat, keys: ["listing_agent", "agent", "agent_name"]) {
            noteLines.append("Agent: \(agent)")
        }
        if let ref = string(flat, keys: ["listing_reference", "reference", "ref", "listing_ref"]) {
            noteLines.append("Ref: \(ref)")
        }

        // ── Research narrative fields → notes ─────────────────────────────────
        let researchKeys: [(String, String)] = [
            ("soil_type",                   "Soil"),
            ("solar_exposure",              "Solar"),
            ("microclimate_benefits",       "Microclimate"),
            ("water_access",                "Water"),
            ("licensing_framework",         "Licensing"),
            ("zoning_restrictions",         "Zoning"),
            ("sustainable_architectural_potentials", "Sustainable potential"),
            ("north_boundary",              "N boundary"),
            ("south_boundary",              "S boundary"),
            ("west_boundary",               "W boundary"),
            ("east_boundary",               "E boundary"),
            ("archaeological_proximity",    "Archaeological"),
            ("structure",                   "Structure"),
            ("status",                      "Status"),
        ]
        for (key, label) in researchKeys {
            if let val = flat[key] as? String, !val.isEmpty {
                noteLines.append("\(label): \(val)")
            }
        }

        // ── Price per sqm (informational) ─────────────────────────────────────
        if let ppsqm = double(flat, keys: ["implied_unit_price_eur_sqm", "price_per_sqm",
                                            "subject_price_per_sqm"]), ppsqm > 0 {
            noteLines.append(String(format: "Price/m²: €%.0f", ppsqm))
        }

        // ── Append research notes ─────────────────────────────────────────────
        let researchBlock = noteLines.isEmpty ? "" : "\n\n--- RESEARCH IMPORT ---\n" + noteLines.joined(separator: "\n")
        if !researchBlock.isEmpty {
            deal.notes = deal.notes + researchBlock
        }

        // ── Market resolution ─────────────────────────────────────────────────
        if deal.marketId.isEmpty, !deal.locationCity.isEmpty {
            if let resolved = MarketFeedRegistry.resolveMarketId(
                city: deal.locationCity,
                countryHint: string(flat, keys: ["country", "region"]) ?? "") {
                deal.marketId = resolved
                applied.append("market \(resolved)")
            }
        }

        deal.updatedAt = Date()
        try? context.save()

        return ImportResult(applied: applied, notes: researchBlock, hadGPS: hadGPS)
    }

    // MARK: - JSON flattening

    /// Recursively flattens nested dicts into a single [String: Any] map.
    private static func flatten(_ dict: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dict {
            result[key] = value
            if let nested = value as? [String: Any] {
                let sub = flatten(nested)
                for (subKey, subVal) in sub {
                    result[subKey] = subVal
                }
            }
        }
        return result
    }

    // MARK: - Field extractors

    private static func double(_ flat: [String: Any], keys: [String]) -> Double? {
        for key in keys {
            if let n = flat[key] as? Double { return n }
            if let n = flat[key] as? Int    { return Double(n) }
            if let s = flat[key] as? String, let n = Double(s) { return n }
        }
        return nil
    }

    private static func int(_ flat: [String: Any], keys: [String]) -> Int? {
        for key in keys {
            if let n = flat[key] as? Int    { return n }
            if let n = flat[key] as? Double { return Int(n) }
        }
        return nil
    }

    private static func string(_ flat: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let s = flat[key] as? String, !s.trimmingCharacters(in: .whitespaces).isEmpty {
                return s.trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
}
