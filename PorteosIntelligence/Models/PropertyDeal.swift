import Foundation
import SwiftData

// MARK: - DealStatus

enum DealStatus: String, Codable, CaseIterable {
    case viable
    case review
    case rejected
    case acquired
    case pipeline
}

// MARK: - GeocodeStatus

enum GeocodeStatus: String, Codable, CaseIterable {
    case none
    case pending
    case ok
    case failed
}

// MARK: - PropertyDeal

@Model
final class PropertyDeal {

    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // MARK: Base Data
    var propertyName:    String
    var address:         String
    var propertyType:    String
    var totalArea:       Double   // built / floor area (m²)
    var landArea:        Double   // rustic / plot area (m²) — quintas, rural
    var locationCity:    String

    // MARK: Global Intelligence / Geo
    var latitude:         Double?
    var longitude:        Double?
    var geocodeStatusRaw: String
    var marketId:         String

    // MARK: Real Estate Core Financials
    var purchasePrice:        Double
    var closingCosts:         Double
    var renovationBudget:     Double
    var grossPotentialIncome: Double
    var vacancyRate:          Double   // percentage (e.g. 5 = 5 %)
    var otherIncome:          Double   // annual other/ancillary income
    var operatingExpenses:    Double   // total annual OpEx (summary field)
    var loanAmount:           Double
    var interestRate:         Double   // annual percentage
    var amortizationMonths:   Int
    var exitCapRate:          Double   // percentage for exit valuation

    // MARK: Real Estate OpEx Breakdown
    // Individual line items; when any are > 0 the dashboard uses their sum,
    // otherwise falls back to operatingExpenses.
    var opexPropertyManagement: Double
    var opexPropertyTax:        Double
    var opexInsurance:          Double
    var opexUtilities:          Double
    var opexMaintenance:        Double
    var opexCapitalReserves:    Double

    // MARK: Hospitality Inputs
    var hospitalityRoomCount:        Int
    var hospitalityADR:              Double
    var hospitalityOccupancyRate:    Double
    var hospitalityFBRevenue:        Double
    var hospitalitySpaRevenue:       Double
    var hospitalityMeetingRevenue:   Double
    var hospitalityOtherRevenue:     Double
    var hospitalityOpExRatio:        Double
    var hospitalityDirectBookingPct: Double  // % of bookings via direct channel
    var hospitalityOTABookingPct:    Double  // % of bookings via OTA
    var hospitalityDistributionCost: Double  // annual distribution/channel cost (€)

    // MARK: Circular Economy Inputs
    var circularTotalConstructionCost:  Double
    var circularRepurposedMaterialCost: Double
    var circularCO2Embodied:            Double   // kg CO2e (embodied)
    var circularKgMaterialsUsed:        Double
    var circularKgMaterialsReturned:    Double
    var circularKgMaterialsDisposed:    Double
    var circularRecycledContentPct:     Double   // %
    var circularRenewableContentPct:    Double   // %
    var circularWasteGenerated:         Double   // kg
    var circularOperationalCarbon:      Double   // tCO2e/year
    var circularBuildingAreaM2:         Double   // m² (for carbon intensity)
    var circularWaterRecyclingRate:     Double   // %

    // MARK: Design Inputs
    var designGFA:                 Double  // Gross Floor Area (m²)
    var designNIA:                 Double  // Net Internal Area (m²)
    var designCirculationPct:      Double  // %
    var designSpaceUtilization:    Double  // Space Utilization Rate (%)
    var designDaylighting:         Double  // Daylighting Coverage (%)
    var designCO2ppm:              Double  // CO2 Levels (ppm)
    var designACH:                 Double  // Air Changes Per Hour
    var designThermalComfort:      Double  // Thermal Comfort Score (%)
    var designAcousticComfort:     Double  // Acoustic Comfort Score (%)
    var designBiophilicCount:      Int     // count
    var designGreenWallM2:         Double  // Green Wall Coverage (m²)
    var designViewsToNaturePct:    Double  // Views to Nature (%)
    var designNaturalMaterialsPct: Double  // Natural Materials (%)
    var designMovablePartitionPct: Double  // Movable Partition (%)
    var designMultiUseSpaces:      Int     // count
    var designAdaptabilityScore:   Double  // 0–100

    // MARK: Profile Weights
    var weightRealEstate:  Double
    var weightHospitality: Double
    var weightDesign:      Double
    var weightCircular:    Double

    // MARK: Scoring
    var porteosScore: Double?

    // MARK: Metadata
    var notes:      String
    var tags:       [String]
    var isFavorite: Bool
    var status:     DealStatus

    // MARK: AI
    var aiAnalysisText: String?

    // MARK: - Computed helpers

    /// Returns the sum of individual OpEx line items if any have been entered;
    /// otherwise falls back to the `operatingExpenses` summary field.
    var effectiveOpEx: Double {
        let lineItemSum = opexPropertyManagement + opexPropertyTax + opexInsurance
                       + opexUtilities + opexMaintenance + opexCapitalReserves
        return lineItemSum > 0 ? lineItemSum : operatingExpenses
    }

    var geocodeStatus: GeocodeStatus {
        get { GeocodeStatus(rawValue: geocodeStatusRaw) ?? .none }
        set { geocodeStatusRaw = newValue.rawValue }
    }

    var isGeocoded: Bool {
        geocodeStatus == .ok && latitude != nil && longitude != nil
    }

    /// Map pin can render while geocode is pending — coords are kept until replaced.
    var hasPlottableCoordinates: Bool {
        guard let lat = latitude, let lon = longitude else { return false }
        return lat != 0 || lon != 0
    }

    var needsGeocode: Bool {
        geocodeStatus == .none || geocodeStatus == .pending
            || (geocodeStatus == .failed && (!address.isEmpty || !locationCity.isEmpty))
    }

    // MARK: - Init

    init(
        id:                          UUID    = UUID(),
        createdAt:                   Date    = Date(),
        updatedAt:                   Date    = Date(),
        propertyName:                String  = "",
        address:                     String  = "",
        propertyType:                String  = "",
        totalArea:                   Double  = 0,
        landArea:                    Double  = 0,
        locationCity:                String  = "",
        latitude:                    Double? = nil,
        longitude:                   Double? = nil,
        geocodeStatusRaw:            String  = GeocodeStatus.none.rawValue,
        marketId:                    String  = "",
        purchasePrice:               Double  = 0,
        closingCosts:                Double  = 0,
        renovationBudget:            Double  = 0,
        grossPotentialIncome:        Double  = 0,
        vacancyRate:                 Double  = 0,
        otherIncome:                 Double  = 0,
        operatingExpenses:           Double  = 0,
        loanAmount:                  Double  = 0,
        interestRate:                Double  = 0,
        amortizationMonths:          Int     = 360,
        exitCapRate:                 Double  = 0,
        opexPropertyManagement:      Double  = 0,
        opexPropertyTax:             Double  = 0,
        opexInsurance:               Double  = 0,
        opexUtilities:               Double  = 0,
        opexMaintenance:             Double  = 0,
        opexCapitalReserves:         Double  = 0,
        hospitalityRoomCount:        Int     = 0,
        hospitalityADR:              Double  = 0,
        hospitalityOccupancyRate:    Double  = 0,
        hospitalityFBRevenue:        Double  = 0,
        hospitalitySpaRevenue:       Double  = 0,
        hospitalityMeetingRevenue:   Double  = 0,
        hospitalityOtherRevenue:     Double  = 0,
        hospitalityOpExRatio:        Double  = 0,
        hospitalityDirectBookingPct: Double  = 0,
        hospitalityOTABookingPct:    Double  = 0,
        hospitalityDistributionCost: Double  = 0,
        circularTotalConstructionCost:  Double = 0,
        circularRepurposedMaterialCost: Double = 0,
        circularCO2Embodied:            Double = 0,
        circularKgMaterialsUsed:        Double = 0,
        circularKgMaterialsReturned:    Double = 0,
        circularKgMaterialsDisposed:    Double = 0,
        circularRecycledContentPct:     Double = 0,
        circularRenewableContentPct:    Double = 0,
        circularWasteGenerated:         Double = 0,
        circularOperationalCarbon:      Double = 0,
        circularBuildingAreaM2:         Double = 0,
        circularWaterRecyclingRate:     Double = 0,
        designGFA:                 Double = 0,
        designNIA:                 Double = 0,
        designCirculationPct:      Double = 0,
        designSpaceUtilization:    Double = 0,
        designDaylighting:         Double = 0,
        designCO2ppm:              Double = 0,
        designACH:                 Double = 0,
        designThermalComfort:      Double = 0,
        designAcousticComfort:     Double = 0,
        designBiophilicCount:      Int    = 0,
        designGreenWallM2:         Double = 0,
        designViewsToNaturePct:    Double = 0,
        designNaturalMaterialsPct: Double = 0,
        designMovablePartitionPct: Double = 0,
        designMultiUseSpaces:      Int    = 0,
        designAdaptabilityScore:   Double = 0,
        weightRealEstate:            Double  = 25,
        weightHospitality:           Double  = 25,
        weightDesign:                Double  = 25,
        weightCircular:              Double  = 25,
        porteosScore:                Double? = nil,
        notes:                       String  = "",
        tags:                        [String] = [],
        isFavorite:                  Bool    = false,
        status:                      DealStatus = .pipeline,
        aiAnalysisText:              String? = nil
    ) {
        self.id                             = id
        self.createdAt                      = createdAt
        self.updatedAt                      = updatedAt
        self.propertyName                   = propertyName
        self.address                        = address
        self.propertyType                   = propertyType
        self.totalArea                      = totalArea
        self.landArea                       = landArea
        self.locationCity                   = locationCity
        self.latitude                       = latitude
        self.longitude                      = longitude
        self.geocodeStatusRaw               = geocodeStatusRaw
        self.marketId                       = marketId
        self.purchasePrice                  = purchasePrice
        self.closingCosts                   = closingCosts
        self.renovationBudget               = renovationBudget
        self.grossPotentialIncome           = grossPotentialIncome
        self.vacancyRate                    = vacancyRate
        self.otherIncome                    = otherIncome
        self.operatingExpenses              = operatingExpenses
        self.loanAmount                     = loanAmount
        self.interestRate                   = interestRate
        self.amortizationMonths             = amortizationMonths
        self.exitCapRate                    = exitCapRate
        self.opexPropertyManagement         = opexPropertyManagement
        self.opexPropertyTax                = opexPropertyTax
        self.opexInsurance                  = opexInsurance
        self.opexUtilities                  = opexUtilities
        self.opexMaintenance                = opexMaintenance
        self.opexCapitalReserves            = opexCapitalReserves
        self.hospitalityRoomCount           = hospitalityRoomCount
        self.hospitalityADR                 = hospitalityADR
        self.hospitalityOccupancyRate       = hospitalityOccupancyRate
        self.hospitalityFBRevenue           = hospitalityFBRevenue
        self.hospitalitySpaRevenue          = hospitalitySpaRevenue
        self.hospitalityMeetingRevenue      = hospitalityMeetingRevenue
        self.hospitalityOtherRevenue        = hospitalityOtherRevenue
        self.hospitalityOpExRatio           = hospitalityOpExRatio
        self.hospitalityDirectBookingPct    = hospitalityDirectBookingPct
        self.hospitalityOTABookingPct       = hospitalityOTABookingPct
        self.hospitalityDistributionCost    = hospitalityDistributionCost
        self.circularTotalConstructionCost  = circularTotalConstructionCost
        self.circularRepurposedMaterialCost = circularRepurposedMaterialCost
        self.circularCO2Embodied            = circularCO2Embodied
        self.circularKgMaterialsUsed        = circularKgMaterialsUsed
        self.circularKgMaterialsReturned    = circularKgMaterialsReturned
        self.circularKgMaterialsDisposed    = circularKgMaterialsDisposed
        self.circularRecycledContentPct     = circularRecycledContentPct
        self.circularRenewableContentPct    = circularRenewableContentPct
        self.circularWasteGenerated         = circularWasteGenerated
        self.circularOperationalCarbon      = circularOperationalCarbon
        self.circularBuildingAreaM2         = circularBuildingAreaM2
        self.circularWaterRecyclingRate     = circularWaterRecyclingRate
        self.designGFA                 = designGFA
        self.designNIA                 = designNIA
        self.designCirculationPct      = designCirculationPct
        self.designSpaceUtilization    = designSpaceUtilization
        self.designDaylighting         = designDaylighting
        self.designCO2ppm              = designCO2ppm
        self.designACH                 = designACH
        self.designThermalComfort      = designThermalComfort
        self.designAcousticComfort     = designAcousticComfort
        self.designBiophilicCount      = designBiophilicCount
        self.designGreenWallM2         = designGreenWallM2
        self.designViewsToNaturePct    = designViewsToNaturePct
        self.designNaturalMaterialsPct = designNaturalMaterialsPct
        self.designMovablePartitionPct = designMovablePartitionPct
        self.designMultiUseSpaces      = designMultiUseSpaces
        self.designAdaptabilityScore   = designAdaptabilityScore
        self.weightRealEstate               = weightRealEstate
        self.weightHospitality              = weightHospitality
        self.weightDesign                   = weightDesign
        self.weightCircular                 = weightCircular
        self.porteosScore                   = porteosScore
        self.notes                          = notes
        self.tags                           = tags
        self.isFavorite                     = isFavorite
        self.status                         = status
        self.aiAnalysisText                 = aiAnalysisText
    }
}
