import Foundation

struct HospitalityCalculator {

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Legacy API (used by PropertyDealViewModel / PorteosScoreCalculator)
    // ─────────────────────────────────────────────────────────────────────────

    struct HospitalityInputs {
        var roomCount:      Int
        var adr:            Double
        var occupancyRate:  Double
        var fbRevenue:      Double
        var spaRevenue:     Double
        var meetingRevenue: Double
        var otherRevenue:   Double
        var opExRatio:      Double
    }

    struct HospitalityMetrics {
        var availableRoomNights: Int
        var annualRoomRevenue:   Double
        var totalRevenue:        Double
        var revPAR:              Double
        var trevPAR:             Double
        var gop:                 Double
        var gopPAR:              Double
    }

    static func calculate(inputs: HospitalityInputs) -> HospitalityMetrics {
        let nights  = Double(inputs.roomCount) * 365
        let roomRev = Double(inputs.roomCount) * inputs.adr * (inputs.occupancyRate / 100) * 365
        let totalRev = roomRev + inputs.fbRevenue + inputs.spaRevenue
                     + inputs.meetingRevenue + inputs.otherRevenue
        let revPAR   = inputs.adr * (inputs.occupancyRate / 100)
        let trevPAR  = nights > 0 ? totalRev / nights : 0
        let gop      = totalRev * (1 - inputs.opExRatio / 100)
        let gopPAR   = nights > 0 ? gop / nights : 0
        return HospitalityMetrics(
            availableRoomNights: inputs.roomCount * 365,
            annualRoomRevenue:   roomRev,
            totalRevenue:        totalRev,
            revPAR:              revPAR,
            trevPAR:             trevPAR,
            gop:                 gop,
            gopPAR:              gopPAR
        )
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Full API (used by HospitalityDashboardView – all 3 modules)
    // ─────────────────────────────────────────────────────────────────────────

    struct FullInputs {
        var roomCount:           Int
        var adr:                 Double
        var occupancyRate:       Double   // %
        var fbRevenue:           Double
        var spaRevenue:          Double
        var meetingRevenue:      Double
        var otherRevenue:        Double
        var opExRatio:           Double   // %
        var directBookingPct:    Double   // %
        var otaBookingPct:       Double   // %
        var distributionCost:    Double   // € annual
    }

    struct FullMetrics {
        // Module 01 – Operational Stats
        var adr:                 Double
        var occupancyRate:       Double
        var revPAR:              Double
        var trevPAR:             Double
        // Module 02 – Profitability
        var gop:                 Double
        var gopMargin:           Double   // %
        var gopPAR:              Double
        var ebitdaMargin:        Double   // % (estimated: gopMargin − 5pt mgmt fee)
        // Module 03 – Distribution
        var directBookingPct:    Double
        var otaBookingPct:       Double
        var distributionCost:    Double
        var costOfAcquisition:   Double   // % of annual room revenue
        // Supporting
        var totalRevenue:        Double
        var annualRoomRevenue:   Double
    }

    static func calculateFull(inputs: FullInputs) -> FullMetrics {
        let nights      = Double(inputs.roomCount) * 365
        let roomRev     = Double(inputs.roomCount) * inputs.adr * (inputs.occupancyRate / 100) * 365
        let totalRev    = roomRev + inputs.fbRevenue + inputs.spaRevenue
                        + inputs.meetingRevenue + inputs.otherRevenue
        let revPAR      = inputs.adr * (inputs.occupancyRate / 100)
        let trevPAR     = nights > 0 ? totalRev / nights : 0
        let gop         = totalRev * (1 - inputs.opExRatio / 100)
        let gopMargin   = totalRev > 0 ? (gop / totalRev) * 100 : 0
        let gopPAR      = nights > 0 ? gop / nights : 0
        // EBITDA margin: GOP margin less ~5pt for management fees/rent (industry estimate)
        let ebitdaMargin = max(0, gopMargin - 5)
        let cofa        = roomRev > 0 ? (inputs.distributionCost / roomRev) * 100 : 0

        return FullMetrics(
            adr:               inputs.adr,
            occupancyRate:     inputs.occupancyRate,
            revPAR:            revPAR,
            trevPAR:           trevPAR,
            gop:               gop,
            gopMargin:         gopMargin,
            gopPAR:            gopPAR,
            ebitdaMargin:      ebitdaMargin,
            directBookingPct:  inputs.directBookingPct,
            otaBookingPct:     inputs.otaBookingPct,
            distributionCost:  inputs.distributionCost,
            costOfAcquisition: cofa,
            totalRevenue:      totalRev,
            annualRoomRevenue: roomRev
        )
    }
}
