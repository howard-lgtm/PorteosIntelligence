import Foundation
import MapKit
import CoreLocation
import SwiftData

// MARK: - GeocodingService
// Resolves deal addresses to coordinates on save/import only (no backfill job).

@MainActor
final class GeocodingService {

    static let shared = GeocodingService()
    private init() {}

    func geocode(deal: PropertyDeal, context: ModelContext) async {
        let query = geocodeQuery(for: deal)
        guard !query.isEmpty else { return }

        deal.geocodeStatus = .pending
        deal.updatedAt = Date()
        try? context.save()

        do {
            // CLGeocoder — available macOS 10.8+, identical accuracy to MKGeocodingRequest
            let placemarks = try await CLGeocoder().geocodeAddressString(query)

            guard let placemark = placemarks.first,
                  let location = placemark.location else {
                deal.geocodeStatus = .failed
                try? context.save()
                return
            }

            // ── Country consistency check ──────────────────────────────────────
            // If we have an expected country and the geocoder returned a different
            // one, reject the result. Primary defence against mis-geocoding
            // (e.g. "Messines" → Morocco instead of Portugal).
            let expectedCountry = inferCountry(for: deal)
            if let expected = expectedCountry,
               let geocodedCountry = placemark.country {
                let expNorm = expected.lowercased()
                let geoNorm = geocodedCountry.lowercased()
                let consistent = geoNorm.contains(expNorm) || expNorm.contains(geoNorm)
                if !consistent {
                    deal.geocodeStatus = .failed
                    deal.updatedAt = Date()
                    try? context.save()
                    print("[GeocodingService] Country mismatch — expected '\(expected)', got '\(geocodedCountry)' for query: '\(query)'")
                    return
                }
            }

            deal.latitude  = location.coordinate.latitude
            deal.longitude = location.coordinate.longitude
            deal.geocodeStatus = .ok

            // Resolve marketId using placemark locality/country as context hint
            let countryHint = [placemark.locality, placemark.administrativeArea, placemark.country]
                .compactMap { $0 }
                .joined(separator: " ")
            if let resolved = MarketFeedRegistry.resolveMarketId(
                city: deal.locationCity,
                countryHint: countryHint
            ) {
                deal.marketId = resolved
            }

            deal.updatedAt = Date()
            try context.save()
        } catch {
            deal.geocodeStatus = .failed
            deal.updatedAt = Date()
            try? context.save()
            print("[GeocodingService] failed for '\(query)': \(error.localizedDescription)")
        }
    }

    func scheduleGeocode(deal: PropertyDeal, context: ModelContext) {
        Task { await geocode(deal: deal, context: context) }
    }

    func clearPin(deal: PropertyDeal, context: ModelContext) {
        deal.latitude = nil
        deal.longitude = nil
        deal.geocodeStatus = .none
        deal.updatedAt = Date()
        try? context.save()
    }

    /// Geocode every deal that has address/city but no valid pin.
    func geocodeAllPending(deals: [PropertyDeal], context: ModelContext) async {
        let pending = deals.filter { $0.needsGeocode }
        for (index, deal) in pending.enumerated() {
            await geocode(deal: deal, context: context)
            // Apple rate-limits CLGeocoder — pause to avoid silent failures
            if index < pending.count - 1 {
                try? await Task.sleep(nanoseconds: 1_200_000_000)  // 1.2s
            }
        }
    }

    func scheduleGeocodeAllPending(deals: [PropertyDeal], context: ModelContext) {
        Task { await geocodeAllPending(deals: deals, context: context) }
    }

    // MARK: - Query builder

    private func geocodeQuery(for deal: PropertyDeal) -> String {
        let parts = [deal.address, deal.locationCity]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var query = parts.joined(separator: ", ")
        guard !query.isEmpty else { return "" }

        if let country = inferCountry(for: deal),
           !query.lowercased().contains(country.lowercased()) {
            query += ", \(country)"
        }
        return query
    }

    // MARK: - Country inference (ordered by reliability)

    /// Returns the country name to append to the geocode query and validate results against.
    /// Four levels of fallback — stops at first confident match.
    func inferCountry(for deal: PropertyDeal) -> String? {
        // 0. Stored locationCountry — user-entered, always trusted
        let stored = deal.locationCountry.trimmingCharacters(in: .whitespaces)
        if !stored.isEmpty { return stored }

        // 1. marketId ISO prefix (set post-geocode or on import)
        let idPrefix = String(deal.marketId.prefix(2))
        if let country = Self.iso2ToCountry[idPrefix] { return country }

        // 2. MarketFeedRegistry city alias lookup
        // Covers all thesis-market cities including aliases: Cascais, Sintra, Tavira, etc.
        let cityLower = deal.locationCity.lowercased()
        if !cityLower.isEmpty {
            let allMarkets = MarketFeedRegistry.countries + MarketFeedRegistry.metros
            for market in allMarkets {
                let matched = market.cityAliases.contains { alias in
                    let al = alias.lowercased()
                    return cityLower == al || cityLower.hasPrefix(al) || al.hasPrefix(cityLower)
                }
                if matched {
                    let rootId = market.parentId ?? market.id
                    let root   = MarketFeedRegistry.market(id: rootId)
                    let cc     = root?.countryCode ?? market.countryCode
                    if let name = Self.iso2ToCountry[cc] { return name }
                }
            }
        }

        // 3. MarketBenchmarks city lookup
        if let bm = MarketBenchmarks.benchmark(for: deal.locationCity) {
            return bm.country
        }

        // 4. Text heuristic — Portuguese place-name markers (expanded)
        let text = (deal.locationCity + " " + deal.propertyName).lowercased()
        let ptMarkers = [
            // geographic terms
            "algarve", "alentejo", "ribatejo", "minho", "douro", "beira", "estremadura",
            // diacritics common in PT
            "são", "évora", "setúbal", "lourinhã", "guimarães", "viana",
            // municipalities
            "odemira", "silves", "lagoa", "loulé", "monchique", "portimão",
            "olhão", "tavira", "alcoutim", "aljezur", "castro marim",
            "conceição", "mértola", "beja", "serpa", "moura",
            "grândola", "sines", "santiago do cacém", "alcácer",
            // quinta / rural markers
            "quinta", "herdade", "monte", "casal",
        ]
        if ptMarkers.contains(where: { text.contains($0) }) { return "Portugal" }

        return nil
    }

    // MARK: - ISO-2 → Country name

    private static let iso2ToCountry: [String: String] = [
        "PT": "Portugal",        "ES": "Spain",          "IT": "Italy",
        "FR": "France",          "GB": "United Kingdom", "UK": "United Kingdom",
        "DE": "Germany",         "HR": "Croatia",        "GR": "Greece",
        "SE": "Sweden",          "DK": "Denmark",        "NO": "Norway",
        "FI": "Finland",         "US": "United States",  "JP": "Japan",
        "AU": "Australia",       "NL": "Netherlands",    "AT": "Austria",
        "CH": "Switzerland",     "BE": "Belgium",        "IE": "Ireland",
        "PL": "Poland",          "CZ": "Czech Republic", "HU": "Hungary",
        "RO": "Romania",         "AE": "UAE",            "SA": "Saudi Arabia",
        "MA": "Morocco",         "SG": "Singapore",      "HK": "Hong Kong",
        "BR": "Brazil",
    ]

}
