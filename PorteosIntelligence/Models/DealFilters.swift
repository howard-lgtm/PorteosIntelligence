import Foundation

// MARK: - DealFilters

struct DealFilters: Equatable {

    var searchText:     String  = ""
    var minPrice:       Double? = nil
    var maxPrice:       Double? = nil
    var minCapRate:     Double? = nil
    var maxCapRate:     Double? = nil
    var minNOI:         Double? = nil
    var maxNOI:         Double? = nil
    var minScore:       Double? = nil
    var maxScore:       Double? = nil
    var hasRealEstate:  Bool    = false
    var hasHospitality: Bool    = false
    var hasDesign:      Bool    = false
    var hasCircular:    Bool    = false
    var locationFilter: String  = ""

    // MARK: Active state

    var isActive: Bool {
        !searchText.isEmpty
        || minPrice  != nil || maxPrice  != nil
        || minCapRate != nil || maxCapRate != nil
        || minNOI    != nil || maxNOI    != nil
        || minScore  != nil || maxScore  != nil
        || hasRealEstate || hasHospitality || hasDesign || hasCircular
        || !locationFilter.isEmpty
    }

    // MARK: Clear

    mutating func clear() {
        searchText     = ""
        minPrice       = nil;  maxPrice    = nil
        minCapRate     = nil;  maxCapRate  = nil
        minNOI         = nil;  maxNOI      = nil
        minScore       = nil;  maxScore    = nil
        hasRealEstate  = false
        hasHospitality = false
        hasDesign      = false
        hasCircular    = false
        locationFilter = ""
    }

    // MARK: Matching

    func matches(deal: PropertyDeal) -> Bool {

        // ── Text search ───────────────────────────────────────────────────────
        if !searchText.isEmpty {
            let q         = searchText.lowercased()
            let haystack  = "\(deal.propertyName) \(deal.locationCity) \(deal.address)".lowercased()
            if !haystack.contains(q) { return false }
        }

        // ── Purchase price ────────────────────────────────────────────────────
        if let min = minPrice,  deal.purchasePrice < min { return false }
        if let max = maxPrice,  deal.purchasePrice > max { return false }

        // ── Porteos score ─────────────────────────────────────────────────────
        if let min = minScore, (deal.porteosScore ?? 0) < min { return false }
        if let max = maxScore, (deal.porteosScore ?? 0) > max { return false }

        // ── Cap rate & NOI (computed on-demand) ───────────────────────────────
        if minCapRate != nil || maxCapRate != nil || minNOI != nil || maxNOI != nil {
            let m = RealEstateCalculator.calculateFull(inputs: fullInputs(from: deal))
            if let min = minCapRate, m.capRate             < min { return false }
            if let max = maxCapRate, m.capRate             > max { return false }
            if let min = minNOI,    m.netOperatingIncome   < min { return false }
            if let max = maxNOI,    m.netOperatingIncome   > max { return false }
        }

        // ── Profile data presence ─────────────────────────────────────────────
        if hasRealEstate  && deal.purchasePrice <= 0 && deal.grossPotentialIncome <= 0      { return false }
        if hasHospitality && deal.hospitalityRoomCount <= 0 && deal.hospitalityADR <= 0     { return false }
        if hasDesign      && deal.designGFA <= 0 && deal.designNIA <= 0                     { return false }
        if hasCircular    && deal.circularRecycledContentPct <= 0
                          && deal.circularRenewableContentPct <= 0                          { return false }

        // ── Location ──────────────────────────────────────────────────────────
        if !locationFilter.isEmpty {
            if !deal.locationCity.lowercased().contains(locationFilter.lowercased()) { return false }
        }

        return true
    }

    // MARK: Private helpers

    private func fullInputs(from d: PropertyDeal) -> RealEstateCalculator.FullInputs {
        RealEstateCalculator.FullInputs(
            grossPotentialIncome:   d.grossPotentialIncome,
            vacancyRate:            d.vacancyRate,
            otherIncome:            d.otherIncome,
            operatingExpenses:      d.operatingExpenses,
            opexPropertyManagement: d.opexPropertyManagement,
            opexPropertyTax:        d.opexPropertyTax,
            opexInsurance:          d.opexInsurance,
            opexUtilities:          d.opexUtilities,
            opexMaintenance:        d.opexMaintenance,
            opexCapitalReserves:    d.opexCapitalReserves,
            purchasePrice:          d.purchasePrice,
            closingCosts:           d.closingCosts,
            renovationBudget:       d.renovationBudget,
            loanAmount:             d.loanAmount,
            interestRate:           d.interestRate,
            amortizationMonths:     d.amortizationMonths,
            exitCapRate:            d.exitCapRate
        )
    }
}
