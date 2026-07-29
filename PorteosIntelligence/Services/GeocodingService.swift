import Foundation
import MapKit
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
            guard let request = MKGeocodingRequest(addressString: query) else {
                deal.geocodeStatus = .failed
                try? context.save()
                return
            }

            let mapItems = try await request.mapItems
            guard let item = mapItems.first else {
                deal.geocodeStatus = .failed
                try? context.save()
                return
            }

            let location = item.location
            deal.latitude  = location.coordinate.latitude
            deal.longitude = location.coordinate.longitude
            deal.geocodeStatus = .ok

            // Only resolve marketId from the deal's own city — never from item.name,
            // which can be any place name from a wrong geocode result (was causing
            // "Atlanta Metro" to appear on PT properties when CLGeocoder mis-geocoded).
            let countryHint = addressContext(from: item)
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
            print("[GeocodingService] failed for \(query): \(error.localizedDescription)")
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

    /// Geocode every deal that has address/city but no valid pin (Frame 4 — geocode empty).
    func geocodeAllPending(deals: [PropertyDeal], context: ModelContext) async {
        let pending = deals.filter { $0.needsGeocode }
        for (index, deal) in pending.enumerated() {
            await geocode(deal: deal, context: context)
            // Apple rate-limits CLGeocoder — pause between requests to avoid silent failures
            if index < pending.count - 1 {
                try? await Task.sleep(nanoseconds: 1_200_000_000)  // 1.2s between calls
            }
        }
    }

    func scheduleGeocodeAllPending(deals: [PropertyDeal], context: ModelContext) {
        Task { await geocodeAllPending(deals: deals, context: context) }
    }

    private func geocodeQuery(for deal: PropertyDeal) -> String {
        let parts = [deal.address, deal.locationCity]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var query = parts.joined(separator: ", ")
        guard !query.isEmpty else { return "" }

        // Append country context to prevent mis-geocoding ambiguous place names
        if let country = inferCountry(for: deal), !query.lowercased().contains(country.lowercased()) {
            query += ", \(country)"
        }
        return query
    }

    /// Derives a country name from marketId prefix or benchmark lookup.
    private func inferCountry(for deal: PropertyDeal) -> String? {
        // 1. marketId prefix (most reliable when set post-geocode)
        let idPrefix = String(deal.marketId.prefix(2))
        let countryByCode: [String: String] = [
            "PT": "Portugal", "ES": "Spain", "IT": "Italy", "FR": "France",
            "UK": "United Kingdom", "DE": "Germany", "HR": "Croatia",
            "GR": "Greece", "SE": "Sweden", "DK": "Denmark",
            "NO": "Norway", "FI": "Finland", "US": "United States",
            "JP": "Japan",
        ]
        if let country = countryByCode[idPrefix] { return country }

        // 2. Benchmark lookup on city
        if let bm = MarketBenchmarks.benchmark(for: deal.locationCity) {
            return bm.country
        }

        // 3. Portuguese place-name heuristic (São, da, do, de + no Latin-Am marker)
        let city = deal.locationCity + " " + deal.propertyName
        let ptMarkers = ["são", "lourinhã", "alcobaca", "setúbal", "algarve",
                         "évora", "alentejo", "ribatejo", "minho", "douro"]
        if ptMarkers.contains(where: { city.lowercased().contains($0) }) {
            return "Portugal"
        }

        return nil
    }

    private func addressContext(from item: MKMapItem) -> String {
        [item.address?.fullAddress, item.address?.shortAddress, item.name]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
