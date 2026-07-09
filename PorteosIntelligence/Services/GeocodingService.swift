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

            let countryHint = addressContext(from: item)
            if let resolved = MarketFeedRegistry.resolveMarketId(city: deal.locationCity, countryHint: countryHint) {
                deal.marketId = resolved
            } else if let name = item.name,
                      let resolved = MarketFeedRegistry.resolveMarketId(city: name, countryHint: countryHint) {
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

    private func geocodeQuery(for deal: PropertyDeal) -> String {
        let parts = [deal.address, deal.locationCity].filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return parts.joined(separator: ", ")
    }

    private func addressContext(from item: MKMapItem) -> String {
        [item.address?.fullAddress, item.address?.shortAddress, item.name]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
