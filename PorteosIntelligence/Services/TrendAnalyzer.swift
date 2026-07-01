import Foundation
import SwiftData

// MARK: - Supporting Types

enum TrendDirection {
    case up, down, stable

    var label: String {
        switch self {
        case .up:     return "↑ RISING"
        case .down:   return "↓ FALLING"
        case .stable: return "→ STABLE"
        }
    }
}

struct TrendData {
    let current:       Double
    let threeMonthAvg: Double
    let sixMonthAvg:   Double
    let direction:     TrendDirection
    let strength:      Double   // % change vs six-month average
    let volatility:    Double   // population std dev of all samples
    let confidence:    Double   // 0–1 based on sample count (saturates at 12)

    static let empty = TrendData(
        current: 0, threeMonthAvg: 0, sixMonthAvg: 0,
        direction: .stable, strength: 0, volatility: 0, confidence: 0
    )
}

struct SeasonalData {
    let monthlyAverages:      [Int: Double]   // month 1–12 → average value
    let peakMonth:            Int             // 1–12
    let troughMonth:          Int             // 1–12
    let adjustmentFactor:     Double          // current month / annual average
    let hasSufficientData:    Bool
}

struct MarketHeat {
    let level:           String   // "HOT" | "WARM" | "COOL" | "COLD"
    let importVelocity:  Double   // deals imported per week (last 30 days)
    let priceVelocity:   Double   // % change in avg price per month
    let acquisitionRate: Double   // fraction of imports that became .acquired
}

// MARK: - TrendAnalyzer

enum TrendAnalyzer {

    // MARK: – Main trend calculation

    /// Fetches up to 6 months of `MarketTrend` records for a given city / profile /
    /// metric combination and derives statistical trend indicators.
    static func calculateTrend(
        for city:    String,
        profile:     String,
        metric:      String,
        context:     ModelContext
    ) -> TrendData {
        let cutoff = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<MarketTrend>(
            predicate: #Predicate { t in
                t.city       == city   &&
                t.profile    == profile &&
                t.metricName == metric  &&
                t.recordedAt >= cutoff
            },
            sortBy: [SortDescriptor(\.recordedAt)]
        )

        guard let records = try? context.fetch(descriptor), !records.isEmpty else {
            return .empty
        }

        let values    = records.map(\.value)
        let dates     = records.map(\.recordedAt)
        let now       = Date()
        let threeAgo  = Calendar.current.date(byAdding: .month, value: -3, to: now) ?? now

        // Current: weighted mean of the most-recent month's samples
        let recentValues = zip(values, dates)
            .filter { _, d in Calendar.current.date(byAdding: .month, value: -1, to: now)! <= d }
            .map(\.0)
        let current = recentValues.isEmpty ? values.last! : mean(recentValues)

        // 3-month average
        let threeMonthValues = zip(values, dates)
            .filter { _, d in d >= threeAgo }
            .map(\.0)
        let threeMonthAvg = threeMonthValues.isEmpty ? current : mean(threeMonthValues)

        // 6-month average
        let sixMonthAvg = mean(values)

        // Trend direction and strength (vs 6-month baseline)
        let strength: Double
        let direction: TrendDirection
        if sixMonthAvg == 0 {
            strength  = 0
            direction = .stable
        } else {
            strength = ((current - sixMonthAvg) / abs(sixMonthAvg)) * 100
            if strength > 2 {
                direction = .up
            } else if strength < -2 {
                direction = .down
            } else {
                direction = .stable
            }
        }

        // Volatility: population standard deviation
        let volatility = stdDev(values)

        // Confidence: grows with sample count, saturates at 12 samples → 1.0
        let confidence = min(Double(records.count) / 12.0, 1.0)

        return TrendData(
            current:       current,
            threeMonthAvg: threeMonthAvg,
            sixMonthAvg:   sixMonthAvg,
            direction:     direction,
            strength:      strength,
            volatility:    volatility,
            confidence:    confidence
        )
    }

    // MARK: – Seasonal pattern detection

    /// Groups `MarketTrend` records by calendar month and identifies the peak
    /// (highest) and trough (lowest) months, plus a seasonal adjustment factor
    /// for the current month relative to the annual mean.
    static func detectSeasonalPattern(
        for city:  String,
        profile:   String,
        metric:    String,
        context:   ModelContext
    ) -> SeasonalData {
        let cutoff = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<MarketTrend>(
            predicate: #Predicate { t in
                t.city       == city    &&
                t.profile    == profile &&
                t.metricName == metric  &&
                t.recordedAt >= cutoff
            }
        )

        guard let records = try? context.fetch(descriptor), records.count >= 6 else {
            return SeasonalData(
                monthlyAverages:   [:],
                peakMonth:         0,
                troughMonth:       0,
                adjustmentFactor:  1.0,
                hasSufficientData: false
            )
        }

        // Group values by month number
        var buckets: [Int: [Double]] = [:]
        let cal = Calendar.current
        for record in records {
            let month = cal.component(.month, from: record.recordedAt)
            buckets[month, default: []].append(record.value)
        }

        let monthlyAverages = buckets.mapValues { mean($0) }
        guard !monthlyAverages.isEmpty else {
            return SeasonalData(
                monthlyAverages:   [:],
                peakMonth:         0,
                troughMonth:       0,
                adjustmentFactor:  1.0,
                hasSufficientData: false
            )
        }

        let peakMonth   = monthlyAverages.max(by: { $0.value < $1.value })!.key
        let troughMonth = monthlyAverages.min(by: { $0.value < $1.value })!.key
        let annualMean  = mean(Array(monthlyAverages.values))

        let currentMonth = cal.component(.month, from: Date())
        let currentMonthAvg = monthlyAverages[currentMonth] ?? annualMean
        let adjustmentFactor = annualMean == 0 ? 1.0 : currentMonthAvg / annualMean

        return SeasonalData(
            monthlyAverages:   monthlyAverages,
            peakMonth:         peakMonth,
            troughMonth:       troughMonth,
            adjustmentFactor:  adjustmentFactor,
            hasSufficientData: true
        )
    }

    // MARK: – Market heat

    /// Scores market activity for a city based on recent import velocity, price
    /// momentum, and the portfolio's acquisition rate.
    static func calculateMarketHeat(
        for city:  String,
        context:   ModelContext
    ) -> MarketHeat {
        let now        = Date()
        let cal        = Calendar.current
        let thirtyAgo  = cal.date(byAdding: .day,   value: -30, to: now) ?? now
        let sixtyAgo   = cal.date(byAdding: .day,   value: -60, to: now) ?? now
        let ninetyAgo  = cal.date(byAdding: .day,   value: -90, to: now) ?? now

        // ── Import velocity ────────────────────────────────────────────────────
        // Use MarketTrend "portfolio" records as a proxy for deal imports
        let recentDesc = FetchDescriptor<MarketTrend>(
            predicate: #Predicate { t in
                t.city       == city &&
                t.source     == "portfolio" &&
                t.recordedAt >= thirtyAgo
            }
        )
        let recentCount  = (try? context.fetch(recentDesc).count) ?? 0
        let importVelocity = Double(recentCount) / 4.0   // per week (30 days ÷ 4)

        // ── Price velocity ─────────────────────────────────────────────────────
        // Compare mean capRate/price from last 30 days vs 30–90 days prior
        let priceMetrics = ["capRate", "purchasePrice"]

        var recentPrices:  [Double] = []
        var olderPrices:   [Double] = []

        for metric in priceMetrics {
            let recentPDesc = FetchDescriptor<MarketTrend>(
                predicate: #Predicate { t in
                    t.city       == city &&
                    t.metricName == metric &&
                    t.recordedAt >= thirtyAgo
                }
            )
            let olderPDesc = FetchDescriptor<MarketTrend>(
                predicate: #Predicate { t in
                    t.city       == city &&
                    t.metricName == metric &&
                    t.recordedAt >= ninetyAgo &&
                    t.recordedAt <  thirtyAgo
                }
            )
            if let recs = try? context.fetch(recentPDesc) { recentPrices.append(contentsOf: recs.map(\.value)) }
            if let recs = try? context.fetch(olderPDesc)  { olderPrices.append(contentsOf:  recs.map(\.value)) }
        }

        let priceVelocity: Double
        if !recentPrices.isEmpty, !olderPrices.isEmpty {
            let r = mean(recentPrices)
            let o = mean(olderPrices)
            priceVelocity = o == 0 ? 0 : ((r - o) / abs(o)) * 100
        } else {
            priceVelocity = 0
        }

        // ── Acquisition rate ───────────────────────────────────────────────────
        // Ratio of .acquired deals to total deals in this city
        let dealDesc = FetchDescriptor<PropertyDeal>(
            predicate: #Predicate { d in d.locationCity == city }
        )
        let deals = (try? context.fetch(dealDesc)) ?? []
        let acquisitionRate: Double
        if deals.isEmpty {
            acquisitionRate = 0
        } else {
            let acquired = deals.filter { $0.status == .acquired }.count
            acquisitionRate = Double(acquired) / Double(deals.count)
        }

        // ── Average days between imports (last 60 days) ────────────────────────
        let intervalDesc = FetchDescriptor<MarketTrend>(
            predicate: #Predicate { t in
                t.city       == city &&
                t.source     == "portfolio" &&
                t.recordedAt >= sixtyAgo
            },
            sortBy: [SortDescriptor(\.recordedAt)]
        )
        let intervalRecords = (try? context.fetch(intervalDesc)) ?? []
        var avgDaysBetween: Double = 30
        if intervalRecords.count >= 2 {
            let gaps = zip(intervalRecords, intervalRecords.dropFirst()).map { a, b in
                b.recordedAt.timeIntervalSince(a.recordedAt) / 86_400
            }
            avgDaysBetween = mean(gaps)
        }

        // ── Composite heat score → label ───────────────────────────────────────
        // importVelocity: >2/wk hot, >1/wk warm, >0.5/wk cool, else cold
        // priceVelocity:  >3% strong upward pressure
        // acquisitionRate: >0.3 high conversion
        var score = 0
        if importVelocity   > 2.0  { score += 3 } else if importVelocity   > 1.0  { score += 2 } else if importVelocity   > 0.3  { score += 1 }
        if priceVelocity    > 3.0  { score += 2 } else if priceVelocity    > 1.0  { score += 1 } else if priceVelocity    < -3.0 { score -= 1 }
        if acquisitionRate  > 0.3  { score += 2 } else if acquisitionRate  > 0.1  { score += 1 }
        if avgDaysBetween   < 7.0  { score += 1 }

        let level: String
        switch score {
        case 6...: level = "HOT"
        case 4...5: level = "WARM"
        case 2...3: level = "COOL"
        default:    level = "COLD"
        }

        return MarketHeat(
            level:           level,
            importVelocity:  importVelocity,
            priceVelocity:   priceVelocity,
            acquisitionRate: acquisitionRate
        )
    }

    // MARK: – Math helpers

    private static func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func stdDev(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let m  = mean(values)
        let sq = values.map { ($0 - m) * ($0 - m) }
        return sqrt(sq.reduce(0, +) / Double(values.count))
    }
}
