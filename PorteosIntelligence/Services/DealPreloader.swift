import Foundation

// MARK: - DealPreloader
//
// Generates market-driven field estimates for a deal from:
//   • MarketBenchmarks (OpEx/m², GPI/m², ADR, occupancy, construction cost, etc.)
//   • Price vs implied market value → property condition signal
//   • Area + property type → hospitality room count, renovation range
//
// All outputs are deterministic — no LLM. The LLM (AI Vibe) uses these
// estimates as input for qualitative SWOT analysis.

struct DealPreloader {

    // MARK: - Property condition

    enum PropertyCondition: String, CaseIterable {
        case ruin         = "Ruin / structural"
        case needsWork    = "Needs significant work"
        case habitable    = "Habitable / cosmetic"
        case good         = "Good / move-in ready"

        var renovationFactorRange: (low: Double, high: Double) {
            switch self {
            case .ruin:      return (0.60, 0.85)
            case .needsWork: return (0.25, 0.50)
            case .habitable: return (0.08, 0.20)
            case .good:      return (0.02, 0.07)
            }
        }

        var icon: String {
            switch self {
            case .ruin:      return "⚠︎"
            case .needsWork: return "~"
            case .habitable: return "·"
            case .good:      return "✓"
            }
        }
    }

    // MARK: - Output

    struct PreloadEstimate {
        // Condition signal
        let condition:         PropertyCondition
        let pricePSqm:         Double   // actual €/m²
        let marketPSqm:        Double   // benchmark implied €/m²
        let discountRatio:     Double   // 0–1 (lower = more distressed)

        // Renovation
        let renovationLow:     Double
        let renovationHigh:    Double
        let isHeritage:        Bool     // quinta/rural/stone multiplier applied

        // RE income & expenses
        let grossPotentialIncome: Double
        let vacancyRate:           Double
        let operatingExpenses:     Double

        // OPEX breakdown
        let opexPropertyManagement: Double
        let opexPropertyTax:        Double
        let opexInsurance:          Double
        let opexUtilities:          Double
        let opexMaintenance:        Double
        let opexCapitalReserves:    Double

        // Financing
        let loanAmount:    Double   // 65% LTV
        let interestRate:  Double

        // Hospitality (nil when not applicable)
        let hospitalityRoomCount:     Int?
        let hospitalityADR:           Double?
        let hospitalityOccupancyRate: Double?
        let hospitalityOpExRatio:     Double?

        // Provenance
        let benchmarkCity:    String
        let benchmarkCountry: String
        let fieldNotes:       [String: String]   // field → rationale
    }

    // MARK: - Main entry point

    /// Computes a `PreloadEstimate` from available deal data and city benchmarks.
    /// Returns nil if city/benchmark can't be resolved or area is 0.
    static func estimate(
        city:         String,
        country:      String = "",
        area:         Double,
        landArea:     Double = 0,
        purchasePrice: Double,
        propertyType: String = "",
        propertyName: String = ""
    ) -> PreloadEstimate? {
        guard area > 0 else { return nil }

        // Resolve benchmark
        let searchCity = city.isEmpty ? country : city
        guard let bm = MarketBenchmarks.benchmark(for: searchCity) else { return nil }

        let type = propertyType.lowercased() + " " + propertyName.lowercased()

        // ── Condition detection ───────────────────────────────────────────────
        // Implied market value: capitalise benchmark GPI at market cap rate
        let impliedMarketPSqm: Double = bm.avgCapRate > 0
            ? (bm.avgGPIPerSqm / (bm.avgCapRate / 100))
            : bm.avgConstructionCostPerSqm

        let pricePSqm = purchasePrice / area
        let discountRatio = impliedMarketPSqm > 0 ? pricePSqm / impliedMarketPSqm : 0.5

        let condition: PropertyCondition
        switch discountRatio {
        case ..<0.25:  condition = .ruin
        case 0.25..<0.50: condition = .needsWork
        case 0.50..<0.80: condition = .habitable
        default:          condition = .good
        }

        // ── Heritage / rural multiplier ───────────────────────────────────────
        let ruralKeywords = ["quinta", "farm", "rural", "ruin", "stone", "casale",
                             "farmhouse", "manor", "villa", "herdade", "monte"]
        let isHeritage = ruralKeywords.contains { type.contains($0) }
                      || (landArea > area * 3 && area < 500)
        let heritageMultiplier: Double = isHeritage ? 1.30 : 1.0

        // ── Renovation budget ─────────────────────────────────────────────────
        let (lowFactor, highFactor) = condition.renovationFactorRange
        let baseCostPSqm = bm.avgConstructionCostPerSqm
        let renovationLow  = area * baseCostPSqm * lowFactor  * heritageMultiplier
        let renovationHigh = area * baseCostPSqm * highFactor * heritageMultiplier

        // ── Income ────────────────────────────────────────────────────────────
        let gpi = area * bm.avgGPIPerSqm

        // ── OpEx breakdown ────────────────────────────────────────────────────
        let totalOpEx         = area * bm.avgOpExPerSqm
        let opexMgmt          = purchasePrice * 0.015           // 1.5% of value
        let opexTax           = purchasePrice * (bm.avgPropertyTaxRate / 100)
        let opexInsurance     = area * bm.avgInsuranceRatePerSqm
        let opexUtilities     = max(totalOpEx * 0.15, area * 2) // 15% of total or €2/m²
        let opexMaintenance   = max(totalOpEx * 0.15, area * 2)
        let opexCapReserves   = purchasePrice * 0.01            // 1% of value
        let opexLineTotal     = opexMgmt + opexTax + opexInsurance +
                                opexUtilities + opexMaintenance + opexCapReserves

        // ── Hospitality detection ─────────────────────────────────────────────
        let hospKeywords = ["hotel", "boutique", "hostel", "guesthouse",
                            "lodge", "resort", "inn", "pensão", "pousada", "albergue"]
        let isHospitality = hospKeywords.contains { type.contains($0) }

        let roomCount: Int?       = isHospitality ? max(1, Int(area / 28)) : nil
        let adr: Double?          = isHospitality ? bm.avgADR : nil
        let occupancy: Double?    = isHospitality ? bm.avgOccupancyRate : nil
        let hospOpExRatio: Double? = isHospitality ? 35.0 : nil  // industry standard

        // ── Financing ─────────────────────────────────────────────────────────
        let loanAmount = purchasePrice * 0.65

        // ── Field notes (rationale shown in review UI) ────────────────────────
        var notes: [String: String] = [:]
        notes["grossPotentialIncome"] = "€\(Int(bm.avgGPIPerSqm))/m² × \(Int(area))m² (\(bm.cityName) benchmark)"
        notes["operatingExpenses"]    = "Sum of line items below (\(bm.cityName) rates)"
        notes["vacancyRate"]          = "\(String(format: "%.1f", bm.avgVacancyRate))% — \(bm.cityName) market average"
        notes["interestRate"]         = "\(String(format: "%.1f", bm.avgInterestRate))% — \(bm.cityName) market rate"
        notes["loanAmount"]           = "65% LTV of €\(Int(purchasePrice)) purchase price"
        notes["renovationBudget"]     = "\(condition.rawValue) (\(Int(discountRatio * 100))% of implied market €\(Int(impliedMarketPSqm))/m²)"
            + (isHeritage ? " + 30% heritage premium" : "")
        if let rc = roomCount {
            notes["hospitalityRoomCount"] = "\(Int(area))m² ÷ 28m²/room = \(rc) rooms (boutique standard)"
        }

        return PreloadEstimate(
            condition:             condition,
            pricePSqm:             pricePSqm,
            marketPSqm:            impliedMarketPSqm,
            discountRatio:         discountRatio,
            renovationLow:         renovationLow,
            renovationHigh:        renovationHigh,
            isHeritage:            isHeritage,
            grossPotentialIncome:  gpi,
            vacancyRate:           bm.avgVacancyRate,
            operatingExpenses:     opexLineTotal,
            opexPropertyManagement: opexMgmt,
            opexPropertyTax:       opexTax,
            opexInsurance:         opexInsurance,
            opexUtilities:         opexUtilities,
            opexMaintenance:       opexMaintenance,
            opexCapitalReserves:   opexCapReserves,
            loanAmount:            loanAmount,
            interestRate:          bm.avgInterestRate,
            hospitalityRoomCount:  roomCount,
            hospitalityADR:        adr,
            hospitalityOccupancyRate: occupancy,
            hospitalityOpExRatio:  hospOpExRatio,
            benchmarkCity:         bm.cityName,
            benchmarkCountry:      bm.country,
            fieldNotes:            notes
        )
    }
}
