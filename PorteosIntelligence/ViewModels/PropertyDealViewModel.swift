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

    /// Kept for legacy callers in HospitalityDashboardView / PorteosScoreBlock that reference
    /// `.effectiveGrossIncome` or `.debtServiceCoverageRatio` from the old struct.
    /// New code should derive values from `realEstateFullMetrics` instead.
    var realEstateMetrics: RealEstateCalculator.RealEstateMetrics {
        RealEstateCalculator.calculate(inputs: RealEstateCalculator.RealEstateInputs(
            grossPotentialIncome: deal.grossPotentialIncome,
            vacancyRate:          deal.vacancyRate,
            operatingExpenses:    deal.operatingExpenses,
            purchasePrice:        deal.purchasePrice,
            loanAmount:           deal.loanAmount,
            interestRate:         deal.interestRate,
            amortizationMonths:   deal.amortizationMonths
        ))
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

    var porteosScore: PorteosScoreCalculator.PorteosMetrics {
        PorteosScoreCalculator.calculate(inputs: PorteosScoreCalculator.PorteosInputs(
            capRate:           realEstateFullMetrics.capRate,
            revPAR:            hospitalityMetrics.revPAR,
            designScore:       0,   // TODO: wire DesignCalculator when design inputs added to PropertyDeal
            circularScore:     circularMetrics.overallCEScore,
            totalRevenue:      hospitalityMetrics.totalRevenue,
            weightRealEstate:  deal.weightRealEstate,
            weightHospitality: deal.weightHospitality,
            weightDesign:      deal.weightDesign,
            weightCircular:    deal.weightCircular
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
}
