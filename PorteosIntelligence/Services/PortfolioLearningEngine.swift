import Foundation
import SwiftData

// MARK: - UserPreferences

struct UserPreferences {
    /// City → share of acquired portfolio (0–1)
    let preferredCities:    [String: Double]
    /// Typical purchase-price band derived from acquired deals
    let typicalPriceRange:  ClosedRange<Double>
    /// Profile key → normalised weight derived from acquired deals
    let preferredProfiles:  [String: Double]
    /// 0 = conservative (low LTV), 1 = aggressive (high LTV)
    let riskTolerance:      Double
    /// Median months between creation and acquisition across all acquired deals
    let typicalHoldPeriod:  Int
    /// Metric key → average value across acquired deals (used to rank candidates)
    let keyMetrics:         [String: Double]

    static let empty = UserPreferences(
        preferredCities:   [:],
        typicalPriceRange: 0...0,
        preferredProfiles: [:],
        riskTolerance:     0.5,
        typicalHoldPeriod: 12,
        keyMetrics:        [:]
    )
}

// MARK: - PortfolioLearningEngine

enum PortfolioLearningEngine {

    // MARK: – Preference analysis

    /// Derives a `UserPreferences` snapshot entirely from the portfolio's
    /// `.acquired` deals. Falls back to `.viable` and `.review` if no
    /// acquisitions exist yet, so the engine is useful from day one.
    static func analyzeUserPreferences(context: ModelContext) -> UserPreferences {
        let allDeals = fetchDeals(context: context)
        guard !allDeals.isEmpty else { return .empty }

        // Priority order for learning: acquired > viable > review > pipeline
        let acquired = allDeals.filter { $0.status == .acquired }
        let basis    = acquired.isEmpty
            ? allDeals.filter { $0.status == .viable || $0.status == .review }
            : acquired
        guard !basis.isEmpty else { return .empty }

        // ── Preferred cities ───────────────────────────────────────────────────
        let cityGroups = Dictionary(grouping: basis) { $0.locationCity }
        let totalBasis = Double(basis.count)
        let preferredCities = cityGroups.mapValues { Double($0.count) / totalBasis }

        // ── Typical price range (10th–90th percentile of acquisition prices) ───
        let prices = basis.map(\.purchasePrice).sorted()
        let lo = percentile(prices, 0.10)
        let hi = percentile(prices, 0.90)
        let typicalPriceRange = lo <= hi ? lo...hi : (prices.first ?? 0)...(prices.last ?? 0)

        // ── Preferred profiles (normalised average weights) ────────────────────
        let profileKeys: [String: KeyPath<PropertyDeal, Double>] = [
            "realEstate":  \.weightRealEstate,
            "hospitality": \.weightHospitality,
            "design":      \.weightDesign,
            "circular":    \.weightCircular,
        ]
        var profileSums: [String: Double] = profileKeys.mapValues { _ in 0 }
        for deal in basis {
            for (key, kp) in profileKeys { profileSums[key, default: 0] += deal[keyPath: kp] }
        }
        let profileTotal = profileSums.values.reduce(0, +)
        let preferredProfiles = profileTotal > 0
            ? profileSums.mapValues { $0 / profileTotal }
            : profileKeys.mapValues { _ in 0.25 }

        // ── Risk tolerance (average LTV) ───────────────────────────────────────
        // LTV 0% → tolerance 0.0  |  LTV 80%+ → tolerance 1.0
        let ltvValues = basis.compactMap { d -> Double? in
            guard d.purchasePrice > 0 else { return nil }
            return d.loanAmount / d.purchasePrice
        }
        let avgLTV = ltvValues.isEmpty ? 0.6 : ltvValues.reduce(0, +) / Double(ltvValues.count)
        let riskTolerance = min(max(avgLTV / 0.80, 0), 1)

        // ── Typical hold period (months from createdAt to updatedAt for acquired)
        let holdMonths: [Int]
        if acquired.isEmpty {
            holdMonths = [12]   // default assumption
        } else {
            holdMonths = acquired.map { d in
                let diff = Calendar.current.dateComponents([.month], from: d.createdAt, to: d.updatedAt)
                return max(diff.month ?? 1, 1)
            }
        }
        let typicalHoldPeriod = median(holdMonths)

        // ── Key metrics (averages across acquired/basis deals) ─────────────────
        // These represent the metric values the user has historically found
        // acceptable enough to acquire — used as a personalised benchmark.
        let metricKeypaths: [String: KeyPath<PropertyDeal, Double>] = [
            "purchasePrice":     \.purchasePrice,
            "vacancyRate":       \.vacancyRate,
            "interestRate":      \.interestRate,
            "grossIncome":       \.grossPotentialIncome,
            "loanAmount":        \.loanAmount,
            "adr":               \.hospitalityADR,
            "occupancyRate":     \.hospitalityOccupancyRate,
        ]
        var keyMetrics: [String: Double] = [:]
        for (name, kp) in metricKeypaths {
            let vals = basis.map { $0[keyPath: kp] }.filter { $0 > 0 }
            if !vals.isEmpty { keyMetrics[name] = vals.reduce(0, +) / Double(vals.count) }
        }
        // Include average Porteos score of the acquired cohort
        let scores = basis.compactMap(\.porteosScore)
        if !scores.isEmpty { keyMetrics["porteosScore"] = scores.reduce(0, +) / Double(scores.count) }

        return UserPreferences(
            preferredCities:   preferredCities,
            typicalPriceRange: typicalPriceRange,
            preferredProfiles: preferredProfiles,
            riskTolerance:     riskTolerance,
            typicalHoldPeriod: typicalHoldPeriod,
            keyMetrics:        keyMetrics
        )
    }

    // MARK: – Deal fit score

    /// Compares a candidate deal against the learnt `UserPreferences` and
    /// returns a 0–100 fit score. Higher = more aligned with the user's strategy.
    ///
    /// Scoring dimensions (each 0–1, then weighted and scaled to 100):
    ///   - City preference   (20 %)
    ///   - Price fit         (20 %)
    ///   - Profile alignment (20 %)
    ///   - Risk fit          (20 %)
    ///   - Porteos score     (20 %)
    static func calculateDealFitScore(
        deal:    PropertyDeal,
        context: ModelContext
    ) -> Double {
        let prefs = analyzeUserPreferences(context: context)

        // Guard: no acquisition history yet → return raw Porteos score or 50
        guard prefs.typicalPriceRange.upperBound > 0 else {
            return deal.porteosScore ?? 50
        }

        // ── 1. City preference ─────────────────────────────────────────────────
        let cityScore = prefs.preferredCities[deal.locationCity] ?? 0.05

        // ── 2. Price fit (Gaussian kernel centred on typical range midpoint) ────
        let priceMid   = (prefs.typicalPriceRange.lowerBound + prefs.typicalPriceRange.upperBound) / 2
        let priceWidth = max(prefs.typicalPriceRange.upperBound - prefs.typicalPriceRange.lowerBound, 1)
        let priceDelta = (deal.purchasePrice - priceMid) / priceWidth
        let priceScore = exp(-0.5 * priceDelta * priceDelta)   // 1.0 at midpoint, decays outward

        // ── 3. Profile alignment (dot-product of deal weights vs prefs) ─────────
        let profileMap: [String: Double] = [
            "realEstate":  deal.weightRealEstate,
            "hospitality": deal.weightHospitality,
            "design":      deal.weightDesign,
            "circular":    deal.weightCircular,
        ]
        var profileDot = 0.0
        for (key, prefWeight) in prefs.preferredProfiles {
            profileDot += prefWeight * (profileMap[key] ?? 0) / 100.0
        }
        let profileScore = min(profileDot * 4, 1.0)   // scale: perfect alignment → ~1

        // ── 4. Risk fit (how close is the deal's LTV to the user's tolerance) ───
        let dealLTV = deal.purchasePrice > 0 ? deal.loanAmount / deal.purchasePrice : 0.6
        let dealRisk = min(max(dealLTV / 0.80, 0), 1)
        let riskDelta = abs(dealRisk - prefs.riskTolerance)
        let riskScore = max(1 - riskDelta * 2, 0)   // 1.0 = exact match, 0.0 = >0.5 deviation

        // ── 5. Porteos score normalised to 0–1 ────────────────────────────────
        let porteosRaw   = deal.porteosScore ?? (prefs.keyMetrics["porteosScore"] ?? 50)
        let porteosScore = min(max(porteosRaw / 100.0, 0), 1)

        // ── Weighted composite ─────────────────────────────────────────────────
        let composite =
            0.20 * cityScore    +
            0.20 * priceScore   +
            0.20 * profileScore +
            0.20 * riskScore    +
            0.20 * porteosScore

        return (composite * 100).rounded()
    }

    // MARK: – Private helpers

    private static func fetchDeals(context: ModelContext) -> [PropertyDeal] {
        let desc = FetchDescriptor<PropertyDeal>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(desc)) ?? []
    }

    private static func percentile(_ sorted: [Double], _ p: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let idx = p * Double(sorted.count - 1)
        let lo  = Int(idx)
        let hi  = min(lo + 1, sorted.count - 1)
        let frac = idx - Double(lo)
        return sorted[lo] * (1 - frac) + sorted[hi] * frac
    }

    private static func median(_ values: [Int]) -> Int {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let mid    = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }
}
