import Foundation
import SwiftData

// MARK: - TrendRecorder
//
// Records key metrics from a PropertyDeal into MarketTrend whenever a deal is
// saved (manual edit) or ingested (browser extension / email import). This
// builds the time-series dataset that TrendAnalyzer and the Market Intelligence
// signals draw from — entirely on-device, no API calls required.
//
// Time-decay: newer observations are not re-weighted here because
// TrendAnalyzer.calculateTrend already emphasises the most-recent window by
// computing separate 1-month / 3-month / 6-month averages. Recording one row
// per save event is sufficient.

enum TrendRecorder {

    // MARK: – Public entry point

    /// Records all meaningful metrics for the deal into `MarketTrend`.
    /// Safe to call on any actor — uses only the provided `ModelContext`.
    static func record(_ deal: PropertyDeal, context: ModelContext, source: String = "portfolio") {
        guard !deal.locationCity.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // Prune rows older than 90 days to prevent unbounded growth
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? .distantPast
        if let stale = try? context.fetch(
            FetchDescriptor<MarketTrend>(
                predicate: #Predicate { $0.recordedAt < cutoff }
            )
        ) {
            stale.forEach { context.delete($0) }
        }

        let city    = deal.locationCity
        let country = "unknown"   // PropertyDeal has no locationCountry field

        // ── Real estate metrics ────────────────────────────────────────────────
        if deal.purchasePrice > 0 || deal.grossPotentialIncome > 0 {
            let re = RealEstateCalculator.calculateFull(inputs: .init(
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

            let reMetrics: [(String, Double)] = [
                ("capRate",       re.capRate),
                ("noi",           re.netOperatingIncome),
                ("ltv",           re.loanToValue),
                ("dscr",          re.debtServiceCoverageRatio),
                ("cashOnCash",    re.cashOnCashReturn),
                ("purchasePrice", deal.purchasePrice),
                ("vacancyRate",   deal.vacancyRate),
                ("interestRate",  deal.interestRate),
            ]
            for (name, value) in reMetrics where value != 0 {
                context.insert(MarketTrend(
                    city: city, country: country,
                    profile: "realEstate", metricName: name,
                    value: value, source: source
                ))
            }
        }

        // ── Hospitality metrics ────────────────────────────────────────────────
        if deal.hospitalityRoomCount > 0 || deal.hospitalityADR > 0 {
            let hosp = HospitalityCalculator.calculateFull(inputs: .init(
                roomCount:        deal.hospitalityRoomCount,
                adr:              deal.hospitalityADR,
                occupancyRate:    deal.hospitalityOccupancyRate,
                fbRevenue:        deal.hospitalityFBRevenue,
                spaRevenue:       deal.hospitalitySpaRevenue,
                meetingRevenue:   deal.hospitalityMeetingRevenue,
                otherRevenue:     deal.hospitalityOtherRevenue,
                opExRatio:        deal.hospitalityOpExRatio,
                directBookingPct: deal.hospitalityDirectBookingPct,
                otaBookingPct:    deal.hospitalityOTABookingPct,
                distributionCost: deal.hospitalityDistributionCost
            ))

            let hospMetrics: [(String, Double)] = [
                ("adr",           hosp.adr),
                ("occupancyRate", hosp.occupancyRate),
                ("revPAR",        hosp.revPAR),
                ("gopMargin",     hosp.gopMargin),
            ]
            for (name, value) in hospMetrics where value != 0 {
                context.insert(MarketTrend(
                    city: city, country: country,
                    profile: "hospitality", metricName: name,
                    value: value, source: source
                ))
            }
        }

        // ── Design metrics ─────────────────────────────────────────────────────
        if deal.designGFA > 0 || deal.designDaylighting > 0 {
            let desMetrics: [(String, Double)] = [
                ("daylighting",    deal.designDaylighting),
                ("spaceUtil",      deal.designSpaceUtilization),
                ("thermalComfort", deal.designThermalComfort),
            ]
            for (name, value) in desMetrics where value != 0 {
                context.insert(MarketTrend(
                    city: city, country: country,
                    profile: "design", metricName: name,
                    value: value, source: source
                ))
            }
        }

        // ── Circular economy metrics ───────────────────────────────────────────
        if deal.circularKgMaterialsUsed > 0 || deal.circularRecycledContentPct > 0 {
            let circMetrics: [(String, Double)] = [
                ("recycledContent", deal.circularRecycledContentPct),
                ("waterRecycling",  deal.circularWaterRecyclingRate),
            ]
            for (name, value) in circMetrics where value != 0 {
                context.insert(MarketTrend(
                    city: city, country: country,
                    profile: "circular", metricName: name,
                    value: value, source: source
                ))
            }
        }

        try? context.save()
    }
}
