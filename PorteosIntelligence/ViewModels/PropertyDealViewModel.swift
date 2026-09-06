import Foundation

// MARK: - MetricType

enum MetricType {
    case dscr
    case ltv
    case occupancy
    case neutral
}

// MARK: - PropertyDealViewModel

@Observable
final class PropertyDealViewModel {

    private let deal: PropertyDeal

    init(deal: PropertyDeal) {
        self.deal = deal
    }

    // MARK: - Computed Metrics

    /// Single source of truth for all real estate metrics — used by both porteosScore and formattedNOI.
    private var realEstateFullMetrics: RealEstateCalculator.FullMetrics {
        RealEstateCalculator.calculateFull(inputs: RealEstateCalculator.FullInputs(
            grossPotentialIncome:   deal.grossPotentialIncome,
            vacancyRate:            deal.vacancyRate,
            otherIncome:            deal.otherIncome,
            operatingExpenses:      deal.operatingExpenses,
            opexPropertyManagement: deal.opexPropertyManagement,
            opexPropertyTax:        deal.opexPropertyTax,
            opexInsurance:          deal.opexInsurance,
            opexUtilities:          deal.opexUtilities,
            opexMaintenance:        deal.opexMaintenance,
            opexCapitalReserves:    deal.opexCapitalReserves,
            purchasePrice:          deal.purchasePrice,
            closingCosts:           deal.closingCosts,
            renovationBudget:       deal.renovationBudget,
            loanAmount:             deal.loanAmount,
            interestRate:           deal.interestRate,
            amortizationMonths:     deal.amortizationMonths,
            exitCapRate:            deal.exitCapRate
        ))
    }

    /// Maps full metrics for legacy callers that still expect `RealEstateMetrics`.
    var realEstateMetrics: RealEstateCalculator.RealEstateMetrics {
        let m = realEstateFullMetrics
        return RealEstateCalculator.RealEstateMetrics(
            effectiveGrossIncome:     m.effectiveGrossIncome,
            netOperatingIncome:       m.netOperatingIncome,
            capRate:                  m.capRate,
            loanToValue:              m.loanToValue,
            debtServiceCoverageRatio: m.debtServiceCoverageRatio
        )
    }

    var hospitalityMetrics: HospitalityCalculator.HospitalityMetrics {
        HospitalityCalculator.calculate(inputs: HospitalityCalculator.HospitalityInputs(
            roomCount:      deal.hospitalityRoomCount,
            adr:            deal.hospitalityADR,
            occupancyRate:  deal.hospitalityOccupancyRate,
            fbRevenue:      deal.hospitalityFBRevenue,
            spaRevenue:     deal.hospitalitySpaRevenue,
            meetingRevenue: deal.hospitalityMeetingRevenue,
            otherRevenue:   deal.hospitalityOtherRevenue,
            opExRatio:      deal.hospitalityOpExRatio
        ))
    }

    var circularMetrics: CircularEconomyCalculator.CircularEconomyMetrics {
        CircularEconomyCalculator.calculate(inputs: CircularEconomyCalculator.CircularEconomyInputs(
            totalConstructionCost:  deal.circularTotalConstructionCost,
            repurposedMaterialCost: deal.circularRepurposedMaterialCost,
            co2Embodied:            deal.circularCO2Embodied,
            kgMaterialsUsed:        deal.circularKgMaterialsUsed,
            kgMaterialsReturned:    deal.circularKgMaterialsReturned,
            kgMaterialsDisposed:    deal.circularKgMaterialsDisposed,
            vendorCount:            0,
            averageHourlyRate:      0
        ))
    }

    /// Design score (0–100) derived from DesignCalculator FullMetrics.
    /// Only non-zero fields contribute so partially-filled deals aren't penalised.
    private var designScore: Double {
        guard deal.designGFA > 0 || deal.designDaylighting > 0 ||
              deal.designAdaptabilityScore > 0 || deal.designBiophilicCount > 0 else { return 0 }
        let des = DesignCalculator.calculateFull(inputs: .init(
            gfa:               deal.designGFA,
            nia:               deal.designNIA,
            circulationPct:    deal.designCirculationPct,
            spaceUtilization:  deal.designSpaceUtilization,
            daylighting:       deal.designDaylighting,
            co2ppm:            deal.designCO2ppm,
            ach:               deal.designACH,
            thermalComfort:    deal.designThermalComfort,
            acousticComfort:   deal.designAcousticComfort,
            biophilicCount:    deal.designBiophilicCount,
            greenWallM2:       deal.designGreenWallM2,
            viewsToNaturePct:  deal.designViewsToNaturePct,
            naturalMaterialsPct: deal.designNaturalMaterialsPct,
            movablePartitionPct: deal.designMovablePartitionPct,
            multiUseSpaces:    deal.designMultiUseSpaces,
            adaptabilityScore: deal.designAdaptabilityScore
        ))
        var components: [Double] = []
        if des.daylighting > 0      { components.append(des.daylighting) }
        if des.thermalComfort > 0   { components.append(des.thermalComfort) }
        if des.acousticComfort > 0  { components.append(des.acousticComfort) }
        if des.spaceUtilization > 0 { components.append(min(des.spaceUtilization, 100)) }
        if des.adaptabilityScore > 0 { components.append(des.adaptabilityScore) }
        if des.biophilicCount > 0   { components.append(min(Double(des.biophilicCount) * 25, 100)) }
        return components.isEmpty ? 0 : components.reduce(0, +) / Double(components.count)
    }

    var porteosScore: PorteosScoreCalculator.PorteosMetrics {
        let re = realEstateFullMetrics
        return PorteosScoreCalculator.calculate(inputs: PorteosScoreCalculator.PorteosInputs(
            capRate:           re.capRate,
            revPAR:            hospitalityMetrics.revPAR,
            designScore:       designScore,
            circularScore:     circularMetrics.overallCEScore,
            totalRevenue:      hospitalityMetrics.totalRevenue,
            dscr:              re.debtServiceCoverageRatio,
            ltv:               re.loanToValue,
            cashOnCash:        re.cashOnCashReturn,
            weightRealEstate:  deal.weightRealEstate,
            weightHospitality: deal.weightHospitality,
            weightDesign:      deal.weightDesign,
            weightCircular:    deal.weightCircular,
            heritageOrListed:  deal.heritageOrListed,
            planningStatus:    deal.planningStatus,
            strLicenceStatus:  deal.strLicenceStatus
        ))
    }

    // MARK: - Threshold Logic

    func getMetricState(for value: Double, type: MetricType) -> MetricState {
        switch type {
        case .dscr:
            if value >= 1.25 { return .optimal }
            if value >= 1.10 { return .warning }
            return .critical
        case .ltv:
            if value <= 75.0 { return .optimal }
            if value <= 90.0 { return .warning }
            return .critical
        case .occupancy:
            if value > 70 { return .optimal }
            if value > 50 { return .warning }
            return .critical
        case .neutral:
            return .neutral
        }
    }

    // MARK: - Formatted Outputs

    var formattedNOI: String {
        realEstateFullMetrics.netOperatingIncome.formatted(.currency(code: "EUR"))
    }

    var formattedADR: String {
        deal.hospitalityADR.formatted(.currency(code: "EUR"))
    }

    var formattedOccupancyRate: String {
        "\(deal.hospitalityOccupancyRate.formatted(.number.precision(.fractionLength(1))))%"
    }

    var occupancyState: MetricState {
        getMetricState(for: deal.hospitalityOccupancyRate, type: .occupancy)
    }

    // MARK: - Unit Price

    var pricePerSqft: Double {
        RealEstateCalculator.pricePerSqft(
            purchasePrice: deal.purchasePrice,
            totalArea: deal.totalArea
        )
    }
}
