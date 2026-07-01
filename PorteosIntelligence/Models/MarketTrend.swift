import Foundation
import SwiftData

// MARK: - MarketTrend

/// Persists a single historical market metric observation for a city/profile/metric
/// combination. Multiple records for the same key form a time-series that the
/// Trend-Aware Intelligence Engine uses to detect movement and compute adaptive
/// benchmarks entirely on-device.
@Model
final class MarketTrend {

    var id:         UUID
    var city:       String
    var country:    String
    var profile:    String     // "realEstate" | "hospitality" | "design" | "circular"
    var metricName: String     // "capRate" | "adr" | "occupancy" | …
    var value:      Double
    var sampleSize: Int        // Number of deals that contributed to this average
    var recordedAt: Date
    var source:     String     // "portfolio" | "benchmark" | "import"

    init(
        city:       String,
        country:    String,
        profile:    String,
        metricName: String,
        value:      Double,
        sampleSize: Int    = 1,
        source:     String = "portfolio"
    ) {
        self.id         = UUID()
        self.city       = city
        self.country    = country
        self.profile    = profile
        self.metricName = metricName
        self.value      = value
        self.sampleSize = sampleSize
        self.recordedAt = Date()
        self.source     = source
    }
}
