import Foundation

// MARK: - ValidationSeverity

enum ValidationSeverity {
    case warning, critical
}

// MARK: - ValidationMessage

struct ValidationMessage: Identifiable {
    let id       = UUID()
    let severity: ValidationSeverity
    let field:    String
    let message:  String

    var prefix: String {
        switch severity {
        case .critical: return "[ERR] "
        case .warning:  return "[WARN]"
        }
    }
}

// MARK: - DataValidator

struct DataValidator {

    /// Returns all triggered validation messages for the given deal.
    /// Returns an empty array when the deal is fully valid.
    /// This is advisory only — it does NOT prevent saving.
    static func validate(deal: PropertyDeal) -> [ValidationMessage] {
        var msgs: [ValidationMessage] = []

        // ── Real Estate ───────────────────────────────────────────────────────

        if !(0...100).contains(deal.vacancyRate) {
            msgs.append(.init(
                severity: .critical,
                field:    "Vacancy Rate",
                message:  "Vacancy rate \(fmt(deal.vacancyRate))% is outside 0–100%."
            ))
        }

        if deal.purchasePrice > 0 {
            let ltv = deal.purchasePrice > 0
                ? (deal.loanAmount / deal.purchasePrice) * 100
                : 0
            if ltv > 100 {
                msgs.append(.init(
                    severity: .critical,
                    field:    "LTV",
                    message:  "Loan (\(eur(deal.loanAmount))) exceeds Purchase Price (\(eur(deal.purchasePrice))). LTV \(fmt(ltv, dp: 1))%."
                ))
            }
        }

        if deal.grossPotentialIncome > 0 && deal.purchasePrice > 0 {
            let egi    = deal.grossPotentialIncome * (1 - deal.vacancyRate / 100)
            let opex   = max(
                deal.opexPropertyManagement + deal.opexPropertyTax + deal.opexInsurance
                + deal.opexUtilities + deal.opexMaintenance + deal.opexCapitalReserves,
                deal.operatingExpenses
            )
            let noi = egi - opex
            if noi <= 0 {
                msgs.append(.init(
                    severity: .warning,
                    field:    "Cap Rate / NOI",
                    message:  "Operating expenses ≥ effective income. NOI is non-positive (\(eur(noi)))."
                ))
            }
        }

        // ── Hospitality ───────────────────────────────────────────────────────

        if deal.hospitalityOccupancyRate > 0 && !(0...100).contains(deal.hospitalityOccupancyRate) {
            msgs.append(.init(
                severity: .critical,
                field:    "Occupancy Rate",
                message:  "Occupancy rate \(fmt(deal.hospitalityOccupancyRate))% must be between 0 and 100."
            ))
        }

        let channelTotal = deal.hospitalityDirectBookingPct + deal.hospitalityOTABookingPct
        if channelTotal > 100 {
            msgs.append(.init(
                severity: .critical,
                field:    "Booking Channels",
                message:  "Direct booking (\(fmt(deal.hospitalityDirectBookingPct))%) + OTA (\(fmt(deal.hospitalityOTABookingPct))%) = \(fmt(channelTotal))% — exceeds 100%."
            ))
        }

        // ── Design ────────────────────────────────────────────────────────────

        if deal.designNIA > 0 && deal.designGFA > 0 && deal.designNIA > deal.designGFA {
            msgs.append(.init(
                severity: .critical,
                field:    "NIA / GFA",
                message:  "Net Internal Area (\(fmtM2(deal.designNIA))) cannot exceed Gross Floor Area (\(fmtM2(deal.designGFA)))."
            ))
        }

        let designPcts: [(String, Double)] = [
            ("Circulation %",       deal.designCirculationPct),
            ("Space Utilization %", deal.designSpaceUtilization),
            ("Daylighting %",       deal.designDaylighting),
            ("Thermal Comfort %",   deal.designThermalComfort),
            ("Acoustic Comfort %",  deal.designAcousticComfort),
            ("Views to Nature %",   deal.designViewsToNaturePct),
            ("Natural Materials %", deal.designNaturalMaterialsPct),
            ("Movable Partition %", deal.designMovablePartitionPct),
        ]
        for (name, value) in designPcts where value > 0 {
            if !(0...100).contains(value) {
                msgs.append(.init(
                    severity: .warning,
                    field:    name,
                    message:  "\(name) (\(fmt(value))%) must be between 0 and 100."
                ))
            }
        }

        // ── Circular Economy ──────────────────────────────────────────────────

        let contentTotal = deal.circularRecycledContentPct + deal.circularRenewableContentPct
        if contentTotal > 100 {
            msgs.append(.init(
                severity: .critical,
                field:    "Circular Content",
                message:  "Recycled (\(fmt(deal.circularRecycledContentPct))%) + Renewable (\(fmt(deal.circularRenewableContentPct))%) content = \(fmt(contentTotal))% — exceeds 100%."
            ))
        }

        if deal.circularKgMaterialsUsed > 0 {
            let accounted = deal.circularKgMaterialsReturned + deal.circularKgMaterialsDisposed
            if accounted > deal.circularKgMaterialsUsed {
                msgs.append(.init(
                    severity: .critical,
                    field:    "Material Flow",
                    message:  "Returned (\(fmtKg(deal.circularKgMaterialsReturned))) + Disposed (\(fmtKg(deal.circularKgMaterialsDisposed))) exceeds Total Used (\(fmtKg(deal.circularKgMaterialsUsed)))."
                ))
            }
        }

        if deal.circularWaterRecyclingRate > 0 && !(0...100).contains(deal.circularWaterRecyclingRate) {
            msgs.append(.init(
                severity: .warning,
                field:    "Water Recycling Rate",
                message:  "Water recycling rate (\(fmt(deal.circularWaterRecyclingRate))%) must be between 0 and 100."
            ))
        }

        return msgs
    }

    // MARK: Private Formatters

    private static func fmt(_ v: Double, dp: Int = 1) -> String {
        v.formatted(.number.precision(.fractionLength(dp)))
    }

    private static func eur(_ v: Double) -> String {
        v.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }

    private static func fmtM2(_ v: Double) -> String {
        "\(v.formatted(.number.precision(.fractionLength(0)))) m²"
    }

    private static func fmtKg(_ v: Double) -> String {
        "\(v.formatted(.number.precision(.fractionLength(0)))) kg"
    }
}
