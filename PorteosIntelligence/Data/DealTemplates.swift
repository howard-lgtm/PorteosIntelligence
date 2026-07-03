import Foundation
import SwiftUI

// MARK: - DealTemplate

struct DealTemplate: Identifiable {
    let id:              String
    let name:            String
    let category:        String    // "realEstate" | "hospitality" | "mixedUse" | "design" | "circular"
    let description:     String
    let defaultLocation: String
    let defaultMetrics:  [String: Double]

    // MARK: – Derived

    /// First component of defaultLocation, used as locationCity on the deal.
    var locationCity: String {
        defaultLocation.components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespaces) ?? defaultLocation
    }

    /// 2–3 headline metric pairs shown in the picker card.
    var keyMetrics: [(label: String, value: String)] {
        let m = defaultMetrics
        var result: [(String, String)] = []

        if let v = m["purchasePrice"], v > 0 {
            result.append(("PRICE", formatCurrency(v)))
        }
        if let v = m["hospitalityRoomCount"], v > 0 {
            result.append(("ROOMS", "\(Int(v))"))
        } else if let v = m["totalArea"], v > 0 {
            result.append(("AREA", "\(Int(v))m²"))
        }
        if let v = m["hospitalityADR"], v > 0 {
            result.append(("ADR", "€\(Int(v))"))
        } else if let gpi = m["grossPotentialIncome"], gpi > 0,
                  let price = m["purchasePrice"], price > 0 {
            let vac  = m["vacancyRate"] ?? 5
            let opex = m["operatingExpenses"] ?? 0
            let noi  = gpi * (1 - vac / 100) - opex
            let cap  = noi / price * 100
            result.append(("CAP RATE", String(format: "%.1f%%", cap)))
        }
        if let v = m["circularRecycledContentPct"], v > 0 {
            result.append(("RECYCLED", "\(Int(v))%"))
        }
        return Array(result.prefix(3))
    }

    /// Category display name.
    var categoryLabel: String {
        switch category {
        case "realEstate":  return "REAL ESTATE"
        case "hospitality": return "HOSPITALITY"
        case "mixedUse":    return "MIXED-USE"
        case "design":      return "DESIGN"
        case "circular":    return "CIRCULAR"
        default:            return category.uppercased()
        }
    }

    /// Short category tag for template picker cards (Figma img_00_10).
    var shortCategoryLabel: String {
        switch category {
        case "realEstate":  return "RE"
        case "hospitality": return "HOSP"
        case "mixedUse":    return "MIXED"
        case "design":      return "DESIGN"
        case "circular":    return "CIRCULAR"
        default:            return category.uppercased()
        }
    }

    /// Profile accent colour for this template.
    var accentColor: Color {
        switch category {
        case "realEstate":  return ProfileType.realEstate.accentColor
        case "hospitality": return ProfileType.hospitality.accentColor
        case "design":      return ProfileType.design.accentColor
        case "circular":    return ProfileType.circular.accentColor
        case "mixedUse":    return DesignTokens.accentPipeline
        default:            return DesignTokens.textSecondary
        }
    }

    // MARK: – PropertyDeal Factory

    /// Creates a pre-filled PropertyDeal from this template.
    func makePropertyDeal(customName: String? = nil) -> PropertyDeal {
        let m = defaultMetrics
        let d = PropertyDeal()

        d.propertyName = customName ?? name
        d.locationCity = locationCity
        d.address      = defaultLocation
        d.propertyType = resolvedPropertyType

        // ── Real Estate ────────────────────────────────────────────────────────
        d.purchasePrice           = m["purchasePrice"]           ?? 0
        d.totalArea               = m["totalArea"]               ?? 0
        d.closingCosts            = m["closingCosts"]            ?? 0
        d.renovationBudget        = m["renovationBudget"]        ?? 0
        d.grossPotentialIncome    = m["grossPotentialIncome"]    ?? 0
        d.vacancyRate             = m["vacancyRate"]             ?? 0
        d.otherIncome             = m["otherIncome"]             ?? 0
        d.operatingExpenses       = m["operatingExpenses"]       ?? 0
        d.loanAmount              = m["loanAmount"]              ?? 0
        d.interestRate            = m["interestRate"]            ?? 0
        d.amortizationMonths      = Int(m["amortizationMonths"]  ?? 360)
        d.exitCapRate             = m["exitCapRate"]             ?? 0
        d.opexPropertyManagement  = m["opexPropertyManagement"]  ?? 0
        d.opexPropertyTax         = m["opexPropertyTax"]         ?? 0
        d.opexInsurance           = m["opexInsurance"]           ?? 0
        d.opexUtilities           = m["opexUtilities"]           ?? 0
        d.opexMaintenance         = m["opexMaintenance"]         ?? 0
        d.opexCapitalReserves     = m["opexCapitalReserves"]     ?? 0

        // ── Hospitality ────────────────────────────────────────────────────────
        d.hospitalityRoomCount       = Int(m["hospitalityRoomCount"]       ?? 0)
        d.hospitalityADR             = m["hospitalityADR"]                 ?? 0
        d.hospitalityOccupancyRate   = m["hospitalityOccupancyRate"]       ?? 0
        d.hospitalityFBRevenue       = m["hospitalityFBRevenue"]           ?? 0
        d.hospitalitySpaRevenue      = m["hospitalitySpaRevenue"]          ?? 0
        d.hospitalityMeetingRevenue  = m["hospitalityMeetingRevenue"]      ?? 0
        d.hospitalityOtherRevenue    = m["hospitalityOtherRevenue"]        ?? 0
        d.hospitalityOpExRatio       = m["hospitalityOpExRatio"]           ?? 0
        d.hospitalityDirectBookingPct = m["hospitalityDirectBookingPct"]   ?? 0
        d.hospitalityOTABookingPct   = m["hospitalityOTABookingPct"]       ?? 0
        d.hospitalityDistributionCost = m["hospitalityDistributionCost"]   ?? 0

        // ── Design ────────────────────────────────────────────────────────────
        d.designGFA               = m["designGFA"]               ?? 0
        d.designNIA               = m["designNIA"]               ?? 0
        d.designCirculationPct    = m["designCirculationPct"]    ?? 0
        d.designSpaceUtilization  = m["designSpaceUtilization"]  ?? 0
        d.designDaylighting       = m["designDaylighting"]       ?? 0
        d.designCO2ppm            = m["designCO2ppm"]            ?? 0
        d.designACH               = m["designACH"]               ?? 0
        d.designThermalComfort    = m["designThermalComfort"]    ?? 0
        d.designAcousticComfort   = m["designAcousticComfort"]   ?? 0
        d.designBiophilicCount    = Int(m["designBiophilicCount"] ?? 0)
        d.designGreenWallM2       = m["designGreenWallM2"]       ?? 0
        d.designViewsToNaturePct  = m["designViewsToNaturePct"]  ?? 0
        d.designNaturalMaterialsPct = m["designNaturalMaterialsPct"] ?? 0
        d.designMovablePartitionPct = m["designMovablePartitionPct"] ?? 0
        d.designMultiUseSpaces    = Int(m["designMultiUseSpaces"] ?? 0)
        d.designAdaptabilityScore = m["designAdaptabilityScore"] ?? 0

        // ── Circular Economy ──────────────────────────────────────────────────
        d.circularTotalConstructionCost  = m["circularTotalConstructionCost"]  ?? 0
        d.circularRepurposedMaterialCost = m["circularRepurposedMaterialCost"] ?? 0
        d.circularCO2Embodied            = m["circularCO2Embodied"]            ?? 0
        d.circularKgMaterialsUsed        = m["circularKgMaterialsUsed"]        ?? 0
        d.circularKgMaterialsReturned    = m["circularKgMaterialsReturned"]    ?? 0
        d.circularKgMaterialsDisposed    = m["circularKgMaterialsDisposed"]    ?? 0
        d.circularRecycledContentPct     = m["circularRecycledContentPct"]     ?? 0
        d.circularRenewableContentPct    = m["circularRenewableContentPct"]    ?? 0
        d.circularWasteGenerated         = m["circularWasteGenerated"]         ?? 0
        d.circularOperationalCarbon      = m["circularOperationalCarbon"]      ?? 0
        d.circularBuildingAreaM2         = m["circularBuildingAreaM2"]         ?? 0
        d.circularWaterRecyclingRate     = m["circularWaterRecyclingRate"]     ?? 0

        // ── Profile weights ───────────────────────────────────────────────────
        d.weightRealEstate  = m["weightRealEstate"]  ?? 25
        d.weightHospitality = m["weightHospitality"] ?? 25
        d.weightDesign      = m["weightDesign"]      ?? 25
        d.weightCircular    = m["weightCircular"]    ?? 25

        return d
    }

    private var resolvedPropertyType: String {
        switch category {
        case "realEstate":  return "Commercial"
        case "hospitality": return "Hospitality"
        case "mixedUse":    return "Mixed-Use"
        case "design":      return "Commercial"
        case "circular":    return "Commercial"
        default:            return "Commercial"
        }
    }

    private func formatCurrency(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "€%.1fM", v / 1_000_000) }
        if v >= 1_000     { return String(format: "€%.0fK", v / 1_000) }
        return "€\(Int(v))"
    }
}

// MARK: - DealTemplates Database

enum DealTemplates {

    static let all: [DealTemplate] = [

        // ── REAL ESTATE ────────────────────────────────────────────────────────

        DealTemplate(
            id: "lisbon_t2_apartment",
            name: "Lisbon T2 Apartment",
            category: "realEstate",
            description: "2-bedroom apartment in central Lisbon. Strong yield in a high-demand rental market with steady appreciation.",
            defaultLocation: "Lisbon, Portugal",
            defaultMetrics: [
                "purchasePrice":          350_000,
                "totalArea":              90,
                "closingCosts":           10_500,
                "grossPotentialIncome":   18_000,
                "vacancyRate":            5.0,
                "operatingExpenses":      3_600,
                "loanAmount":             262_500,
                "interestRate":           4.0,
                "amortizationMonths":     360,
                "exitCapRate":            5.5,
                "opexPropertyManagement": 1_440,
                "opexPropertyTax":        1_050,
                "opexInsurance":          420,
                "opexUtilities":          360,
                "opexMaintenance":        210,
                "opexCapitalReserves":    120,
                "weightRealEstate":       100,
                "weightHospitality":      0,
                "weightDesign":           0,
                "weightCircular":         0,
            ]
        ),

        DealTemplate(
            id: "porto_historic_apartment",
            name: "Porto Historic Apartment",
            category: "realEstate",
            description: "Renovated apartment in Porto's UNESCO heritage centre. High tourist demand with strong short-term rental potential.",
            defaultLocation: "Porto, Portugal",
            defaultMetrics: [
                "purchasePrice":          280_000,
                "totalArea":              75,
                "closingCosts":           8_400,
                "renovationBudget":       15_000,
                "grossPotentialIncome":   14_400,
                "vacancyRate":            7.0,
                "operatingExpenses":      2_880,
                "loanAmount":             196_000,
                "interestRate":           4.25,
                "amortizationMonths":     360,
                "exitCapRate":            5.8,
                "opexPropertyManagement": 1_152,
                "opexPropertyTax":        840,
                "opexInsurance":          336,
                "opexUtilities":          288,
                "opexMaintenance":        168,
                "opexCapitalReserves":    96,
                "weightRealEstate":       100,
                "weightHospitality":      0,
                "weightDesign":           0,
                "weightCircular":         0,
            ]
        ),

        DealTemplate(
            id: "berlin_office_block",
            name: "Berlin Office Block",
            category: "realEstate",
            description: "Class-B office building in Berlin Mitte. Long-term corporate tenants, stable cash flow with value-add potential.",
            defaultLocation: "Berlin, Germany",
            defaultMetrics: [
                "purchasePrice":          5_000_000,
                "totalArea":              2_000,
                "closingCosts":           150_000,
                "grossPotentialIncome":   300_000,
                "vacancyRate":            8.0,
                "operatingExpenses":      75_000,
                "loanAmount":             3_500_000,
                "interestRate":           5.0,
                "amortizationMonths":     300,
                "exitCapRate":            4.8,
                "opexPropertyManagement": 24_000,
                "opexPropertyTax":        20_000,
                "opexInsurance":          8_000,
                "opexUtilities":          12_000,
                "opexMaintenance":        7_000,
                "opexCapitalReserves":    4_000,
                "designGFA":              2_000,
                "designNIA":              1_680,
                "designSpaceUtilization": 80,
                "designDaylighting":      60,
                "weightRealEstate":       80,
                "weightHospitality":      0,
                "weightDesign":           20,
                "weightCircular":         0,
            ]
        ),

        DealTemplate(
            id: "madrid_retail_space",
            name: "Madrid Retail Space",
            category: "realEstate",
            description: "High-street retail unit in central Madrid. Long lease to anchor tenant with built-in rent escalation clauses.",
            defaultLocation: "Madrid, Spain",
            defaultMetrics: [
                "purchasePrice":          1_200_000,
                "totalArea":              800,
                "closingCosts":           36_000,
                "grossPotentialIncome":   96_000,
                "vacancyRate":            10.0,
                "operatingExpenses":      24_000,
                "loanAmount":             840_000,
                "interestRate":           4.75,
                "amortizationMonths":     300,
                "exitCapRate":            5.2,
                "opexPropertyManagement": 9_600,
                "opexPropertyTax":        8_000,
                "opexInsurance":          2_400,
                "opexUtilities":          2_000,
                "opexMaintenance":        1_500,
                "opexCapitalReserves":    500,
                "weightRealEstate":       100,
                "weightHospitality":      0,
                "weightDesign":           0,
                "weightCircular":         0,
            ]
        ),

        DealTemplate(
            id: "algarve_vacation_villa",
            name: "Algarve Vacation Villa",
            category: "realEstate",
            description: "Premium vacation villa in the Algarve coast. High seasonal demand, strong ADR, and tourism growth market.",
            defaultLocation: "Faro, Portugal",
            defaultMetrics: [
                "purchasePrice":          650_000,
                "totalArea":              180,
                "closingCosts":           19_500,
                "grossPotentialIncome":   65_000,
                "vacancyRate":            35.0,
                "operatingExpenses":      16_250,
                "loanAmount":             455_000,
                "interestRate":           4.5,
                "amortizationMonths":     360,
                "exitCapRate":            4.5,
                "opexPropertyManagement": 6_500,
                "opexPropertyTax":        3_900,
                "opexInsurance":          1_950,
                "opexUtilities":          2_600,
                "opexMaintenance":        975,
                "opexCapitalReserves":    325,
                "weightRealEstate":       70,
                "weightHospitality":      30,
                "weightDesign":           0,
                "weightCircular":         0,
            ]
        ),

        // ── HOSPITALITY ────────────────────────────────────────────────────────

        DealTemplate(
            id: "porto_boutique_hotel",
            name: "Porto Boutique Hotel",
            category: "hospitality",
            description: "20-room boutique hotel in Porto's historic centre. High-margin operation with direct booking focus and curated F&B.",
            defaultLocation: "Porto, Portugal",
            defaultMetrics: [
                "purchasePrice":             2_500_000,
                "totalArea":                 1_200,
                "closingCosts":              75_000,
                "loanAmount":                1_750_000,
                "interestRate":              4.5,
                "amortizationMonths":        300,
                "hospitalityRoomCount":      20,
                "hospitalityADR":            120,
                "hospitalityOccupancyRate":  75,
                "hospitalityFBRevenue":      80_000,
                "hospitalitySpaRevenue":     20_000,
                "hospitalityMeetingRevenue": 15_000,
                "hospitalityOpExRatio":      45,
                "hospitalityDirectBookingPct": 60,
                "hospitalityOTABookingPct":  40,
                "hospitalityDistributionCost": 18,
                "weightRealEstate":          30,
                "weightHospitality":         70,
                "weightDesign":              0,
                "weightCircular":            0,
            ]
        ),

        DealTemplate(
            id: "lisbon_city_hotel",
            name: "Lisbon City Hotel",
            category: "hospitality",
            description: "80-room full-service hotel in Lisbon's waterfront district. Mixed MICE and leisure demand with strong ADR growth.",
            defaultLocation: "Lisbon, Portugal",
            defaultMetrics: [
                "purchasePrice":             8_000_000,
                "totalArea":                 3_500,
                "closingCosts":              240_000,
                "loanAmount":                5_600_000,
                "interestRate":              4.75,
                "amortizationMonths":        240,
                "hospitalityRoomCount":      80,
                "hospitalityADR":            150,
                "hospitalityOccupancyRate":  80,
                "hospitalityFBRevenue":      400_000,
                "hospitalitySpaRevenue":     60_000,
                "hospitalityMeetingRevenue": 120_000,
                "hospitalityOpExRatio":      48,
                "hospitalityDirectBookingPct": 50,
                "hospitalityOTABookingPct":  50,
                "hospitalityDistributionCost": 20,
                "weightRealEstate":          20,
                "weightHospitality":         80,
                "weightDesign":              0,
                "weightCircular":            0,
            ]
        ),

        DealTemplate(
            id: "algarve_beach_resort",
            name: "Algarve Beach Resort",
            category: "hospitality",
            description: "150-room beach resort in the Algarve. Full-service amenities with strong RevPAR driven by peak summer season.",
            defaultLocation: "Lagos, Portugal",
            defaultMetrics: [
                "purchasePrice":             18_000_000,
                "totalArea":                 15_000,
                "closingCosts":              540_000,
                "loanAmount":                12_600_000,
                "interestRate":              5.0,
                "amortizationMonths":        240,
                "hospitalityRoomCount":      150,
                "hospitalityADR":            200,
                "hospitalityOccupancyRate":  70,
                "hospitalityFBRevenue":      800_000,
                "hospitalitySpaRevenue":     300_000,
                "hospitalityMeetingRevenue": 150_000,
                "hospitalityOpExRatio":      52,
                "hospitalityDirectBookingPct": 45,
                "hospitalityOTABookingPct":  55,
                "hospitalityDistributionCost": 22,
                "weightRealEstate":          20,
                "weightHospitality":         60,
                "weightDesign":              20,
                "weightCircular":            0,
            ]
        ),

        // ── MIXED-USE ─────────────────────────────────────────────────────────

        DealTemplate(
            id: "paris_mixed_use_building",
            name: "Paris Mixed-Use Building",
            category: "mixedUse",
            description: "Haussmann-era building combining ground-floor retail, serviced apartments, and office space in central Paris.",
            defaultLocation: "Paris, France",
            defaultMetrics: [
                "purchasePrice":             12_000_000,
                "totalArea":                 3_000,
                "closingCosts":              360_000,
                "grossPotentialIncome":      600_000,
                "vacancyRate":               6.0,
                "operatingExpenses":         120_000,
                "loanAmount":                8_400_000,
                "interestRate":              4.5,
                "amortizationMonths":        240,
                "exitCapRate":               4.2,
                "opexPropertyManagement":    48_000,
                "opexPropertyTax":           36_000,
                "opexInsurance":             12_000,
                "opexUtilities":             15_000,
                "opexMaintenance":           6_000,
                "opexCapitalReserves":       3_000,
                "hospitalityRoomCount":      20,
                "hospitalityADR":            180,
                "hospitalityOccupancyRate":  65,
                "hospitalityOpExRatio":      42,
                "designGFA":                 3_000,
                "designNIA":                 2_550,
                "designSpaceUtilization":    82,
                "designDaylighting":         55,
                "weightRealEstate":          50,
                "weightHospitality":         30,
                "weightDesign":              20,
                "weightCircular":            0,
            ]
        ),

        DealTemplate(
            id: "barcelona_creative_loft",
            name: "Barcelona Creative Loft Complex",
            category: "mixedUse",
            description: "Converted industrial building in Poblenou. Creative offices, co-working, and live-work lofts with strong design pedigree.",
            defaultLocation: "Barcelona, Spain",
            defaultMetrics: [
                "purchasePrice":          4_500_000,
                "totalArea":              2_200,
                "closingCosts":           135_000,
                "renovationBudget":       450_000,
                "grossPotentialIncome":   270_000,
                "vacancyRate":            8.0,
                "operatingExpenses":      54_000,
                "loanAmount":             3_150_000,
                "interestRate":           4.5,
                "amortizationMonths":     300,
                "exitCapRate":            4.6,
                "opexPropertyManagement": 21_600,
                "opexPropertyTax":        13_500,
                "opexInsurance":          5_400,
                "opexUtilities":          8_100,
                "opexMaintenance":        4_050,
                "opexCapitalReserves":    1_350,
                "designGFA":              2_200,
                "designNIA":              1_870,
                "designSpaceUtilization": 85,
                "designDaylighting":      70,
                "designBiophilicCount":   8,
                "designThermalComfort":   82,
                "designAcousticComfort":  78,
                "designAdaptabilityScore": 80,
                "circularRecycledContentPct": 35,
                "circularRenewableContentPct": 20,
                "circularBuildingAreaM2": 2_200,
                "weightRealEstate":       40,
                "weightHospitality":      0,
                "weightDesign":           40,
                "weightCircular":         20,
            ]
        ),

        // ── DESIGN ────────────────────────────────────────────────────────────

        DealTemplate(
            id: "amsterdam_green_office",
            name: "Amsterdam Green Office",
            category: "design",
            description: "BREEAM-Excellent office campus in Amsterdam South. High daylighting, biophilic design, and adaptive floor plates.",
            defaultLocation: "Amsterdam, Netherlands",
            defaultMetrics: [
                "purchasePrice":          7_500_000,
                "totalArea":              4_000,
                "closingCosts":           225_000,
                "grossPotentialIncome":   375_000,
                "vacancyRate":            8.0,
                "operatingExpenses":      75_000,
                "loanAmount":             5_250_000,
                "interestRate":           5.0,
                "amortizationMonths":     240,
                "exitCapRate":            4.5,
                "opexPropertyManagement": 30_000,
                "opexPropertyTax":        22_500,
                "opexInsurance":          7_500,
                "opexUtilities":          9_000,
                "opexMaintenance":        4_500,
                "opexCapitalReserves":    1_500,
                "designGFA":              4_000,
                "designNIA":              3_400,
                "designCirculationPct":   10,
                "designSpaceUtilization": 88,
                "designDaylighting":      80,
                "designCO2ppm":           700,
                "designACH":              8,
                "designThermalComfort":   90,
                "designAcousticComfort":  85,
                "designBiophilicCount":   12,
                "designGreenWallM2":      80,
                "designViewsToNaturePct": 75,
                "designNaturalMaterialsPct": 40,
                "designMovablePartitionPct": 60,
                "designMultiUseSpaces":   6,
                "designAdaptabilityScore": 88,
                "circularRecycledContentPct": 55,
                "circularRenewableContentPct": 40,
                "circularBuildingAreaM2": 4_000,
                "weightRealEstate":       25,
                "weightHospitality":      0,
                "weightDesign":           50,
                "weightCircular":         25,
            ]
        ),

        // ── CIRCULAR ──────────────────────────────────────────────────────────

        DealTemplate(
            id: "copenhagen_sustainable_dev",
            name: "Copenhagen Sustainable Development",
            category: "circular",
            description: "Net-zero mixed-use development in Copenhagen Harbour. Circular construction, renewable energy, and DGNB Platinum target.",
            defaultLocation: "Copenhagen, Denmark",
            defaultMetrics: [
                "purchasePrice":          15_000_000,
                "totalArea":              8_000,
                "closingCosts":           450_000,
                "grossPotentialIncome":   750_000,
                "vacancyRate":            5.0,
                "operatingExpenses":      112_500,
                "loanAmount":             10_500_000,
                "interestRate":           4.75,
                "amortizationMonths":     240,
                "exitCapRate":            4.0,
                "opexPropertyManagement": 45_000,
                "opexPropertyTax":        30_000,
                "opexInsurance":          15_000,
                "opexUtilities":          12_500,
                "opexMaintenance":        7_500,
                "opexCapitalReserves":    2_500,
                "hospitalityRoomCount":   30,
                "hospitalityADR":         200,
                "hospitalityOccupancyRate": 75,
                "hospitalityOpExRatio":   44,
                "designGFA":              8_000,
                "designNIA":              7_000,
                "designSpaceUtilization": 90,
                "designDaylighting":      85,
                "designCO2ppm":           650,
                "designACH":              10,
                "designThermalComfort":   92,
                "designAcousticComfort":  88,
                "designBiophilicCount":   15,
                "designGreenWallM2":      200,
                "designViewsToNaturePct": 80,
                "designNaturalMaterialsPct": 60,
                "designMovablePartitionPct": 70,
                "designMultiUseSpaces":   10,
                "designAdaptabilityScore": 92,
                "circularTotalConstructionCost":  14_000_000,
                "circularRepurposedMaterialCost": 3_500_000,
                "circularCO2Embodied":            800,
                "circularKgMaterialsUsed":        4_000_000,
                "circularKgMaterialsReturned":    2_800_000,
                "circularKgMaterialsDisposed":    400_000,
                "circularRecycledContentPct":     75,
                "circularRenewableContentPct":    60,
                "circularWasteGenerated":         200_000,
                "circularOperationalCarbon":      50,
                "circularBuildingAreaM2":         8_000,
                "circularWaterRecyclingRate":     80,
                "weightRealEstate":       20,
                "weightHospitality":      20,
                "weightDesign":           30,
                "weightCircular":         30,
            ]
        ),
    ]

    // MARK: – Lookup Helpers

    static func templates(for category: String) -> [DealTemplate] {
        category == "all" ? all : all.filter { $0.category == category }
    }

    static func template(id: String) -> DealTemplate? {
        all.first { $0.id == id }
    }
}
