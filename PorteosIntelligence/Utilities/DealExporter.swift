import Foundation
import UniformTypeIdentifiers

// MARK: - Export Enums

enum ExportFormat: String, CaseIterable {
    case csv  = "CSV"
    case json = "JSON"

    var fileExtension: String { rawValue.lowercased() }

    var utType: UTType { self == .csv ? .commaSeparatedText : .json }
}

enum ExportDepth: String, CaseIterable {
    case base        = "BASE FIELDS"
    case financials  = "+FINANCIALS"
    case allMetrics  = "ALL METRICS"
}

// MARK: - DealExporter

struct DealExporter {

    // MARK: - Public API

    static func exportToCSV(deals: [PropertyDeal], depth: ExportDepth) -> Data {
        var rows = [csvHeader(depth: depth)]
        for deal in deals { rows.append(csvRow(deal: deal, depth: depth)) }
        return rows.joined(separator: "\r\n").data(using: .utf8) ?? Data()
    }

    static func exportToJSON(deals: [PropertyDeal], depth: ExportDepth) -> Data {
        let records = deals.map { dealDict($0, depth: depth) }
        return (try? JSONSerialization.data(withJSONObject: records, options: [.prettyPrinted, .sortedKeys])) ?? Data()
    }

    /// Returns a human-readable preview string (≤ `maxRows` data rows).
    static func previewLines(
        deals: [PropertyDeal],
        depth: ExportDepth,
        format: ExportFormat,
        maxRows: Int = 3
    ) -> String {
        let sample = Array(deals.prefix(maxRows))
        switch format {
        case .csv:
            var lines = [csvHeader(depth: depth)]
            lines += sample.map { csvRow(deal: $0, depth: depth) }
            if deals.count > maxRows {
                lines.append("... \(deals.count - maxRows) more row\(deals.count - maxRows == 1 ? "" : "s")")
            }
            return lines.joined(separator: "\n")
        case .json:
            let records = sample.map { dealDict($0, depth: depth) }
            guard let data = try? JSONSerialization.data(withJSONObject: records, options: [.prettyPrinted]),
                  let text = String(data: data, encoding: .utf8) else { return "[]" }
            return text
        }
    }

    // MARK: - CSV Internals

    private static func csvHeader(depth: ExportDepth) -> String {
        var cols = baseHeaders
        if depth != .base   { cols += financialHeaders }
        if depth == .allMetrics { cols += metricsHeaders }
        return cols.map { csvEscape($0) }.joined(separator: ",")
    }

    private static var baseHeaders: [String] {
        ["Property Name", "Location City", "Address", "Type", "Status",
         "Purchase Price", "Total Area (m2)", "Notes", "Created At"]
    }

    private static var financialHeaders: [String] {
        ["GPI", "Vacancy Rate (%)", "Effective OpEx",
         "Loan Amount", "Interest Rate (%)", "Amortization (months)",
         "NOI", "Cap Rate (%)", "CFBT", "DSCR", "LTV (%)", "CoC Return (%)"]
    }

    private static var metricsHeaders: [String] {
        ["Porteos Score",
         // Hospitality
         "Hosp Room Count", "Hosp ADR", "Hosp Occupancy (%)",
         "Hosp F&B Revenue", "Hosp Spa Revenue", "Hosp OpEx Ratio (%)",
         "RevPAR", "GOP",
         // Design
         "Design GFA (m2)", "Design NIA (m2)", "Design Net-to-Gross (%)",
         "Design Space Utilization (%)", "Design Daylighting (%)", "Design CO2 (ppm)",
         // Circular
         "Circ Recycled Content (%)", "Circ Renewable Content (%)",
         "Circ Waste Generated (kg)", "Circ Recovery Rate (%)",
         "Circ Embodied Carbon (tCO2e)", "Circ MCI Score", "Circ CE Score"]
    }

    private static func csvRow(deal: PropertyDeal, depth: ExportDepth) -> String {
        var fields = baseFields(deal)
        if depth != .base        { fields += financialFields(deal) }
        if depth == .allMetrics  { fields += allMetricFields(deal) }
        return fields.map { csvEscape($0) }.joined(separator: ",")
    }

    private static func baseFields(_ d: PropertyDeal) -> [String] {
        let iso = ISO8601DateFormatter()
        return [
            d.propertyName,
            d.locationCity,
            d.address,
            d.propertyType,
            d.status.rawValue,
            fmt(d.purchasePrice),
            fmt(d.totalArea),
            d.notes,
            iso.string(from: d.createdAt)
        ]
    }

    private static func financialFields(_ d: PropertyDeal) -> [String] {
        let m = reMetrics(d)
        return [
            fmt(d.grossPotentialIncome),
            fmt2(d.vacancyRate),
            fmt(d.effectiveOpEx),
            fmt(d.loanAmount),
            fmt2(d.interestRate),
            "\(d.amortizationMonths)",
            fmt(m.netOperatingIncome),
            fmt2(m.capRate),
            fmt(m.cashFlowBeforeTax),
            fmt2(m.debtServiceCoverageRatio),
            fmt1(m.loanToValue),
            fmt2(m.cashOnCashReturn)
        ]
    }

    private static func allMetricFields(_ d: PropertyDeal) -> [String] {
        let hm = hospMetrics(d)
        let ce = circMetrics(d)

        // Hospitality
        let revPAR = hm.revPAR
        let gop    = hm.gop

        // Design net-to-gross
        let ntg: Double = d.designGFA > 0 ? (d.designNIA / d.designGFA * 100) : 0

        return [
            d.porteosScore.map { fmt1($0) } ?? "",
            // Hospitality
            "\(d.hospitalityRoomCount)", fmt(d.hospitalityADR), fmt1(d.hospitalityOccupancyRate),
            fmt(d.hospitalityFBRevenue), fmt(d.hospitalitySpaRevenue), fmt1(d.hospitalityOpExRatio),
            fmt2(revPAR), fmt(gop),
            // Design
            fmt(d.designGFA), fmt(d.designNIA), fmt1(ntg),
            fmt1(d.designSpaceUtilization), fmt1(d.designDaylighting), fmt(d.designCO2ppm),
            // Circular
            fmt1(d.circularRecycledContentPct), fmt1(d.circularRenewableContentPct),
            fmt(d.circularWasteGenerated), fmt1(ce.recoveryRate),
            fmt2(ce.embodiedCarbon), fmt2(ce.mciScore), fmt1(ce.overallCEScore)
        ]
    }

    // MARK: - JSON Internals

    private static func dealDict(_ d: PropertyDeal, depth: ExportDepth) -> [String: Any] {
        let iso = ISO8601DateFormatter()
        var dict: [String: Any] = [
            "id":           d.id.uuidString,
            "propertyName": d.propertyName,
            "locationCity": d.locationCity,
            "address":      d.address,
            "propertyType": d.propertyType,
            "status":       d.status.rawValue,
            "purchasePrice": d.purchasePrice,
            "totalArea":    d.totalArea,
            "notes":        d.notes,
            "createdAt":    iso.string(from: d.createdAt)
        ]

        if depth != .base {
            let m = reMetrics(d)
            dict["grossPotentialIncome"] = d.grossPotentialIncome
            dict["vacancyRate"]          = d.vacancyRate
            dict["effectiveOpEx"]        = d.effectiveOpEx
            dict["loanAmount"]           = d.loanAmount
            dict["interestRate"]         = d.interestRate
            dict["amortizationMonths"]   = d.amortizationMonths
            dict["noi"]                  = round2(m.netOperatingIncome)
            dict["capRate"]              = round2(m.capRate)
            dict["cfbt"]                 = round2(m.cashFlowBeforeTax)
            dict["dscr"]                 = round2(m.debtServiceCoverageRatio)
            dict["ltv"]                  = round2(m.loanToValue)
            dict["cashOnCashReturn"]     = round2(m.cashOnCashReturn)
        }

        if depth == .allMetrics {
            let hm = hospMetrics(d)
            let ce = circMetrics(d)
            dict["porteosScore"] = d.porteosScore ?? NSNull()

            dict["hospitality"] = [
                "roomCount":       d.hospitalityRoomCount,
                "adr":             d.hospitalityADR,
                "occupancyRate":   d.hospitalityOccupancyRate,
                "fbRevenue":       d.hospitalityFBRevenue,
                "spaRevenue":      d.hospitalitySpaRevenue,
                "opExRatio":       d.hospitalityOpExRatio,
                "revPAR":          round2(hm.revPAR),
                "gop":             round2(hm.gop),
                "gopMargin":       round2(hm.gopMargin)
            ] as [String: Any]

            dict["design"] = [
                "gfa":              d.designGFA,
                "nia":              d.designNIA,
                "spaceUtilization": d.designSpaceUtilization,
                "daylighting":      d.designDaylighting,
                "co2ppm":           d.designCO2ppm,
                "thermalComfort":   d.designThermalComfort,
                "acousticComfort":  d.designAcousticComfort
            ] as [String: Any]

            dict["circular"] = [
                "recycledContentPct":  d.circularRecycledContentPct,
                "renewableContentPct": d.circularRenewableContentPct,
                "kgMaterialsUsed":     d.circularKgMaterialsUsed,
                "wasteGenerated":      d.circularWasteGenerated,
                "recoveryRate":        round2(ce.recoveryRate),
                "embodiedCarbon":      round2(ce.embodiedCarbon),
                "mciScore":            round2(ce.mciScore),
                "overallCEScore":      round2(ce.overallCEScore)
            ] as [String: Any]
        }

        return dict
    }

    // MARK: - Calculator Bridges

    private static func reMetrics(_ d: PropertyDeal) -> RealEstateCalculator.FullMetrics {
        RealEstateCalculator.calculateFull(inputs: RealEstateCalculator.FullInputs(
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
        ))
    }

    private static func hospMetrics(_ d: PropertyDeal) -> HospitalityCalculator.FullMetrics {
        HospitalityCalculator.calculateFull(inputs: HospitalityCalculator.FullInputs(
            roomCount:        d.hospitalityRoomCount,
            adr:              d.hospitalityADR,
            occupancyRate:    d.hospitalityOccupancyRate,
            fbRevenue:        d.hospitalityFBRevenue,
            spaRevenue:       d.hospitalitySpaRevenue,
            meetingRevenue:   d.hospitalityMeetingRevenue,
            otherRevenue:     d.hospitalityOtherRevenue,
            opExRatio:        d.hospitalityOpExRatio,
            directBookingPct: d.hospitalityDirectBookingPct,
            otaBookingPct:    d.hospitalityOTABookingPct,
            distributionCost: d.hospitalityDistributionCost
        ))
    }

    private static func circMetrics(_ d: PropertyDeal) -> CircularEconomyCalculator.FullMetrics {
        CircularEconomyCalculator.calculateFull(inputs: CircularEconomyCalculator.FullInputs(
            totalConstructionCost:  d.circularTotalConstructionCost,
            repurposedMaterialCost: d.circularRepurposedMaterialCost,
            co2Embodied:            d.circularCO2Embodied,
            kgMaterialsUsed:        d.circularKgMaterialsUsed,
            kgMaterialsReturned:    d.circularKgMaterialsReturned,
            kgMaterialsDisposed:    d.circularKgMaterialsDisposed,
            recycledContentPct:     d.circularRecycledContentPct,
            renewableContentPct:    d.circularRenewableContentPct,
            wasteGenerated:         d.circularWasteGenerated,
            operationalCarbon:      d.circularOperationalCarbon,
            buildingAreaM2:         d.circularBuildingAreaM2,
            waterRecyclingRate:     d.circularWaterRecyclingRate
        ))
    }

    // MARK: - Formatting Helpers

    private static func fmt (_ v: Double) -> String { String(format: "%.0f", v) }
    private static func fmt1(_ v: Double) -> String { String(format: "%.1f", v) }
    private static func fmt2(_ v: Double) -> String { String(format: "%.2f", v) }
    private static func round2(_ v: Double) -> Double { (v * 100).rounded() / 100 }

    private static func csvEscape(_ s: String) -> String {
        guard s.contains(",") || s.contains("\"") || s.contains("\n") || s.contains("\r") else {
            return s
        }
        return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
